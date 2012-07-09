## AppTools Widget Core
class CoreWidgetAPI extends CoreAPI


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
