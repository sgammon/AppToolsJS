## AppTools AccordionAPI & Accordion
class AccordionAPI extends WidgetAPI

    @mount: 'accordion'
    @events: ['ACCORDION_READY', 'ACCORDION_API_READY']


class Accordion extends CoreWidget

    template: 'AccordionWidget'
    event: 'click'

    handler: (e) ->

        if e.preventDefault
            e.preventDefault()
            e.stopPropagation()

        trigger = e.target
        target_id = trigger.data('target').slice(1) or trigger.getAttribute('id').split('-').slice(1).join('-')
        target = _.get('#'+target_id)

        accordion_el = trigger.parentNode
        accordion = $.apptools.widgets.get(accordion_el.data('uuid'))

        current_fold = accordion.state.current_fold or _.filter(_.get('.current-fold', accordion_el), (x) ->
            return x.parentNode is accordion_el and x.hasClass('accordion-fold'))[0]
        same = target is current_fold

        return accordion if same

        accordion.state.active = true

        if not current_fold?

            target.classList.add('current-fold')
            trigger.classList.add('current-fold')

            accordion.state.current_fold = target

            target.fadeIn()
            accordion.state.active = false

        else

            current_a = _.get('#a-'+current_fold.getAttribute('id'))

            current_a.classList.remove('current-fold')
            trigger.classList.add('current-fold')

            current_fold.fadeOut(
                callback: () =>
                    current_fold.classList.remove('current-fold')
                    target.classList.add('current-fold')

                    accordion.state.current_fold = target

                    target.fadeIn()
                    accordion.state.active = false
            )

        return accordion

    constructor: (target, options) ->

        target_id = target.getAttribute('id')
        super(target_id)

        @state =

            folds: []
            current_fold: null

            active: false
            init: false

            config: _.extend(

                axis: null              # 'horizontal' or 'vertical'

            , options)

            cached:
                id: target_id
                el: null

            history: []
            element: target


        @init = () =>

            source = _.get('#' + @state.cached.id)
            @state.cached.el = source

            links = _.filter(_.get('.accordion-link', source), (x) -> return x.parentNode is source)

            for link in links

                target_id = link.getAttribute('href').slice(1)
                target = _.get('#' + target_id)

                @state.folds.push

                    name: link.innerText
                    target:
                        id: target_id
                        innerHTML: target.innerHTML

            @render

                folds: @state.folds
                id: @id
                uuid: @uuid

            @state.init = true
            delete @init

            return @

        return @



@__apptools_preinit.abstract_base_classes.push Accordion
@__apptools_preinit.abstract_base_classes.push AccordionAPI
@__apptools_preinit.deferred_core_modules.push {module: AccordionAPI, package: 'widgets'}