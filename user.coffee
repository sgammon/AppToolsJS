# User API
class CoreUserAPI extends CoreAPI

    @mount = 'user'
    @events = ['SET_USER_INFO']

    constructor: (apptools, window) ->
        @current_user = null
        @authenticated = false
        @permissions = {}

        @_init = (apptools) =>
            if apptools.sys.state.config? and apptools.sys.state.config?.user?
                @setUserInfo()

        ## Set user info. Usually run by the server during JS injection.
        @setUserInfo = (authenticated, userinfo, permissions) =>

            # Set user, log this, and trigger SET_USER_INFO
            @authenticated = true
            @current_user = userinfo
            @permissions = permissions

            apptools.dev.log('User', 'Set server-injected userinfo: ', {authenticated: authenticated, user: userinfo, permissions: permissions})
            apptools.events.trigger('SET_USER_INFO', userinfo, authenticated, permissions)
            return

@__apptools_preinit.abstract_base_classes.push CoreUserAPI
