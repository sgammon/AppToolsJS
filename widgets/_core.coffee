## AppTools Widget Core
class CoreWidgetAPI extends CoreAPI

    @mount: 'widget'

    constructor: () ->

        @handle = (e) =>

            if e.preventDefault
                e.preventDefault()
                e.stopPropagation()

                trigger = e.target
                target_ids = _.filter(trigger.getAttribute('data-href').split('#'), (it) -> return it isnt '' and it isnt String())
                touched_targets = []

                if target_ids?
                    for target_id in target_ids
                        target = document.getElementById(target_id)
                        is_curr = target.classList.contains('active') or trigger.classList.contains('active')

                        touched_targets.push(target)

                        _w = _.resolve_common_ancestor(trigger, target)
                        if _w? and _.has_class(_w, 'widget')
                            widget = _w
                            other_targ.classList.remove('active') for other_targ in other_targs if (other_targs = _.filter(_.get(target.tagName), (o) => return _.is_child(widget, o) and (o isnt target) and not _.in_array(touched_targets, o)))?
                            other_trig.classList.remove('active') for other_trig in other_trigs if (other_trigs = _.filter(_.get(trigger.tagName), (o) => return _.is_child(widget, o) and (o isnt trigger)))?

                        if is_curr
                            return @deferred
                                target: target
                                trigger: trigger
                                preventDefault: ->
                                stopPropagation: ->
                                callback: (targ, trig) ->
                                    targ.classList.remove('active')
                                    trig.classList.remove('active')
                                    if trig.classList.contains('autoclose')
                                        targ.removeEventListener('mouseout', @handle, false)

                        else
                            target.classList.add('active')
                            trigger.classList.add('active')

                            target.addEventListener('webkitTransitionEnd', @deferred, false)
                            if trigger.classList.contains('autoclose')
                                target.addEventListener('mouseout', @handle, false)

                        return

                else touched_targets = false
                return touched_targets

            else if e?
                throw 'Unparseable event object passed to default handle()'
            else throw 'Default handle() can only be called via event binding'

        @deferred = (e) =>

            if e.preventDefault
                e.preventDefault()
                e.stopPropagation()

                e.target?.removeEventListener('webkitTransitionEnd', @deferred)

                if (evc = e.callback)?
                    tar = e.target
                    tri = e.trigger
                    deact = _.debounce((d) =>
                        return evc.call(@, tar, tri)
                    , 50)
                    cback = (ev) =>
                        if ev.preventDefault
                            ev.preventDefault()
                            ev.stopPropagation()
                            d = ev.target
                            d.removeEventListener('webkitTransitionEnd', cback)

                        return deact()

                custom = !!cback

                defers = e.target.find('.deferred')

                if not defers? or (defers.length and defers.length is 0)
                    return (if custom then cback() else e)

                for defer in defers
                    if custom
                        defer.addEventListener('webkitTransitionEnd', cback, false)
                        defer.classList.remove('active')
                    else
                        defer.classList.add('active')

                return

            else if e?
                throw 'Unparseable event object passed to default deferred()'
            else throw 'Default deferred() can only be called via event binding'

        @_init = () =>

            link.addEventListener('click', @handle , false) for link in target_links if (target_links = _.get('.target-link'))?

class CoreWidget extends Model

    constructor: (@element_id) ->
        @id = @constructor.name.toLowerCase() + '-' + @element_id
        super()
        return

@__apptools_preinit?.abstract_base_classes.push CoreWidget
@__apptools_preinit?.abstract_base_classes.push CoreWidgetAPI
@__apptools_preinit?.deferred_core_modules.push {module: CoreWidgetAPI}
