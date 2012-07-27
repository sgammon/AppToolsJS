## AppTools accordion widget & API
class AccordionAPI extends CoreWidgetAPI

    @mount = 'accordion'
    @events = ['ACCORDION_READY', 'ACCORDION_API_READY']

    constructor: (apptools, widget, window) ->

        @_state =
            accordions: []
            accordions_by_id: {}
            init: false

        @create = (target) =>

            options = if target.hasAttribute('data-options') then JSON.parse(target.getAttribute('data-options')) else {}

            accordion = new Accordion(target, options)
            id = accordion._state.element_id

            @_state.accordions_by_id[id] = @_state.accordions.push(accordion) - 1

            return accordion._init()

        @destroy = (accordion) =>

            id = accordion._state.element_id

            @_state.accordions.splice @_state.accordions_by_id[id], 1
            delete @_state.accordions_by_id[id]

            return accordion

        @enable = (accordion) =>

            (trigger.addEventListener('click', accordion.fold, false) if (trigger = Util.get('a-'+f))? and trigger.nodeType) for f in accordion._state.folds
            return accordion

        @disable = (accordion) =>

            (trigger.removeEventListener('click') if (trigger = Util.get('a-'+fold))? and trigger.nodeType) for fold in accordion._state.folds
            return accordion

        @get = (element_id) =>

            return if (u = @_state.accordions_by_id[element_id])? then @_state.accordions[u] else false

        @_init = () =>

            accordions = Util.get 'pre-accordion'
            @enable(@create(accordion)) for accordion in accordions if accordions?

            apptools.events.trigger 'ACCORDION_API_READY', @
            @_state.init = true

            return @


class Accordion extends CoreWidget

    constructor: (target, options) ->

        @_state =
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

        @_state.config = Util.extend(true, @_state.config, options)

        @internal =

            register_fold: (anchor) =>

                fold_id = if (f = anchor.getAttribute('href')).charAt(0) isnt '#' then f else f.slice(1)
                fold = Util.get(fold_id)
                anchor_id = 'a-' + fold_id

                fold.classList.add('accordion-fold')
                fold.classList.add('none')

                anchor.removeAttribute('href')
                anchor.setAttribute('id', anchor_id)
                anchor.classList.add('accordion-link')

                @_state.folds.push(fold_id)


        @fold = (e) =>

            if e.preventDefault
                e.preventDefault()
                e.stopPropagation()

            trigger = e.target
            target_div = Util.get(target_id = trigger.getAttribute('id').split('-').splice(1).join('-'))
            current_fold = Util.get(@_state.current_fold) or false
            current = false
            same = target_div is current_fold

            accordion = Util.get(@_state.element_id)

            [curr_folds, block_folds] = [Util.get('current-fold', accordion), Util.get('block', accordion)]

            (if folds?
                folds = Util.filter(folds, (el) -> return el.parentNode is accordion)) for folds in [curr_folds, block_folds]

            unique_folds = curr_folds
            (unique_folds.push(tab) if not Util.in_array(tab, unique_folds)) for tab in block_folds if block_folds

            if unique_folds?
                current = true

            @_state.active = true

            opened = @_state.config[axis = @_state.config.axis].opened
            opened.height = target_div.scrollHeight + 'px'
            closed = @_state.config[axis].closed
            open_anim = (close_anim = Util.prep_animation())

            ($(open_tab).animate(closed,
                duration: 400
                complete: () =>
                    open_tab.classList.remove(cls) for cls in ['current-fold', 'block']
                    open_tab.classList.add('none')
            )) for open_tab in unique_folds if unique_folds?

            open_anim.complete = () =>
                    target_div.classList.add('current-fold')
                    @_state.active = false
                    return @

            target_div.style[prop] for prop of closed

            if Util.has_class(target_div, 'none')
                target_div.classList.remove('none')
                target_div.classList.add('block')

            if not same
                $(target_div).animate(opened, open_anim)

            @_state.current_fold = target_id

            return @


        @_init = () =>

            accordion = Util.get(@_state.element_id)
            links = Util.filter(Util.get('a', accordion), (el) -> return el.parentNode is accordion)
            @internal.register_fold(link) for link in links if links?

            if current_fold?
                e = {}
                e.target = links[0]
                @fold(e)

            @_state.init = true
            return @



@__apptools_preinit.abstract_base_classes.push Accordion
@__apptools_preinit.abstract_base_classes.push AccordionAPI
@__apptools_preinit.deferred_core_modules.push {module: AccordionAPI, package: 'widgets'}