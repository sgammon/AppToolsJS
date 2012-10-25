## AppTools accordion widget & API
class Accordion extends CoreWidget

    constructor: (target, options) ->

        super()

        @state =
            element_id: target.getAttribute('id')
            folds: []
            current_fold: null
            active: false
            init: false

            config:

                axis: 'vertical'

                vertical:
                    closed:
                        height: '0px'
                        opacity: 0

                    opened:
                        height: '75px'
                        opacity: 1

                horizontal:
                    closed:
                        width: '0px'
                        opacity: 0

                    opened:
                        width: '300px'
                        opacity: 1

        @state.config = _.extend(true, @state.config, options)

        @internal =

            register_fold: (anchor) =>

                fold_id = if (f = anchor.getAttribute('href')).charAt(0) isnt '#' then f else f.slice(1)
                fold = _.get(fold_id)
                anchor_id = 'a-' + fold_id

                fold.classList.add('accordion-fold')
                fold.classList.add('none')

                anchor.removeAttribute('href')
                anchor.setAttribute('id', anchor_id)
                anchor.classList.add('accordion-link')

                @state.folds.push(fold_id)


        @fold = (e) =>

            if e.preventDefault
                e.preventDefault()
                e.stopPropagation()

            trigger = e.target
            target_div = _.get(target_id = trigger.getAttribute('id').split('-').splice(1).join('-'))
            current_fold = _.get(@state.current_fold) or false
            current = false
            same = target_div is current_fold

            accordion = _.get(@state.element_id)

            [curr_folds, block_folds] = [_.get('.current-fold', accordion), _.get('.block', accordion)]

            (if folds?
                folds = _.filter(folds, (el) -> return el.parentNode is accordion)) for folds in [curr_folds, block_folds]

            unique_folds = curr_folds
            (unique_folds.push(tab) if not _.in_array(unique_folds, tab)) for tab in block_folds if block_folds

            if unique_folds?
                current = true

            @state.active = true

            opened = @state.config[axis = @state.config.axis].opened
            opened.height = target_div.scrollHeight + 'px'
            closed = @state.config[axis].closed
            open_anim = (close_anim = _.prep_animation())

            ($(open_tab).animate(closed,
                duration: 400
                complete: () =>
                    open_tab.classList.remove(cls) for cls in ['current-fold', 'block']
                    open_tab.classList.add('none')
            )) for open_tab in unique_folds if unique_folds?

            open_anim.complete = () =>
                    target_div.classList.add('current-fold')
                    @state.active = false
                    return @

            target_div.style[prop] for prop of closed

            if _.has_class(target_div, 'none')
                target_div.classList.remove('none')
                target_div.classList.add('block')

            if not same
                $(target_div).animate(opened, open_anim)

            @state.current_fold = target_id

            return @


        @init = () =>

            accordion = _.get(@state.element_id)
            links = _.filter(_.get('a', accordion), (el) -> return el.parentNode is accordion)
            @internal.register_fold(link) for link in links if links?

            if current_fold?
                e = {}
                e.target = links[0]
                @fold(e)

            @state.init = true
            delete @init
            return @


class AccordionAPI extends CoreWidgetAPI

    @mount = 'accordion'
    @events = ['ACCORDION_READY', 'ACCORDION_API_READY']


    enable: (accordion) ->

        (trigger.addEventListener('click', accordion.fold, false) if (trigger = _.get('#a-'+f))? and trigger.nodeType) for f in accordion._state.folds
        return accordion

    disable: (accordion) ->

        (trigger.removeEventListener('click') if (trigger = _.get('#a-'+fold))? and trigger.nodeType) for fold in accordion._state.folds
        return accordion

    constructor: (apptools, widget, window) ->

        super(apptools, widget, window)

        return @init()



@__apptools_preinit.abstract_base_classes.push Accordion
@__apptools_preinit.abstract_base_classes.push AccordionAPI
@__apptools_preinit.deferred_core_modules.push {module: AccordionAPI, package: 'widgets'}