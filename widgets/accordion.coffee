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

            (trigger.addEventListener('click', accordion.fold, false) if (trigger = Util.get('a-'+fold))? and trigger.nodeType) for fold in accordion._state.folds
            return accordion

        @disable = (accordion) =>

            (trigger.removeEventListener('click') if (trigger = Util.get('a-'+fold))? and trigger.nodeType) for fold in accordion._state.folds
            return accordion

        @get = (element_id) =>

            return if (u = @_state.accordions_by_id[element_id])? then @_state.accordions[u] else false

        @_init = () =>

            accordions = Util.get 'pre-accordion'
            @enable(@create(accordion)) for accordion in accordions if accordions?

            apptools.events.trigger 'ACCORDION_READY', @
            @_state.init = true

            return @


class Accordion extends CoreWidget

    constructor: (target, options) ->

        @_state =
            element_id: target.getAttribute('id')
            folds: []
            active: false
            init: false

            config:

                axis: 'vertical'

                horizontal:
                    closed:
                        height: '0px'
                        opacity: 0

                    opened:
                        height: '200px'
                        opacity: 1

                vertical:
                    closed:
                        width: '0px'
                        opacity: 0

                    opened:
                        width: '200px'
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
            target_div = Util.get(trigger.getAttribute('id').split('-').splice(1).join('-'))
            current = false

            accordion = Util.get(@_state.element_id)

            if (c = Util.get('current-fold', accordion))?
                c = Util.filter(c, test = (el) -> return el.parentNode is accordion)            # get only top-level divs/anchors marked 'current-fold'

                current_div = Util.filter(c, (x) -> return x.tagName.toLowerCase() is 'div')[0]
                current_a = Util.filter(c, (x) -> return x.tagName.toLowerCase() is 'a')[0]

                current = true

            @_state.active = true

            opened = @_state.config[axis = @_state.config.axis].opened
            closed = @_state.config[axis].closed
            open_anim = (close_anim = Util.prep_animation())

            if current
                close_anim.complete = () =>
                    closed = if current_div isnt target then current_div else target_div
                    closed.className.replace(/block/, 'none')
                    current_a.classList.remove('current-fold')
                    trigger.classList.add('current-fold')

                    @_state.active = false
                    return @

            else
                open_anim.complete = () =>
                    trigger.classList.add('current')

                    @_state.active = false
                    return @

            if Util.has_class(target_div, 'none')

                if current
                    current_div.classList.remove('current-fold')
                    $(current_div).animate(closed, close_anim)

                target_div.style[prop] for prop in closed
                target_div.className.replace(/none/, 'block')

            $(target_div).animate(opened, open_anim)

            @_state.current_fold = target_div.getAttribute('id')


        @_init = () =>

            accordion = Util.get(@_state.element_id)
            links = Util.filter(Util.get('a', accordion), (test=(el) -> return if el.parentNode is accordion then true else false))
            @internal.register_fold(link) for link in links if links?

            current_fold = if (c = Util.filter(Util.filter(Util.get('current', accordion), (x)-> return x.tagName.toLowerCase() is 'a'), test))? then c[0] else null
            if current_fold?
                e = {}
                e.target = current_fold
                @fold(e)

            @_state.init = true
            return @



@__apptools_preinit.abstract_base_classes.push Accordion
@__apptools_preinit.abstract_base_classes.push AccordionAPI
@__apptools_preinit.deferred_core_modules.push {module: AccordionAPI, package: 'widgets'}