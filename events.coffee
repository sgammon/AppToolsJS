# Events API
class CoreEventsAPI extends CoreAPI

    @mount = 'events'
    @events = []

    constructor: (apptools, window) ->

        ## Expose eventlists
        @registry = [] # Global registry of all named events
        @callchain = {} # Event callbacks attached to named events
        @history = [] # Runtime event history
        @mutators = [] # Mutate functions registered by `bridge`

        ## Trigger a named event, optionally with context
        @fire = @trigger = (event, args...) =>

            apptools.dev.eventlog 'Trigger', 'Triggered event.', event, args, @callchain[event]

            # Have we seen this event before?
            if event in @registry

                # Keep track of hooks executed/erred
                hook_exec_count = 0
                hook_error_count = 0
                event_bridges = []
                touched_events = []

                touched_events.push(event)

                # Consider all callchain directives
                for hook in @callchain[event].hooks
                    try
                        # If it's a run-once and it's already run, continue as fast as possible...
                        if hook.once == true and hook.has_run == true
                            continue

                        # If it's not an event bridge, execute the hook
                        else if hook.bridge == false

                            # Execute callback with context, add to history/exec count
                            result = hook.fn(args...)
                            hook_exec_count++
                            @history.push event: event, callback: hook, args: args, result: result

                            # Mark as run
                            hook.has_run = true

                        # If we encounter a bridge, defer it (after all hooks are executed for this event)...
                        else if hook.bridge == true
                            event_bridges.push(event: hook.event, args: args, mutator: hook.mutator)

                    catch error
                        ## Increment error count and add to runtime history
                        hook_error_count++
                        nl = @history.push event: event, callback: hook, args: args, error: error

                        $.apptools.dev.eventlog 'exception', 'Encountered unhandled exception when dispatching event hook for "' + event + '".', @history[nl - 1]
                        if $.apptools.dev.debug.eventlog and $.apptools.dev.debug.verbose
                            $.apptools.dev.error 'Events', 'Unhandled event hook exception.', error
                        if $.apptools.dev.debug.strict
                            throw error

                # Execute deferred event bridges
                for bridge in event_bridges
                    touched_events.push(bridge.event)
                    if bridge.mutator != false
                        @trigger(bridge.event, (@mutators[bridge.mutator](bridge.args, event, bridge.event))...)
                    else
                        @trigger(bridge.event, bridge.args...)

                return events: touched_events, executed: hook_exec_count, errors: hook_error_count
            else
                # Silent failure if we don't recognize the event...
                return false

        ## Register a named, global event so it can be triggered later.
        @create = @register = (names) =>

            if not _.is_array(names)
                if _.is_string(names) and names == ''
                    return
                names = [names]
            else
                if names.length == 0
                    return

            apptools.dev.eventlog 'Register', 'Registered events.', {count: names.length, events: names}
            for name in names
                # Add to event registry, create a slot in the callchain...
                @registry.push(name)
                @callchain[name] =
                    hooks: []

            return true

        ## Register a callback to be executed when an event is triggered
        @on = @upon = @when = @hook = (event, callback, once=false) =>

            if event not in @registry
                apptools.dev.warning 'warn', 'Tried to hook to unrecognized event. Registering...'
                @register(event)
            @callchain[event].hooks.push(fn: callback, once: once, has_run: false, bridge: false)
            apptools.dev.eventlog 'Hook', 'Hook registered on event.', event
            return true

        ## Delegate one event to another, to be triggered after all hooks on the original event
        @delegate = @bridge = (from_events, to_events, context_mutator_fn=null) =>

            if typeof(to_events) == 'string'
                to_events = [to_events]
            if typeof(from_events) == 'string'
                from_events = [from_events]

            apptools.dev.eventlog 'Bridge', 'Bridging events.', {from: from_events}, '->', {to: to_events}
            for source_ev in from_events
                for target_ev in to_events
                    if not @callchain[source_ev]?
                        apptools.dev.warn('Events', 'Bridging from undefined source event:', source_ev)
                        @register(source_ev)
                    if context_mutator_fn?
                        nl = @mutators.push context_mutator_fn
                        @callchain[source_ev].hooks.push(
                            event: target_ev,
                            bridge: true,
                            mutator: nl - 1
                        )
                    else
                        @callchain[source_ev].hooks.push(
                            event: target_ev,
                            bridge: true,
                            mutator: false
                        )

@__apptools_preinit.abstract_base_classes.push CoreEventsAPI
