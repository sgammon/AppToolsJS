
# analytics controller
class GoogleAnalytics extends Integration

    @mount = 'analytics'
    @export = 'private'

    @events = [

        ## Internal Events
        'ANALYTICS_INIT',
        'ANALYTICS_PUSH',
        'ANALYTICS_EVENT',
        'ANALYTICS_READY',

        ## Vars + Config
        'ANALYTICS_CONFIG',
        'ANALYTICS_SETVAR',

        ## Tracking Events
        'ANALYTICS_TRACK_EVENT',
        'ANALYTICS_TRACK_SOCIAL',
        'ANALYTICS_TRACK_TIMING',
        'ANALYTICS_TRACK_PAGEVIEW',
        'ANALYTICS_TRACK_CAMPAIGN',
        'ANALYTICS_TRACK_TRANSACTION',

        ## E-Commerce Events
        'ANALYTICS_TRANSACTION_NEWITEM',
        'ANALYTICS_TRANSACTION_COMPLETE'

    ]

    constructor: (apptools, window) ->

        ## build analytics state
        @state =

            # tracker/runtime config
            vars: {}
            agent: {}
            trackers: {}
            initialized: false

            # tracked analytics operations
            data:
                events: []
                social: []
                timing: []
                campaigns: []
                transactions: []

            index:
                timing: {}
                networks: {}
                campaigns: {}
                transactions: {}

            # analytics API mappings
            _ga:
                queue: null
                tracker: null
                scopes: ['visitor', 'session', 'page']
                bindings:
                   ANALYTICS_SETVAR: '_setCustomVar'
                   ANALYTICS_TRACK_EVENT: '_trackEvent'
                   ANALYTICS_TRACK_SOCIAL: '_trackSocial'
                   ANALYTICS_TRACK_TIMING: '_trackTiming'
                   ANALYTICS_TRACK_PAGEVIEW: '_trackPageview'
                   ANALYTICS_TRACK_CAMPAIGN: '_setCampaignTrack'
                   ANALYTICS_TRACK_TRANSACTION: '_addTrans'
                   ANALYTICS_TRANSACTION_NEWITEM: '_addItem'
                   ANALYTICS_TRANSACTION_COMPLETE: '_trackTrans'


            # build analytics config
            config:
                account_ids: {}

                linker: true
                anonymize: false
                samplerate: 1
                multitrack: false

        ## object init
        @_init = (apptools) =>


        ## internal methods
        @internal =

            initialize: (queue, tracker, config=null, event=null) =>

                if not @state.initialized
                    $.apptools.dev.verbose('Analytics', 'Initializing Google Analytics integration.')

                    if (not config?) and (window._gac?)
                        config = window._gac

                    # splice in overrides from config
                    @state.config = _.extend(true, {}, @state.config, config)
                    $.apptools.dev.verbose('Analytics', 'Merged analytics config.', config)

                    # bind apptools events
                    @internal.bind_events()

                    # copy over analytics apis and state
                    installed_trackers = [k for k in @state.config.account_ids]
                    @state.initialized = installed_trackers.length
                    @state._ga.queue = queue
                    @state._ga.tracker = tracker

                    # init extra trackers, if multitrack is enabled
                    for key, value of @state.config.account_ids
                        @internal.provision_tracker(key, value)
                        if @state.config.multitrack
                            continue
                        else
                            break

                return @

            bind_events: (event) =>

                ## bind tracker initialization logic
                _.bind 'ANALYTICS_INIT', (tracker) =>
                    $.apptools.dev.verbose('Analytics', 'Tracker initialized.', tracker)
                    boot_cmd_list = []
                    if @state.config.linker
                        boot_cmd_list.push ['_setAllowLinker', true]
                    boot_cmd_list.push ['_setAccount', @state.config.account_ids[tracker.name]]
                    if event? and event.srcElement.hasAttribute('data-hostname')
                        boot_cmd_list.push ['_setDomainName', event.srcElement.getAttribute('data-hostname')]
                    @internal.push_command boot_cmd_list, tracker.name
                    @state.initialized--

                    if @state.initialized == 0
                        @state.initialized = true

                        ## nothing left to init, trigger ready
                        _.trigger 'ANALYTICS_READY', @state.trackers

                    return

                ## bind tracker command logic
                _.bind 'ANALYTICS_PUSH', (method, args...) =>
                    $.apptools.dev.verbose('Analytics', 'Pushing tracker command.', method, args)

                    # add the method on first, then dispatch to the trackers
                    args.unshift(method)
                    @internal.push_command args
                    return

                ## bind tracker ready logic
                _.bind 'ANALYTICS_READY', (trackers) =>
                    $.apptools.dev.verbose('Analytics', 'Analytics is READY to receive events.', 'config:', @state.config, 'trackers:', trackers)
                    _.trigger 'ANALYTICS_PUSH', ['_trackPageview']


                ## bridge low-level tracking events to the command queue
                _.bridge [ 'ANALYTICS_SETVAR'
                           'ANALYTICS_TRACK_EVENT',
                           'ANALYTICS_TRACK_SOCIAL',
                           'ANALYTICS_TRACK_TIMING',
                           'ANALYTICS_TRACK_PAGEVIEW',
                           'ANALYTICS_TRACK_CAMPAIGN',
                           'ANALYTICS_TRACK_TRANSACTION',
                           'ANALYTICS_TRANSACTION_NEWITEM',
                           'ANALYTICS_TRANSACTION_COMPLETE' ],
                           [
                                'ANALYTICS_PUSH'

                           ], (args, source) =>

                                # resolve GA method from event name
                                command_spec = [@state._ga.bindings[source]]

                                # if it's an array with more than one item, it's position args
                                if _.is_array(args) and args.length > 1

                                    for value in args

                                        # discard null values
                                        if value?
                                            command_spec.push value
                                        else
                                            continue

                                # if it's an array with a length of one, or an object (kwargs)
                                else

                                    # if it's an object (in position 0 of the 1-item array or as an object itself)
                                    if (_.is_object(args) and not _.is_array(args)) or (args.length == 1 and _.is_object(args[0]))

                                        # pull it out of the array if it's not an object literal
                                        if not _.is_object(args)
                                            args = args[0]

                                        for key, value of args

                                            # discard null values, all values are strings
                                            if value?
                                                command_spec.push value

                                    # if it's a literal string or something
                                    else
                                        command_spec.push args[0]

                                # return hash that is expanded to be ANALYTICS_PUSH context
                                return command_spec


                ## bridge mid-level controller events to the main event trunk
                _.bridge [ 'ANALYTICS_INIT',
                           'ANALYTICS_PUSH',
                           'ANALYTICS_READY' ],
                           [
                                'ANALYTICS_EVENT'

                           ], (args, source) =>

                                event_spec = source.split('_')[1]
                                args.unshift(event_spec)
                                $.apptools.dev.verbose 'Analytics', 'Emitted "' + event_spec + '".', args
                                return args

                return @mappings

            provision_tracker: (name, account) =>

                @state.trackers[name] = @state._ga.tracker._createTracker(account, name)
                $.apptools.events.trigger('ANALYTICS_INIT', name: name, tracker: @state.trackers[name])
                return @state.trackers[name]

            push_command: (command, tracker=null) =>

                $.apptools.dev.verbose('Analytics', 'Pushing command.', command, tracker)

                # resolve trackers to push command to
                if tracker == null
                    targets = _.extend({}, @state.trackers)
                else
                    if _.is_array(tracker)
                        for t in tracker
                            targets[t] = @state.trackers[t]
                    else
                        targets = {}
                        targets[tracker] = @state.trackers[tracker]

                $.apptools.dev.verbose('Analytics', 'Resolved target trackers.', targets)

                # push each command
                touched_trackers = 0
                for name, tracker of targets

                    command_spec = []
                    if _.is_array(command)

                        # if it's one level of commands...
                        if _.is_string(command[0])
                            command[0] = [name, command[0]].join('.')
                            command_spec.push command
                        else
                            for cmd_statement in command
                                if not _.is_string(cmd_statement[0])
                                    continue  # don't do anything if it's more than one level deep
                                else
                                    cmd_statement[0] = [name, cmd_statement[0]].join('.')
                                command_spec.push cmd_statement

                    @state._ga.queue.push command_spec...
                    $.apptools.dev.verbose('Analytics', 'Pushed command to tracker "' + name + '".', command_spec)
                    touched_trackers++

                $.apptools.dev.log('Analytics', 'Pushed command to ' + touched_trackers.toString() + ' trackers.', command, targets)

                return touched_trackers

        @config =

            flash: (enable=null) =>

                if enable?
                    return @state._ga.tracker._setDetectFlash(enable)
                return @state._ga.tracker._getDetectFlash()

            title: (enable=null) =>

                if enable?
                    return @state._ga.tracker._setDetectTitle(enable)
                return @state._ga.tracker._getDetectTitle()

            client: (enable=null) =>

                if enable?
                    return @state._ga.tracker._setClientInfo(enable)
                return @state._ga.tracker._getClientInfo()

            anonymize: (enable=null) =>

                if enable?
                    @state.config.anonymize = enable
                return @state.config.anonymize

            samplerate: (value=null) =>

                if value?
                    @state.config.samplerate = value
                return @state.config.samplerate

        @vars =

            set: (slot, name, value, scope='page') =>

                if _.is_string(scope)
                    scope = _.indexOf(@state.config._ga.scopes, scope)
                _.trigger 'ANALYTICS_SETVAR', [slot, name, value, scope]...
                return @

        @track =

            event: (category, action, label=null, value=null, non_interaction=false) =>

                _command_spec = [category, action]
                if label?
                    _command_spec.push label
                if value?
                    _command_spec.push value
                if non_interaction != false
                    _command_spec.push non_interaction
                _.trigger 'ANALYTICS_TRACK_EVENT', _command_spec...
                return @

            social: (network, action, target=null, path=null) =>

                _command_spec = [network, action]
                if target?
                    _command_spec.push target
                if path?
                    _command_spec.push path
                _.trigger 'ANALYTICS_TRACK_SOCIAL', _command_spec...
                return @

            timing: (category, variable, time, label=null, samplerate=null) =>

                _command_spec = [category, variable, time]
                if label?
                    _command_spec.push label
                if samplerate?
                    _command_spec.push samplerate
                _.trigger 'ANALYTICS_TRACK_TIMING', _command_spec...
                return @

            pageview: (page_url=null) =>

                _command_spec = []
                if page_url?
                    _command_spec.push page_url
                _.trigger 'ANALYTICS_TRACK_PAGEVIEW', _command_spec...
                return @

            campaign: (content_key, medium, name, source, term, nokey=null) =>
            transaction: (order_id, affiliation, total, tax, shipping, city, state, country) =>

        @transactions =

            item: (order_id, sku, name, category, price, quantity) =>
                return

            complete: (order_id=null) =>
                return

window.GoogleAnalytics = GoogleAnalytics

@__apptools_preinit.abstract_base_classes.push GoogleAnalytics
@__apptools_preinit.installed_integrations.push GoogleAnalytics
@__apptools_preinit.deferred_core_modules.push module: GoogleAnalytics