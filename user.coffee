# User API
class CoreUserAPI extends CoreAPI

    constructor: (apptools, window) ->

		## Set user info. Usually run by the server during JS injection.
        @setUserInfo = (userinfo) =>

            $.apptools.dev.log('UserAPI', 'Setting server-injected userinfo: ', userinfo)
            @current_user = userinfo?.current_user
