## AppTools Widgets Core
class WidgetsAPI extends CoreAPI

    @mount: 'widgets'

    resolve_type: (uuid) ->
        return _.resolve_uuid(uuid, 'prefix')

    handle: (e) ->

        if e.preventDefault
            e.preventDefault()
            e.stopPropagation()

            trigger = e.target
            target_ids = _.filter(trigger.getAttribute('data-href').split('#'), (it) -> return it isnt '' and it isnt String())
            touched_targets = []

            if target_ids?
                for target_id in target_ids
                    target = document.getElementById(target_id)
                    is_curr = target.classList.contains('active') or trigger.classList.contains('active')

                    touched_targets.push(target)

                    _w = _.resolve_common_ancestor(trigger, target)
                    if _w? and _.has_class(_w, 'widget')
                        widget = _w
                        other_targ.classList.remove('active') for other_targ in other_targs if (other_targs = _.filter(_.get(target.tagName), (o) => return _.is_child(widget, o) and (o isnt target) and not _.in_array(touched_targets, o)))?
                        other_trig.classList.remove('active') for other_trig in other_trigs if (other_trigs = _.filter(_.get(trigger.tagName), (o) => return _.is_child(widget, o) and (o isnt trigger)))?

                    if is_curr

                        return @deferred
                            target: target
                            trigger: trigger
                            preventDefault: ->
                            stopPropagation: ->
                            callback: (targ, trig) ->
                                targ.classList.remove('active')
                                trig.classList.remove('active')
                                if trig.classList.contains('autoclose')
                                    targ.removeEventListener('mouseout', @handle, false)

                    else
                        target.classList.add('active')
                        trigger.classList.add('active')

                        target.addEventListener('webkitTransitionEnd', @deferred, false)
                        if trigger.classList.contains('autoclose')
                            target.addEventListener('mouseout', @handle, false)

                    return

            else touched_targets = false
            return touched_targets

        else if e?
            throw 'Unparseable event object passed to default handle()'
        else throw 'Default handle() can only be called via event binding'

    deferred: (e) ->

        if e.preventDefault
            e.preventDefault()
            e.stopPropagation()

            e.target?.removeEventListener('webkitTransitionEnd', @deferred)

            if (evc = e.callback)?
                tar = e.target
                tri = e.trigger
                deact = _.debounce((d) =>
                    return evc.call(@, tar, tri)
                , 50)
                cback = (ev) =>
                    if ev.preventDefault
                        ev.preventDefault()
                        ev.stopPropagation()
                        d = ev.target
                        d.removeEventListener('webkitTransitionEnd', cback)

                    return deact()

            custom = !!cback

            defers = e.target.find('.deferred')

            if not defers? or (defers.length and defers.length is 0)
                return (if custom then cback() else e)

            for defer in defers
                if custom
                    defer.addEventListener('webkitTransitionEnd', cback, false)
                    defer.classList.remove('active')
                else
                    defer.classList.add('active')

            return

        else if e?
            throw 'Unparseable event object passed to default deferred()'
        else throw 'Default deferred() can only be called via event binding'

    register: (widget) ->

        uuid = widget.uuid
        return false if not widget? or not uuid? or @state.index[uuid]?

        @state.index[uuid] = widget

        return widget


    get: (uuid, kind) ->

        return false if not uuid?
        return if kind? then @[kind].get(uuid) else (@state.index[uuid] or false)

    constructor: (apptools, window) ->

        @state =
            index: {}

        @init = () =>

            target_links = _.filter(_.get('.target_link'), (x) -> return x.hasClass('default-widget'))
            _.bind(link, 'click', @constructor::handle, false) for link in target_links if target_links?

            delete @init
            return @

        return @


class WidgetAPI extends CoreAPI

    create: (target) ->

        options = _.data(target, 'options')

        widget = new @class(target, options)
        widget.uuid = _.uuid(widget.constructor.name)

        id = widget.state.cached.id
        @state.index[id] = @state.data.push(widget.register(apptools)) - 1

        return widget.init(target)

    destroy: (widget) ->

        id = widget.state.cached.id

        @state.data.splice(@state.index[id], 1)
        delete @state.index[id]

        return widget

    enable: (widget) ->

        widget_el = _.get('#' + widget.id)
        widget_type = widget.constructor.name.toLowerCase()

        links = _.filter(_.get('.'+widget_type+'-link', widget_el), (x) ->
            return x.parentNode is widget_el
        )

        event = widget.constructor::event

        for link in links
            link.addEventListener(event, widget.handler, false)

        return widget

    disable: (widget) ->

        widget_el = _.get('#' + widget.id)
        widget_type = widget.constructor.name.toLowerCase()

        links = _.filter(_.get('.'+widget_type+'-link', widget_el), (x) ->
            return x.parentNode is widget_el
        )

        event = widget.constructor::event

        for link in links
            link.removeEventListener(event, widget.handler, false)

        return widget

    get: (id) ->

        return if (w_i = @state.index[id])? then @state.data[w_i] else false

    constructor: (apptools, window) ->

        super

        cls = @constructor.name.replace(/API/, '')

        @constructor::events = apptools.events
        @constructor::class = new Function('','return ' + cls + ';')()

        @state =
            index: {}
            data: []
            init: false

        @init = () ->
            widgets = _.get('.pre-'+cls.toLowerCase())
            @enable(@create(widget)) for widget in widgets
            @state.init = true

            delete @init
            return @

        return @


class CoreWidget extends Model

    enable: () ->

        api = @constructor.name.toLowerCase()
        return $.apptools.widgets[api].enable(@)

    disable: () ->

        api = @constructor.name.toLowerCase()
        return $.apptools.widgets[api].disable(@)

    calc: (element) ->

        source = @state.cached.el

        return false if not source or not element

        element.setAttribute('style', element.getAttribute('style') + ' ' +  source.getAttribute('style'))

        if not element.style.width
            element.style.width = source.scrollWidth + 'px'
        if not element.style.height
            element.style.height = source.scrollHeight + 'px'

        return element

    show: () ->

        return _.get('#'+@id).fadeIn()

    hide: () ->

        return _.get('#'+@id).fadeOut()

    register: (apptools) ->

        return false if not apptools?

        apptools.widgets.register(@)
        return @

    render: (context) ->

        sourcenode = @state.element or @state.cached.el
        template = window.templates[@constructor::template]
        temp = document.createElement(sourcenode.tagName)

        source_copy = sourcenode.cloneNode(false)
        temp.appendChild(source_copy)
        source_copy.outerHTML = template(context)

        new_source = _.get('.'+@constructor.name.toLowerCase(), temp)[0]
        @calc(new_source)

        before = sourcenode.nextSibling or sourcenode
        sourcenode.parentNode.insertBefore(new_source, before)
        @state.history.push(sourcenode.remove())
        @state.element = new_source

        return new_source

    constructor: (source_id) ->

        @id = @constructor.name.toLowerCase() + '-' + source_id
        return @

@__apptools_preinit?.abstract_base_classes.push CoreWidget
@__apptools_preinit?.abstract_base_classes.push WidgetsAPI, WidgetAPI
@__apptools_preinit?.deferred_core_modules.push {module: WidgetsAPI}