
# Agent/Capabilities API
class CoreAgentAPI extends CoreAPI

    @mount = 'agent'
    @events = ['UA_DISCOVER']

    constructor: (apptools, window) ->

        # Expose platform & client results
        @platform = {}
        @fingerprint = {}
        @capabilities = {}

        # Modernizr can do it better
        if apptools.lib.modernizr?
            @capabilities = apptools.lib.modernizr
        @capabilities.simple = {}

        # Setup lookup data for User-Agent
        detection_data =

            browsers: [

                {string: navigator.userAgent, subString: "Chrome", identity: "Chrome"},
                {string: navigator.userAgent, subString: "OmniWeb", versionSearch: "OmniWeb/", identity: "OmniWeb"},
                {string: navigator.vendor, subString: "Apple", identity: "Safari", versionSearch: "Version"},
                {prop: window.opera, identity: "Opera"},
                {string: navigator.vendor, subString: "iCab", identity: "iCab"},
                {string: navigator.vendor, subString: "KDE", identity: "Konqueror"},
                {string: navigator.userAgent, subString: "Firefox", identity: "Firefox"},
                {string: navigator.vendor, subString: "Camino", identity: "Camino"},
                {string: navigator.userAgent, subString: "Netscape", identity: "Netscape"},
                {string: navigator.userAgent, subString: "MSIE", identity: "Explorer", versionSearch: "MSIE"},
                {string: navigator.userAgent, subString: "Gecko", identity: "Mozilla", versionSearch: "rv"},
                {string: navigator.userAgent, subString: "Mozilla", identity: "Netscape", versionSearch: "Mozilla"},
            ]

            os: [

                {string: navigator.platform, subString: "Win", identity: "Windows"},
                {string: navigator.platform, subString: "Mac", identity: "Mac"},
                {string: navigator.userAgent, subString: "iPhone", identity: "iPhone/iPod"},
                {string: navigator.platform, subString: "Linux", identity: "Linux"}

            ]

        _makeMatch = (sample) =>
            for value in sample
                if value.string?
                    if value.string.indexOf(value.subString) isnt -1
                        detection_data.versionSearchString = value.versionSearch || value.identity
                        return value.identity
                else if value.prop
                    detection_data.versionSearchString = value.versionSearch || value.identity
                    return value.identity

        _makeVersion = (dataString) =>
            index = dataString.indexOf(detection_data.versionSearchString)
            if index is -1
                return
            else
                return parseFloat(dataString.substring(index+detection_data.versionSearchString.length+1))

        # Discover info via User-Agent string
        discover = () =>

            # Match browser
            browser = _makeMatch(detection_data.browsers) || "unknown"
            version = _makeVersion(navigator.userAgent) || _makeVersion(navigator.appVersion) || "unknown"

            # Match OS
            os = _makeMatch(detection_data.os) || "unknown"
            if (browser.search('iPod/iPhone') != -1) || (browser.search('Android') != -1)
                type = 'mobile'
                mobile = true
            else
                type = 'desktop'
                mobile = false

            @platform =
                os: os
                type: type
                vendor: navigator.vendor
                product: navigator.product
                browser: browser
                version: version
                flags:
                    online: navigator.onLine || true
                    mobile: mobile
                    webkit: /AppleWebKit\//.test navigator.userAgent
                    msie: /MSIE/.test navigator.userAgent
                    opera: /Opera/.test navigator.userAgent
                    mozilla: /Firefox/.test navigator.userAgent

            # Simple capabilities exported by navigator/jquery
            @capabilities.simple.cookies = navigator.cookieEnabled
            if window.XMLHttpRequest?
                @capabilities.simple.ajax = true

            return {
                browser: [@platform.browser, @platform.version].join(":")
                mobile: @platform.flags.mobile
                legacy: @platform.flags.msie
            }

        @fingerprint = discover()
        return @

@__apptools_preinit.abstract_base_classes.push CoreAgentAPI
