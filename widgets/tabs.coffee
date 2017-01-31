## AppTools tabs widget & api
class TabsAPI extends WidgetAPI

    @mount = 'tabs'
    @events = ['TABS_READY', 'TABS_API_READY']


class Tabs extends CoreWidget

    template: 'TabsWidget'
    event: 'click'

    handler: (e) ->

        return false if not e.target

        if e.preventDefault
            e.preventDefault()
            e.stopPropagation()

        trigger = e.target
        target_id = trigger.data('target')
        target = _.get(target_id)

        uuid = target.data('uuid')
        tabset = $.apptools.widgets.get(uuid)

        current = tabset.state.current
        tabset.state.active = true

        if not current?         # widget init()

            target.classList.add('current-tab')
            trigger.classList.add('current-tab')

            target.fadeIn(display: 'block')

        else

            current_a = _.get('#a-'+current.getAttribute('id'))

            current_a.classList.remove('current-tab')
            trigger.classList.add('current-tab')

            current.fadeOut callback: () ->

                current.classList.remove('current-tab')
                target.classList.add('current-tab')
                target.fadeIn
                    display: 'block'
                    callback: () ->
                        tabset.state.active = false


        tabset.state.current = target

        return tabset

    constructor: (target, options) ->

        target_id = target.getAttribute('id')
        super(target_id)

        @state =

            current: null
            tabs: []

            active: false
            init: false

            config: _.extend(

                rounded: true
                absolute: true

            , options)

            cached:
                id: target_id
                el: null

            history: []
            element: target

        @init = () =>

            source = _.get('#' + @state.cached.id)
            @state.cached.el = source

            tabs = _.filter(_.get('.tab-link', source), (x) -> return x.parentNode is source)

            for tab in tabs
                t_id = tab.data('target')
                target_id = t_id.slice(1)

                target = _.get(t_id)

                @state.tabs.push

                    trigger: tab.getAttribute('id')
                    target: target_id
                    name: tab.innerHTML
                    content: target.innerHTML

            @render

                id: @id
                uuid: @uuid
                rounded: @state.config.rounded
                tabs: @state.tabs
                absolute: @state.config.absolute

            @state.init = true
            delete @init

            return @

        return @



@__apptools_preinit.abstract_base_classes.push Tabs
@__apptools_preinit.abstract_base_classes.push TabsAPI
@__apptools_preinit.deferred_core_modules.push {module: TabsAPI, package: 'widgets'}