## AppTools tabs widget & api
class TabsAPI extends CoreAPI

    @mount = 'tabs'
    @events = ['TABS_READY', 'TABS_API_READY']

    constructor: (apptools, widget, window) ->

        @_state =
            tabs: []
            tabs_by_id: {}
            init: false

        @create = (target) =>

            options = if target.hasAttribute('data-options') then JSON.parse(target.getAttribute('data-options')) else {}

            tabs = new Tabs(target, options)
            id = tabs._state.element_id

            @_state.tabs_by_id[id] = @_state.tabs.push(tabs) - 1

            return tabs._init()

        @destroy = (tabs) =>

            id = tabs._state.element_id

            @_state.tabs.splice(@_state.tabs_by_id, 1)
            delete @_state.tabs_by_id[id]

            document.body.removeChild(Util.get(id))

            return tabs

        @enable = (tabs) =>

            Util.bind(Util.get(trigger), 'click', tabs.switch, false) for trigger of tabs._state.tabs
            return tabs

        @disable = (tabs) =>

            Util.unbind(Util.get(trigger), 'click') for trigger of tabs._state.tabs
            return tabs

        @_init = () =>

            tabsets = Util.get 'pre-tabs'
            @enable(@create(tabs)) for tabs in tabsets

            apptools.events.trigger 'TABS_API_READY', @
            return @_state.init = true


class Tabs extends CoreWidget

    constructor: (target, options) ->

        @_state =

            element_id: target.getAttribute('id')
            active_tab: null
            tab_count: 0
            tabs: {}

            active: false
            init: false

            config:

                rounded: true
                width: '500px'

        @_state.config = Util.extend(true, @_state.config, options)

        @internal =

            classify: () =>

                target = Util.get(@_state.element_id)
                triggers = Util.get('a', target) # <a> --> actual 'tab'-looking element
                tabs = Util.get('div', target) # the content divs

                target.style.width = @_state.config.width
                target.classList.add(cls) for cls in ['relative', 'tabset']

                (if @_state.config.rounded then trigger.classList.add('tab-rounded') else trigger.classList.add('tab-link')) for trigger in triggers

                tab.classList.add(_cls) for _cls in ['absolute', 'tab'] for tab in tabs

                return @

        @make = () =>

            target = Util.get(@_state.element_id)
            triggers = Util.get('a', target)

            for trigger in triggers
                do (trigger) =>
                    content_div = Util.get(content_id=trigger.getAttribute('href').slice(1))
                    trigger.setAttribute('id', (trigger_id = 'a-'+content_id))

                    if not content_div?
                        return false
                    else
                        content_div.style.opacity = 0
                        content_div.classList.remove('pre-tabs')

                        trigger.removeAttribute('href')

                        @_state.tabs[trigger_id] = content_id
                        @_state.tab_count++

            return @internal.classify()

        @switch = (e) =>

            @_state.active = true

            tabset = Util.get(@_state.element_id)
            currents = Util.get('tab-current', tabset)
            current = if currents? then Util.get('tab-current', tabset)[0] else (if (_at=@_state.active_tab)? then Util.get(_at) else false)
            target = Util.get(target_id=(trigger=e.target).getAttribute('id').split('-').splice(1))
            console.log('TARGET_ID: '+target_id+' AND TARGET: '+target)

            return @ if current is target # return if current tab selected

            if current is false    # if no tab selected (first click), select first tab

                current = Util.get('div', tabset)[0]
                current.classList.add 'tab-current'

            $(current).animate opacity: 0,
                duration: 200
                complete: () =>
                    current.classList.remove('tab-current')
                    target.classList.add('tab-current')
                    @_state.active_tab = target_id
                    $(target).animate opacity: 1,
                        duration: 300
                        complete: () =>
                            @_state.active = false

        @_init = () =>

            tabs = @make()

            Util.get('a', Util.get(@_state.element_id))[0].click()

            @_state.init = true
            apptools.events.trigger 'TABS_READY', @

            return @



@__apptools_preinit.abstract_base_classes.push Tabs
@__apptools_preinit.abstract_base_classes.push TabsAPI
@__apptools_preinit.deferred_core_modules.push {module: TabsAPI, package: 'widgets'}