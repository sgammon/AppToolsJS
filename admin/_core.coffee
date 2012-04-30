## Admin API
class CoreAdminAPI extends CoreAPI

    @mount = 'admin'
    @events = []

    _init: (apptools) =>
        apptools.sys.state.add_flag 'admin'
        apptools.dev.log 'AdminAPI', 'NOTICE: Admin APIs are enabled.'
        return


@__apptools_preinit.abstract_base_classes.push CoreAdminAPI
@__apptools_preinit.deferred_core_modules.push {module: CoreAdminAPI}
