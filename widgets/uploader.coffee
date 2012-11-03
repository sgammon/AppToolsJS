## AppTools standalone media upload widget
class UploaderAPI extends WidgetAPI

    @mount = 'uploader'
    @events = ['UPLOADER_READY', 'UPLOADER_API_READY']

    enable: (uploader) =>

        target = _.get(id = uploader._state.config.id)

        console.log('[UPLOADER:INIT]', 'Enabling drop zone on #'+id)
        target.addEventListener('drop', uploader.upload, false) if target?

        return uploader

    disable: (uploader) =>

        target = _.get(uploader._state.config.id)
        _.unbind(target, 'drop') if target?

        return uploader

    constructor: (apptools, widget, window) ->

        super(apptools, widget, window)

        @create = (kind, options) =>

            if _.is_raw_object(kind)
                options = kind
                kind = null

            if not options?
                options = {}

            uploader = new ArrayBufferUploader(options)

            if options?.id?
                # if attached to an element, use element ID
                id = options.id
                uploader = @enable(uploader) if _.is_id(id)

            else
                # otherwise use unique boundary with '-' trimmed
                (bound = uploader._state.boundary).match(/^-+(\w+)-+$/)
                uploader._state.config.id = (id = RegExp.$1)

            @state.index[id] = @state.data.push(uploader) - 1

            return uploader.init()

        return @


class Uploader extends CoreWidget

    allow: (file) ->

        extension = file.name.split('.').pop()

        type = file.type

        return false if _.in_array(@state.config.banned_extensions, extension)
        return false if _.in_array(@state.config.banned_types, type)
        return true

    finish: (response) ->

        if @state.config.finish?
            return @state.config.finish.call(@, response)

        else return response

    prep_body: (file, data) ->

        return false if not @allow(file)

        boundary = @state.boundary
        crlf = '\r\n'

        body = '--' +  boundary + crlf
        body += 'Content-Disposition: form-data; name="at-upload"; filename="' + file.name + '"' + crlf
        body += 'Content-type: ' + file.type + crlf + crlf
        body += data + crlf + crlf + '--' + boundary + '--'

        return body

    preview: (e) ->

        # need upload UI before I know what goes here

        return

    progress: (file, xhr) ->

        xhr.upload.onprogress = (ev) =>

            _f = file.name.split('.')[0]
            if ev.lengthComputable
                percent = Math.floor((ev.loaded/ev.total)*100)

                if @state.config.onprogress?
                    return @state.config.onprogress(percent)

    provision_boundary: () ->

        _b = ['-----']
        base = @state.config.boundary_base
        rand = Math.floor(Math.pow(Math.random() * 10000, 3))

        _b.push(base[char]) for char in rand.toString().split('')
        _b.push('-----')

        return _b.join('')

    read: (file, callback) ->

        reader = new FileReader()
        reader.file = file
        reader.onloadend = callback

        return reader.readAsBinaryString file

    ready: (file, xhr) ->

        xhr.onreadystatechange = () =>

            if xhr.readyState is 4 and xhr.status is 200

                response = xhr.responseText
                @update_cache(file, xhr)
                return @finish(JSON.parse(response))

            else if xhr.readyState is 4
                return 'XHR send finished with status '+xhr.status

            else
                return 'XHR send failed at readyState '+xhr.readyState

    send: (file, data, url) ->

        xhr = new XMLHttpRequest()
        body = @prep_body(file, data)

        @progress(file, xhr)

        xhr.open('POST', url, true)
        xhr.setRequestHeader 'Content-type', 'multipart/form-data; boundary=' + @state.boundary

        @ready(file, xhr)

        apptools.dev.verbose 'UPLOADER', 'About to upload file: ' + file.name
        return if !!body then xhr.send body else false

    update_cache: (file, xhr) ->

        remaining = @state.queued--

        @state.config.endpoints = [] if remaining is 0

        if (t = @state.cache.uploads_by_type)[type=file.type]?
            t[type]++
        else
            t[type] = (name=file.name)

        (u = @state.cache.uploaded).push(name)
        u = u.splice(l - mx) if (l=u.length) > (mx = @state.config.max_cache) # eject stalest items from cache

    constructor: (options) ->

        @state =

            queued: 0
            session: null

            config: _.extend(

                boundary_base: 'd4v1dR3K0W'
                banned_types: ['application/exe']
                banned_extensions: ['.exe']

                endpoints: []
                max_cache: 15

                finish: null

            , options)

            cache:

                uploads_by_type: {}         # @[filetype] returns count
                uploaded: []                # max_cache is max length

            boundary: @provision_boundary()
            active: false
            init: false

        @add_endpoint = (endpoint, clear_queue=false) =>

            if clear_queue
                @state.config.endpoints = []

            if _.is_array(endpoint)
                @add_endpoint(endpt, false) for endpt in endpoint

            else @state.config.endpoints.push(endpoint)

            return @

        @set_endpoint = (endpoint) =>

            @state.config.endpoints.unshift(endpoint)
            return @

        @add_callback = (callback) =>

            if _.is_function(callback)
                @state.config.finish = callback

            return @

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

                else
                    console.log('[Uploader]', 'Not sure how to handle a '+e.type+' event...:(')

            return @

        @upload = (e) =>

            if e.preventDefault
                e.preventDefault()
                e.stopPropagation()
                files = e.dataTransfer.files

            else if _.is_array(e)
                files = e

            else if e.size
                files = [e]

            else files = []

            process_upload = (f, url) =>
                @state.active = true
                @read f, (ev) =>
                    ev.preventDefault()
                    ev.stopPropagation()

                    _f = ev.target.file
                    data = ev.target.result
                    @send(_f, data, url)

            if not (e = @state.config.endpoints)? or e.length < files.length
                if not e?
                    @state.config.endpoints = []

                diff = files.length - @state.config.endpoints.length

                $.apptools.api.media.generate_endpoint(
                    backend: 'blobstore'
                    file_count: diff
                ).fulfill
                    success: (response) =>
                        @state.config.endpoints.push(endpt) for endpt in response.endpoints
                    failure: (error) =>
                        alert 'Uploader endpoint generation failed.'

            @state.queued = files.length
            process_upload(file, @state.config.endpoints.shift()) for file in files

            return @

        @init = () =>

            @state.init = true

            delete @init
            return @


class BinaryUploader extends Uploader


class DataURLUploader extends Uploader

    constructor: (options) ->

        super(options)

        @read = (file, callback) =>

            reader = new FileReader()
            reader.file = file
            reader.onloadend = callback

            return reader.readAsDataURL file


class ArrayBufferUploader extends BinaryUploader

    constructor: (options) ->

        super(options)

        @read = (file, callback) =>

            reader = new FileReader()
            reader.file = file
            reader.onloadend = callback

            return reader.readAsArrayBuffer file

        @send = (file, data, url) =>

            if not ArrayBuffer?
                return false

            xhr = new XMLHttpRequest()
            @progress(file, xhr)

            to_blob = (buff) =>
                mime = file.type

                abuff_view = new Uint8Array(buff)

                blobb = if window.BlobBuilder then new BlobBuilder() else if window.WebKitBlobBuilder then new WebKitBlobBuilder() else if window.MozBlobBuilder then new MozBlobBuilder() else null

                if blobb?
                    blobb.append(abuff_view.buffer)
                    return blobb.getBlob(mime)
                else
                    return null

            fd = new FormData()
            fd.append('file', to_blob(data))

            xhr.open('POST', url, true)
            @ready(file, xhr)
            return xhr.send(fd)



@__apptools_preinit.abstract_base_classes.push Uploader
@__apptools_preinit.abstract_base_classes.push UploaderAPI
@__apptools_preinit.deferred_core_modules.push {module: UploaderAPI, package: 'widgets'}