## AppTools Widget Core
class CoreWidgetAPI extends CoreAPI

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
                        is_curr = target.classList.contains('active')

                        touched_targets.push(target)

                        _w = _.resolve_common_ancestor(trigger, target)
                        if _w? and _.has_class(_w, 'widget')
                            widget = _w
                            other.classList.remove('active') for other in others if (others = _.filter(_.get(target.tagName), (o) => return _.is_child(widget, o) and (o isnt target) and not _.in_array(touched_targets, o)))?

                        return if is_curr then target.classList.remove('active') else target.classList.add('active')
                
                else touched_targets = false
                return touched_targets

            else if e?
                throw 'Unparseable event object passed to default handle()'
            else
                throw 'Default handle() can only be called via event binding'

        @_init = () =>

            link.addEventListener('click', @handle , false) for link in target_links if (target_links = _.get('target-link'))?


class CoreWidget extends CoreObject

    constructor: () ->

        @_init = () =>
            return


if @__apptools_preinit?
    if not @__apptools_preinit.abstract_base_classes?
        @__apptools_preinit.abstract_base_classes = []
    if not @__apptools_preinit.deferred_core_modules?
        @__apptools_preinit.deferred_core_modules = []
else
    @__apptools_preinit =
        abstract_base_classes: []
        deferred_core_modules: []

@__apptools_preinit.abstract_base_classes.push CoreWidget
@__apptools_preinit.abstract_base_classes.push CoreWidgetAPI
@__apptools_preinit.deferred_core_modules.push {module: CoreWidgetAPI}
