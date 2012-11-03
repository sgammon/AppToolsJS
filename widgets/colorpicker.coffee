class ColorPicker extends CoreWidget

    constructor: (target, numID, options) ->

        @state =
            el: target
            palette: null
            active: false
            init: false

        @defaults =
            color: '000000'
            swatches: [
                '000000', '333333', '666666', '999999', 'CCCCCC', 'FFFFFF',
                '660000', 'AA0000', 'FF0000', 'FF4444', 'FF8888', 'FFCCCC',
                'FF6347', 'FF8C00', 'FFA500', 'FFCC00', 'FFD700', 'FFFF00',
                '8B4513', 'A0522D', 'B8860B', 'DAA520', 'F0E68C', 'EEE8AA',
                '003300', '006600', '009900', '33AA33', '66CC66', '99FF99',
                '000066', '0000AA', '0000FF', '4444FF', '8888FF', 'CCCCFF',
                '440044', '662266', '884488', 'AA66AA', 'CC99CC', 'FFCCFF'
            ]

        @config = $.extend true, @defaults, options

        @make = () =>

            palette = document.createElement 'div'

            palette.style.opacity = 0
            palette.setAttribute 'id', 'colorpick-palette-'+numID
            palette.className = 'colorpalette'

            swatches = @config.swatches

            for swatch in swatches
                do (swatch) ->
                    s = document.createElement 'div'
                    s.setAttribute 'data-color', '#' + swatch
                    s.className = 'swatch'
                    s.style.backgroundColor = '#' + swatch

                    return palette.appendChild s

            h = document.createElement 'div'
            h.className = 'colorhex'

            cv = document.createElement 'div'
            cv.setAttribute 'id', 'color-value-'+numID
            cv.className = 'colorvalue'
            cv.innerHTML = '&nbsp;'

            t = document.createTextNode 'Hex: '

            h.appendChild t
            h.appendChild cv
            palette.appendChild h

            # stash a reference to the palette
            @state.palette = palette.getAttribute 'id'

            return palette

        @show = (palette) =>

            picker = _.get @state.el.getAttribute 'id'
            hex = picker.getAttribute 'data-chosen-color' or picker.getAttribute 'data-default-color'
            swatches = _.get 'swatch', palette

            hex_preview = (val) =>
                _.get('colorhex', palette).innerHTML = val

            @state.active = true

            palette.style.top = _.getOffset(picker).top + picker.offsetHeight
            palette.style.left = _.getOffset(picker).left

            hex_preview hex

            document.body.addEventListener 'mousedown', @hide, false
            picker.addEventListener 'mousedown', @hide, false
            for swatch in swatches
                do (swatch) =>
                    swatch.addEventListener 'mousedown', @pick swatch, false 
                    swatch.addEventListener 'mouseover', () ->
                        hex_preview swatch.getAttribute 'data-color'
                    , false

            palette.style.opacity = 1
            return palette


        @hide = (palette) =>

            swatches = _.get 'swatch', palette

            swatch.removeEventListener 'mousedown' for swatch in swatches
            palette.style.opacity = 0

            return @state.active = false

        @pick = (swatch) =>

            hex = swatch.getAttribute 'data-color'
            palette = swatch.parentNode
            picker = _.get @state.el.getAttribute 'id'

            picker.setAttribute 'data-chosen-color', hex

            picker.style.backgroundColor =
            _.get('colorhex', palette).innerHTML =
            hex

            @hide palette
            return palette

        @init = () =>

            palette = @make()
            document.body.appendChild palette

            @state.init = true
            delete @init
            $.apptools.events.trigger 'COLORPICKER_READY', @
            return @


class ColorPickerAPI extends WidgetAPI

    @mount = 'colorpicker'
    @events = ['COLORPICKER_READY', 'COLORPICKER_API_READY']

    enable: (picker) ->

        el = picker.state.el
        @prime {el: _.get picker.state.palette}, picker.show
        return picker

    disable: (picker) ->

        @unprime [picker.state.el]
        return picker

    constructor: (apptools, widget, window) ->

        super(apptools, widget, window)
        return @



@__apptools_preinit.abstract_base_classes.push ColorPicker
@__apptools_preinit.abstract_base_classes.push ColorPickerAPI
@__apptools_preinit.deferred_core_modules.push {module: ColorPickerAPI, package: 'widgets'}