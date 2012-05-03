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

            picker = @util.get @state.el.getAttribute 'id'
            hex = picker.getAttribute 'data-chosen-color' or picker.getAttribute 'data-default-color'
            swatches = @util.get 'swatch', palette

            hex_preview = (val) =>
                @util.get('colorhex', palette).innerHTML = val

            @state.active = true

            palette.style.top = @util.getOffset(picker).top + picker.offsetHeight
            palette.style.left = @util.getOffset(picker).left

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

            swatches = @util.get 'swatch', palette

            swatch.removeEventListener 'mousedown' for swatch in swatches
            palette.style.opacity = 0

            return @state.active = false

        @pick = (swatch) =>

            hex = swatch.getAttribute 'data-color'
            palette = swatch.parentNode
            picker = @util.get @state.el.getAttribute 'id'

            picker.setAttribute 'data-chosen-color', hex

            picker.style.backgroundColor =
            @util.get('colorhex', palette).innerHTML =
            hex

            @hide palette
            return palette

    _init: () ->

        palette = @make()
        document.body.appendChild palette

        @state.init = true
        return $.apptools.events.trigger 'COLORPICKER_READY', @


class ColorPickerAPI extends CoreWidgetAPI

    @mount = 'colorpicker'
    @events = ['COLORPICKER_READY', 'COLORPICKER_API_READY']

    constructor: (apptools, widget, window) ->

        @state =
            pickers: []
            pickers_by_id: {}
            next: pickers.length

        @create = (target, options={}) =>

            picker = new ColorPicker target, @state.next, options
            @state.pickers.push picker
            @state.pickers_by_id[picker.state.el.getAttribute 'id'] = @state.next

            return picker

        @destroy = (picker) =>

            id = picker.state.el.getAttribute 'id'
            palette = document.getElementById picker.state.palette

            @state.pickers.splice @state.pickers_by_id[id], 1
            delete @state.pickers_by_id[id]

            document.removeChild palette
            return picker

        @enable = (picker) =>

            el = picker.state.el
            @prime {el: @util.get picker.state.palette}, picker.show
            return picker

        @disable = (picker) =>

            @unprime [picker.state.el]
            return picker


    _init: (apptools) ->

        pickers = @util.get 'colorpicker'
        for picker in pickers
            do (picker) ->
                picker = @create picker
                picker = @enable picker

        return apptools.events.trigger 'COLORPICKER_API_READY', @



@__apptools_preinit.abstract_base_classes.push ColorPicker
@__apptools_preinit.abstract_base_classes.push ColorPickerAPI
@__apptools_preinit.deferred_core_modules.push {module: ColorPickerAPI, package: 'widgets'}