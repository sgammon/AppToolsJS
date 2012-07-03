## AppTools tabs widget & api
class TabsAPI extends CoreAPI

    @mount = 'tabs'
    @events = ['tabs_READY', 'tabs_API_READY']

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

            #
            return tabs

        @disable = (tabs) =>

            #
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

        @_state.config = Util.extend(true, @_state.config, JSON.parse(target.getAttribute('data-options')))

        @internal =

            classify: () =>

                tabset = Util.get(@_state.element_id)
                triggers = Util.get('tab-trigger', tabset) # the actual stylized 'tab' element
                tabs = Util.get('tab', tabset) # the attached

                tabset.classList.add('relative') if not Util.has_class(tabset, 'relative')

                trigger.classList.add('')


        @switch = (e) =>

            @_state.active = true

            tabset = Util.get(@_state.element_id)
            current = if (a_t=@_state.active_tab)? then Util.get(a_t) else Util.get('current-tab', tabset)[0]
            target = Util.get((trigger=e.target).getAttribute('id').split('-').splice(1))

            current.style.opacity = 0
            target.style.opacity = 1


