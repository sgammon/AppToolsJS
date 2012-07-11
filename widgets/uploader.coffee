## AppTools standalone media upload widget
class UploaderAPI extends CoreAPI

    @mount = 'uploader'
    @events = ['UPLOADER_READY', 'UPLOADER_API_READY']

    constructor: (apptools, widget, window) ->

        @_state =
            uploaders: []
            uploaders_by_id: {}
            init: false

        @create = (options) =>

            if not options?
                options = {}

            uploader = new Uploader(options)

            if options?.id?
                # if attached to an element, use element ID
                id = options.id

            else
                # otherwise use unique boundary with '-' trimmed
                (bound = uploader._state.boundary).match(/^-+(\w+)-+$/)
                uploader._state.config.id = (id = RegExp.$1)

            @_state.uploaders_by_id[id] = @_state.uploaders.push(uploader) - 1

            return uploader._init()

        @destroy = (uploader) =>

            id = uploader._state.config.id

            @_state.uploaders.splice(@_state.uploaders_by_id[id], 1)
            delete @_state.uploaders_by_id[id]

            return uploader

        @enable = (uploader) =>

            target = Util.get(uploader._state.config.id)
            target.addEventListener('drop', uploader.upload, false)

            return uploader

        @disable = (uploader) =>

            target = Util.get(uploader._state.element_id)
            Util.unbind(target, 'dragenter', 'dragover', 'dragexit', 'dragleave', 'drop')

            return uploader

        @get = (element_id) =>

            return if (u = @_state.uploaders_by_id[element_id])? then @_state.uploaders[u] else false

        @_init = () =>

            uploaders = Util.get('pre-uploader')
            _i = (_u) =>
                _u = @create(_u)
                if Util.is_id(_u._state.config.id)
                    _u = @enable(_u)

            _i(id: uploader.getAttribute('id')) for uploader in uploaders if uploaders?

            apptools.events.trigger 'UPLOADER_API_READY', @
            return @_state.init = true


class Uploader extends CoreWidget

    constructor: (options) ->

        @_state =

            boundary: null
            active: false
            init: false

            uploads:
                queued: 0
                finished: 0

            session: null

            config:

                boundary_base: 'd4v1dR3K0W'
                banned_types: ['application/exe']
                banned_extensions: ['.exe']

                max_cache: 15

                endpoints: []

                finish: null

            cache:

                uploads_by_type: {}         # @[filetype] returns count
                uploaded: []                # max_cache is max length

        @_state.config = Util.extend(@_state.config, options)

        @internal =

            allow: (file) =>

                extension = file.name.split('.').pop()

                type = file.type

                return false if Util.in_array(extension, @_state.config.banned_extensions)
                return false if Util.in_array(type, @_state.config.banned_types)
                return true

            finish: (response) =>

                if @_state.config.finish?
                    return @_state.config.finish(response)

                else return response

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

                xhr.onreadystatechange = (e) =>

                    if xhr.readyState = 4
                        if xhr.status = 200
                            @internal.update_cache(file, xhr)
                            @internal.finish(xhr.response)

                        else
                            return 'XHR finished with status '+xhr.status

            send: (file, data, url) =>

                xhr = new XMLHttpRequest()
                body = @internal.prep_body(file, data)

                @internal.progress(file, xhr)

                xhr.open('POST', url, true)
                xhr.setRequestHeader 'Content-type', 'multipart/form-data; boundary=' + @_state.boundary

                @internal.ready(file, xhr)

                apptools.dev.verbose 'UPLOADER', 'About to upload file: ' + file.name
                return if !!body then xhr.send body else false

            update_cache: (file, xhr) =>

                if (t = @_state.cache.uploads_by_type)[type=file.type]?
                    t[type]++
                else
                    t[type] = (name=file.name)

                (u = @_state.cache.uploaded).push(name)
                u = u.splice(l - mx) if (l=u.length) > (mx = @_state.config.max_cache) # eject stalest items from cache

        @_state.boundary = @internal.provision_boundary()

        @handle = (e) =>

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
                files = e.dataTransfer.files

            else if Util.is_array(e)
                files = e

            else if e.size
                files = [e]

            else files = []

            process_upload = (f, url) =>
                @_state.active = true
                @internal.read f, (ev) =>
                    ev.preventDefault()
                    ev.stopPropagation()

                    _f = ev.target.file
                    data = ev.target.result
                    @internal.send(_f, data, url)

            if not (e = @_state.config.endpoints)? or e.length < files.length
                if not e?
                    e = []
                diff = files.length - e.length

                $.apptools.api.media.generate_endpoint(
                        session_id: @_state.session
                        backend: 'blobstore'
                        file_count: diff
                    ).fulfill
                        success: (response) =>
                            @_state.config.endpoints = response.endpoints
                        failure: (error) =>
                            alert 'Uploader endpoint generation failed.'

            process_upload(file, @_state.config.endpoints[i]) for file, i in files

            return @

        @_init = () =>

            @_state.init = true

            return @



@__apptools_preinit.abstract_base_classes.push Uploader
@__apptools_preinit.abstract_base_classes.push UploaderAPI
@__apptools_preinit.deferred_core_modules.push {module: UploaderAPI, package: 'widgets'}