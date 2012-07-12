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
                tabs = Util.filter(Util.get('div', target), (test=(el) ->       # content div elements
                    return if el.parentNode is target then true else false
                ))
                triggers = Util.filter(Util.get('a', target), test)             # <a> --> actual 'tab'-looking element

                target.style.width = @_state.config.width
                target.classList.add(cls) for cls in ['relative', 'tabset']

                (if @_state.config.rounded then trigger.classList.add('tab-rounded') else trigger.classList.add('tab-link')) for trigger in triggers

                tab.classList.add(_cls) for _cls in ['absolute', 'tab'] for tab in tabs

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
            current = false

            if e?
                if e.preventDefault
                    e.preventDefault()
                    e.stopPropagation()

                    target_div = Util.get(target_id=(trigger=e.target).getAttribute('id').split('-').splice(1).join('-'))

                else if e? and e.nodeType
                    target_div = e
                    trigger = Util.get('a-'+(target_id = e.getAttribute('id')))

                else       # assume it's a string ID
                    target_div = Util.get(e)
                    trigger = Util.get('a-'+(target_id = e))

            else
                target_div = Util.get(target_id = (trigger = Util.get('a', tabset)[0]).getAttribute('id').split('-').splice(1).join('-'))

            if (c = Util.get('current-tab', tabset))?

                c = Util.filter(c, test = (el) -> return el.parentNode is tabset)            # get only top-level divs/anchors marked 'current-fold'
                c = @internal.find_match(c) if c.length > 2                                     # and only 1 pair

                current_div = Util.filter(c, (x) -> return x.tagName.toLowerCase() is 'div')[0]
                current_a = Util.filter(c, (x) -> return x.tagName.toLowerCase() is 'a')[0]

                current = true


            return @ if current_div is target_div # return if current tab selected

            @_state.active = true

            console.log('Switching to tab: '+ target_id)

            if not current   # if no tab selected (first click), select first tab
                target_div.classList.remove('none')
                target_div.classList.add('current-tab')
                target_div.classList.add('block')
                trigger.classList.add('current-tab')
                $(target_div).animate opacity: 1,
                    duration: 300
                    complete: () =>
                        @_state.active = false

            else
                $(current_div).animate opacity: 0,
                    duration: 200
                    complete: () =>
                        current_a.classList.remove('current-tab')
                        current_div.classList.remove('current-tab')
                        current_div.classList.remove('block')
                        target_div.classList.remove('none')
                        current_div.classList.add('none')
                        target_div.classList.add('block')
                        target_div.classList.add('current-tab')
                        trigger.classList.add('current-tab')
                        @_state.active_tab = target_id
                        $(target_div).animate opacity: 1,
                            duration: 300
                            complete: () =>
                                @_state.active = false

        @_init = () =>

            tabs = @make()

            @switch()

            @_state.init = true

            return @



@__apptools_preinit.abstract_base_classes.push Tabs
@__apptools_preinit.abstract_base_classes.push TabsAPI
@__apptools_preinit.deferred_core_modules.push {module: TabsAPI, package: 'widgets'}