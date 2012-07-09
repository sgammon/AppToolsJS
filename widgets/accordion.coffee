class Accordion extends CoreWidget

    constructor: (target, options) ->

        @state =
            el: target
            folds: {}
            active: null
            init: false

        @defaults =

            axis: 'vertical'

            horizontal:
                closed:
                    height: '0px'
                    opacity: 0

                opened:
                    height: '350px'
                    opacity: 1

            vertical:
                closed:
                    width: '0px'
                    opacity: 0

                opened:
                    width: '350px'
                    opacity: 1

        @config = $.extend true, @defaults, options

        @fold = (section) =>

            @state.active = true
            accordion = @state.el
            sectionID = section.getAttribute 'id'
            sectionAnchor = accordion.getElementById 'a-' + sectionID
            current = accordion.getElementById(accordion.getElementsByClassName('current-fold')[0].getAttribute('id').split('-').slice(1).join '-') or false

            opened = if @config.axis is 'vertical' then @config.vertical.opened else @config.horizontal.opened
            closed = if @config.axis is 'vertical' then @config.vertical.closed else @config.horizontal.closed
            openAnimation = closeAnimation = @animation

            if current isnt false
                closeAnimation.complete = () =>
                    if current isnt section
                        current.className.replace /block/, 'none'
                    else
                        section.className.replace /block/, 'none'

                    @state.active = false
            else
                openAnimation.complete = () =>
                    @state.active = false

            if @util.hasClass section, 'none'

                @util.get('current-fold')[0].classList.remove 'current-fold'
                $(current).animate closed, closeAnimation

                section.style.height = '0px'
                section.className.replace /none/, 'block'
                sectionAnchor.classList.add 'current-fold'
                return $(section).animate opened, openAnimation

            else if @util.hasClass section, 'block'

                sectionAnchor.classList.remove 'current-fold'
                return $(section).animate closed, closeAnimation

            else false

        return @state.folds[@util.get('a-'+fold.getAttribute 'id')] = fold for fold in target.getElementsByClassName '.fold'


    _init: () ->

        @state.init = true
        return @

class AccordionAPI extends CoreWidgetAPI

    @mount = 'accordion'
    @events = ['ACCORDION_READY', 'ACCORDION_API_READY']

    constructor: (apptools, widget, window) ->

        @state =
            accordions: []
            accordions_by_id: {}
            next: accordions.length

        @create = (target, options={}) =>

            accordion = new Accordion target, @state.next, options
            @state.accordions_by_id[accordion.state.el.getAttribute 'id'] = @state.next
            @state.accordions.push accordion

            return accordion

        @destroy = (accordion) =>

            id = accordion.state.el.getAttribute 'id'

            @state.accordions.splice @state.accordions_by_id[id], 1
            delete @state.accordions_by_id[id]

            return accordion


        @enable = (accordion) =>

            @prime accordion.state.folds, accordion.fold
            return accordion

        @disable = (accordion) =>

            @unprime accordion.state.folds
            return accordion


    _init: (apptools) ->

        accordions = @util.get 'accordion-accordion'
        for accordion in accordions
            do (accordion) =>
                axis = accordion.getAttribute 'data-axis'
                accordion = if axis? then @create accordion, axis: axis else @create accordion
                accordion = @enable accordion

        return @


@__apptools_preinit.abstract_base_classes.push Accordion
@__apptools_preinit.abstract_base_classes.push AccordionAPI
@__apptools_preinit.deferred_core_modules.push {module: AccordionAPI, package: 'widgets'}