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
                            target.classList.remove('active')
                            trigger.classList.remove('active')
                            if trigger.classList.contains('autoclose')
                                target.removeEventListener('mouseout', @handle, false)

                        else
                            target.classList.add('active')
                            trigger.classList.add('active')
                            if trigger.classList.contains('autoclose')
                                target.addEventListener('mouseout', @handle, false)

                        return

                else touched_targets = false
                return touched_targets

            else if e?
                throw 'Unparseable event object passed to default handle()'
            else
                throw 'Default handle() can only be called via event binding'

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
