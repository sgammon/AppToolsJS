## AppTools standalone media upload widget
class UploaderAPI extends CoreAPI

    @mount = 'uploader'
    @events = ['UPLOADER_READY', 'UPLOADER_API_READY']

    constructor: (apptools, widget, window) ->

        @_state =
            uploaders: []
            uploaders_by_id: {}
            init: false

        @create = (target) =>

            options = if target.hasAttribute('data-options') then JSON.parse(target.getAttribute('data-options')) else {}

            uploader = new Uploader(target, options)
            id = uploader._state.element_id

            @_state.uploaders_by_id[id] = @_state.uploaders.push(uploader) - 1

            return uploader._init()

        @destroy = (uploader) =>

            id = uploader._state.element_id

            @_state.uploaders.splice(@_state.uploaders_by_id[id], 1)
            delete @_state.uploaders_by_id[id]

            return uploader

        @enable = (uploader) =>

            target = Util.get(uploader._state.element_id)
            Util.bind(target, ['dragenter', 'dragexit', 'dragleave'], uploader.handle)
            Util.bind(target, 'dragover', Util.debounce(uploader.handle, 200, true))
            Util.bind(target, 'drop', uploader.upload)

            return uploader

        @disable = (uploader) =>

            target = Util.get(uploader._state.element_id)
            Util.unbind(target, 'dragenter', 'dragover', 'dragexit', 'dragleave', 'drop')

            return uploader

        @get = (element_id) =>

            return if (u = @_state.uploaders_by_id[element_id])? then @_state.uploaders[u] else false

        @_init = (apptools) =>

            uploaders = Util.get('pre-uploader')
            @enable(@create(uploader)) for uploader in uploaders

            apptools.events.trigger 'UPLOADER_API_READY', @
            return @_state.init = true


class Uploader extends CoreWidget

    constructor: (target, options) ->

        @_state =

            element_id: target.getAttribute 'id'
            boundary: null

            active: false
            init: false

            config:

                boundary_base: 'd4v1dR3K0W'
                banned_types: ['application/exe']
                banned_extensions: ['.exe']

                max_cache: 15

            cache:

                uploads_by_type: {}         # @[filetype] returns count
                uploaded: []                # max_cache is max length

        @_state.config = Util.extend(true, @_state.config, options)

        @internal =

            allow: (file) =>

                extension = file.name.split('.').pop()

                type = file.type

                return false if Util.in_array(extension, @_state.config.banned_extensions)
                return false if Util.in_array(type, @_state.config.banned_types)
                return true

            finish: @_state.config.finish or (file, xhr) =>

                # will eventually be default post-send callback
                return true

            prep_body: (file, data) =>

                return false if not @internal.allow(file)

                boundary = @_state.boundary
                crlf = '\r\n'

                body = '--' +  boundary + crlf
                body += 'Content-Disposition: form-data; filename="' + file.name + '"' + crlf
                body += 'Content-type: ' + file.type + crlf + crlf
                body += data + crlf + boundary + '--'

                return body

            preview: (e) =>

                # need upload UI before I know what goes here

                return

            progress: (file, xhr) =>

                xhr.upload.onprogress = (ev) =>

                    _f = file.name.split('.')[0]
                    if ev.lengthComputable
                        percent = Math.floor (ev.loaded/ev.total)*100

                        # need upload UI before I know what goes here
                        return percent

            provision_boundary: () =>

                _b = ['-----']
                base = @_state.config.boundary_base
                rand = Math.floor(Math.pow(Math.random() * 10000, 3))

                _b.push(base[char]) for char in rand.toString().split('')
                _b.push('-----')

                return _b.join('')

            read: (file, callback) =>

                reader = new FileReader()
                reader.file = file
                reader.onloadend = callback

                return reader.readAsBinaryString file

            ready: (file, xhr) =>

                xhr.onreadystatechange = () =>

                    if xhr.readyState = 4
                        if xhr.status = 200
                            @internal.update_cache file, xhr, (f, x) =>
                                @internal.finish(f, x)
                        else

                            # ideally we would handle all error cases - for now:

                            return false

            send: (file, data, url) =>

                xhr = new XMLHttpRequest()
                body = @internal.prep_body(file, data)

                @internal.progress(file, xhr)

                xhr.open('POST', url, true)
                xhr.setRequestHeader 'Content-type', 'multipart/form-data; boundary=' + @_state.boundary

                @internal.ready(file, xhr)

                apptools.dev.verbose 'UPLOADER', 'About to upload file: ' + file.name
                return if !!body then xhr.send body else false

            update_cache: (file, xhr, callback) =>

                if (t = @_state.cache.uploads_by_type)[type=file.type]?
                    t[type]++
                else
                    t[type] = (name=file.name)

                (u = @_state.cache.uploaded).push(name)
                u = u.splice(l - mx) if (l=u.length) > (mx = @_state.config.max_cache) # eject stalest items from cache

                return callback?.call(@, file, xhr)

        @handle = (e) =>

            console.log('EVENT OF TYPE '+e.type+' CAPTURED')

            if e.preventDefault
                e.preventDefault()
                e.stopPropagation()

            target = e.target

            switch e.type

                when 'dragenter', 'dragover'
                    target.style.border = '2px dashed green'

                when 'dragexit', 'dragleave'
                    target.style.border = '2px solid transparent'

                else return

        @upload = (e) =>

            if e.preventDefault
                e.preventDefault()
                e.stopPropagation()

            files = e.dataTransfer.files or []

            $.apptools.api.assets.generate_upload_url().fulfill(

                success: (response) =>
                    @internal.read file, (e) =>
                        e.preventDefault()
                        e.stopPropagation()

                        f = e.target.file
                        data = e.target.result
                        @internal.send(f, data, response.url)

                failure: (error) =>
                    apptools.dev.error 'UPLOADER', 'Upload failed with error: ' + error + ' :('

            ) for file in files

        @_init = (apptools) =>

            @_state.boundary = @internal.provision_boundary()
            @_state.init = true

            apptools.events.trigger 'UPLOADER_READY', @

            return @



@__apptools_preinit.abstract_base_classes.push Uploader
@__apptools_preinit.abstract_base_classes.push UploaderAPI
@__apptools_preinit.deferred_core_modules.push {module: UploaderAPI, package: 'widgets'}