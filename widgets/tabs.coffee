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

            options = _.data(target, 'options') or {}

            tabs = new Tabs(target, options)
            id = tabs._state.element_id

            @_state.tabs_by_id[id] = @_state.tabs.push(tabs) - 1

            return tabs._init()

        @destroy = (tabs) =>

            id = tabs._state.element_id

            @_state.tabs.splice(@_state.tabs_by_id, 1)
            delete @_state.tabs_by_id[id]

            document.body.removeChild(_.get(id))

            return tabs

        @enable = (tabs) =>

            _(trigger).bind('mousedown', tabs.switch, false) for trigger of tabs._state.tabs
            return tabs

        @disable = (tabs) =>

            _(trigger).bind('mousedown', tabs.switch) for trigger of tabs._state.tabs
            return tabs

        @_init = () =>

            tabsets = _.get '.pre-tabs'
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

        @_state.config = _.extend(true, @_state.config, options)

        @internal =

            classify: () =>

                div_string = @_state.config.div_string
                target = _.get(@_state.element_id)

                tabs = _.filter(_.get(div_string, target), (test=(el) ->       # content div elements
                    return el.parentNode is target
                ))
                height = 0
                for tab in tabs
                    height = tab.offsetHeight if tab.offsetHeight > height

                triggers = _.filter(_.get('.tab-link', target), test)             # <a> --> actual 'tab'-looking element

                target.classList.add(cls) for cls in ['relative', 'tabset']

                (if @_state.config.rounded then trigger.classList.add('tab-rounded') else trigger.classList.add('tab-link')) for trigger in triggers

                for tab in tabs
                    tab.classList.add('tab')
                    tab.style.height = height + 'px'
                    tab.style.width = '100%'


                return @

        @make = () =>

            target = _.get(@_state.element_id)
            triggers = _.filter(_.get('.tab-link', target), (x) => return x.parentNode is target)

            for trigger in triggers
                do (trigger) =>
                    content_div = _.get(content_id=(if trigger.hasAttribute('href') then trigger.getAttribute('href') else trigger.getAttribute('data-href')).slice(1))
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

            tabset = _.get(@_state.element_id)
            div_string = @_state.config.div_string
            current_tab = _.get(@_state.current_tab) or (if (c = _.get('current-tab', tabset))? then _.filter(c, (x)->return (x.parentNode is tabset and x.tagName.toLowerCase() is div_string))[0] else null) or null
            current = false

            if e?
                if e.preventDefault
                    e.preventDefault()
                    e.stopPropagation()

                    target_tab = _.get(target_id=(trigger=e.target).getAttribute('id').split('-').splice(1).join('-'))

                else if e? and e.nodeType
                    target_tab = e
                    trigger = _.get('a-'+(target_id = e.getAttribute('id')))

                else       # assume it's a string ID
                    target_tab = _.get(e)
                    trigger = _.get('a-'+(target_id = e))

            else
                target_tab = _.get(target_id = (trigger = _.get('.tab-link', tabset)[0]).getAttribute('id').split('-').splice(1).join('-'))

            if current_tab?
                current_a = _.get('a-' + current_tab.getAttribute('id')) or _.get('a-'+@_state.current_tab)
                current = true

            return @ if current_tab is target_tab # return if current tab selected

            @_state.active = true

            console.log('Switching to tab: '+ target_id)

            if not current   # if no tab selected (first click), select first tab
                target_tab.classList.add('current-tab')
                trigger.classList.add('current-tab')
                @_state.current_tab = target_tab.getAttribute('id')
                target_tab.fadeIn(display: 'block')
                @_state.active = false

            else
                current_tab.fadeOut callback: () =>
                    current_a.classList.remove('current-tab')
                    current_tab.classList.remove('current-tab')
                    target_tab.classList.add('current-tab')
                    trigger.classList.add('current-tab')
                    @_state.current_tab = target_tab.getAttribute('id')
                    target_tab.fadeIn(display: 'block')



            return @

        @_init = () =>

            tabs = @make()
            @switch()
            @_state.init = true

            return @



@__apptools_preinit.abstract_base_classes.push Tabs
@__apptools_preinit.abstract_base_classes.push TabsAPI
@__apptools_preinit.deferred_core_modules.push {module: TabsAPI, package: 'widgets'}