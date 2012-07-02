## AppTools standalone media upload widget
class UploaderAPI extends CoreAPI

    @mount = 'upload'
    @events = ['UPLOADER_INIT', 'UPLOADER_READY']


class Uploader extends CoreWidget

    constructor: (target, options) ->

        @_state =

            active: false
            boundary: null

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

                extension = (file.name.split('.'))[(n.length-1)]
                type = file.type

                return false if Util.in_array(extension, @_state.config.banned_extensions)
                return false if Util.in_array(type, @_state.config.banned_types)
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

                return apptools.

            progress: (file, xhr) =>

                xhr.upload.onprogress = (ev) =>

                    _f = file.name.split('.')[0]
                    if ev.lengthComputable
                        percent = Math.floor (ev.loaded/ev.total)*100
                        # finish this shit

            provision_boundary: () =>

                _b = ['-----']
                base = @_state.config.boundary_base
                rand = Math.floor(Math.pow(Math.random() * 10000, 3))

                _b.push(base[char]) for char in rand.toString().split(''))
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
                                @finish(f, x)
                        else
                            # oops wut

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


        @upload = (e) =>

            e.preventDefault()
            e.stopPropagation()

            files = e.dataTransfer.files or []

            for file in files
                do (file) =>

                    $.apptools.api.assets.generate_upload_url().fulfill

                        success: (response) =>

                            @internal.read(file, (e) =>

                                e.preventDefault()
                                e.stopPropagation()

                                f = e.target.file
                                data = e.target.result

                                @internal.send(f, data, response.url)

                            )

                        failure: (error) =>

                            apptools.dev.error 'UPLOADER', 'Upload failed with error: ' + error + ' :('

        @_init = () =>

            @_state.boundary = @internal.provision_boundary()