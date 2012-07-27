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

            Util.bind(Util.get(trigger), 'mousedown', tabs.switch, false) for trigger of tabs._state.tabs
            return tabs

        @disable = (tabs) =>

            Util.unbind(Util.get(trigger), 'mousedown') for trigger of tabs._state.tabs
            return tabs

        @_init = () =>

            tabsets = Util.get 'pre-tabs'
            @enable(@create(tabs)) for tabs in tabsets if tabsets?

            return @_state.init = true


class Tabs extends CoreWidget

    constructor: (target, options) ->

        @_state =

            element_id: target.getAttribute('id')
            current_tab: null
            tab_count: 0
            tabs: {}

            active: false
            init: false

            config:

                rounded: true
                div_string: 'div'

        @_state.config = Util.extend(true, @_state.config, options)

        @internal =

            classify: () =>

                div_string = @_state.config.div_string
                target = Util.get(@_state.element_id)

                tabs = Util.filter(Util.get(div_string, target), (test=(el) ->       # content div elements
                    return el.parentNode is target
                ))
                triggers = Util.filter(Util.get('a', target), test)             # <a> --> actual 'tab'-looking element

                target.classList.add(cls) for cls in ['relative', 'tabset']

                (if @_state.config.rounded then trigger.classList.add('tab-rounded') else trigger.classList.add('tab-link')) for trigger in triggers

                tab.classList.add(_cls) for _cls in ['tab'] for tab in tabs

                return @

        @make = () =>

            target = Util.get(@_state.element_id)
            triggers = Util.filter(Util.get('a', target), (x) => return x.parentNode is target)

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

            tabset = Util.get(@_state.element_id)
            div_string = @_state.config.div_string
            current_tab = Util.get(@_state.current_tab) or (if (c = Util.get('current-tab', tabset))? then Util.filter(c, (x)->return (x.parentNode is tabset and x.tagName.toLowerCase() is div_string))[0] else null) or null
            current = false

            if e?
                if e.preventDefault
                    e.preventDefault()
                    e.stopPropagation()

                    target_tab = Util.get(target_id=(trigger=e.target).getAttribute('id').split('-').splice(1).join('-'))

                else if e? and e.nodeType
                    target_tab = e
                    trigger = Util.get('a-'+(target_id = e.getAttribute('id')))

                else       # assume it's a string ID
                    target_tab = Util.get(e)
                    trigger = Util.get('a-'+(target_id = e))

            else
                target_tab = Util.get(target_id = (trigger = Util.get('a', tabset)[0]).getAttribute('id').split('-').splice(1).join('-'))

            if current_tab?
                current_a = Util.get('a-' + current_tab.getAttribute('id')) or Util.get('a-'+@_state.current_tab)
                current = true

            return @ if current_tab is target_tab # return if current tab selected

            @_state.active = true

            console.log('Switching to tab: '+ target_id)

            if not current   # if no tab selected (first click), select first tab
                target_tab.classList.remove('none')
                target_tab.classList.add('current-tab')
                target_tab.classList.add('block')
                trigger.classList.add('current-tab')
                @_state.current_tab = target_tab.getAttribute('id')
                $(target_tab).animate opacity: 1,
                    duration: 300
                    complete: () =>
                        @_state.active = false

            else
                $(current_tab).animate opacity: 0,
                    duration: 200
                    complete: () =>
                        current_a.classList.remove('current-tab')
                        current_tab.classList.remove('current-tab')
                        current_tab.classList.remove('block')
                        target_tab.classList.remove('none')
                        current_tab.classList.add('none')
                        target_tab.classList.add('block')
                        target_tab.classList.add('current-tab')
                        trigger.classList.add('current-tab')
                        @_state.current_tab = target_tab.getAttribute('id')
                        $(target_tab).animate opacity: 1,
                            duration: 300
                            complete: () =>
                                @_state.active = false



            return @

        @_init = () =>

            tabs = @make()

            @switch()

            @_state.init = true

            return @



@__apptools_preinit.abstract_base_classes.push Tabs
@__apptools_preinit.abstract_base_classes.push TabsAPI
@__apptools_preinit.deferred_core_modules.push {module: TabsAPI, package: 'widgets'}