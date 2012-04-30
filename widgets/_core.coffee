## AppTools Widget Core
class CoreWidgetAPI extends CoreAPI

    name = 'widget'
    events = []

    _init = (apptools) =>
        apptools.sys.state.add_flag 'widgets'
        apptools.dev.verbose 'CoreWidget', 'Widget functionality is currently stubbed.'
        return


class CoreWidget extends CoreObject


@__apptools_preinit.abstract_base_classes.push CoreWidget
@__apptools_preinit.abstract_base_classes.push CoreWidgetAPI
@__apptools_preinit.deferred_core_modules.push {module: CoreWidgetAPI}
