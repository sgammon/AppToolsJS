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
                if apptools.sys.state.config.user != false
                    @setUserInfo(true, apptools.sys.state.config.user, apptools.sys.state.config.permissions)
                else
                    @setUserInfo(false)

            return

        ## Set user info. Usually run by the server during JS injection.
        @setUserInfo = (authenticated, userinfo, permissions) =>

            if authenticated

                # Set user, log this, and trigger SET_USER_INFO
                @authenticated = true
                @current_user = userinfo
                @permissions = permissions

                apptools.dev.log('User', 'Set server-injected userinfo: ', {authenticated: authenticated, user: userinfo, permissions: permissions})
                apptools.events.trigger('SET_USER_INFO', userinfo, authenticated, permissions)
                return

            else

                @authenticated = false
                @current_user = null
                @permissions = {}

                apptools.dev.log('User', 'Server indicated that no user is currently logged in.')
                apptools.events.trigger('SET_USER_INFO', null, false, {})
                return

@__apptools_preinit.abstract_base_classes.push CoreUserAPI
