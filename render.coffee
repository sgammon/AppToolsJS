# Render API
class CoreRenderAPI extends CoreAPI

    @mount = 'render'
    @events = []
    @export = 'private'

    constructor: (apptools, window) ->
        @_init = () =>
            @environment = new RenderEnvironment(shared: true).set_loader_priority([
                DOMLoader,
                StorageLoader,
                ModelLoader,
                StringLoader
            ])._init()
            @context = new RenderContext()


class RenderException extends CoreException

class Template extends Model

    constructor : () ->

        @name = ''
        @source = ''
        @cacheable =
            rendered: false     # should we cache rendered templates?
            source: false       # what about source?

        return @

class DOMTemplate extends Template

    constructor : (element) ->
        attrs = _.to_array(element.attributes)

class QueryDriver extends CoreInterface

    @export = 'private'
    @methods = []

    constructor: () ->
        return

class AnimationDriver extends CoreInterface

    @export = 'private'
    @methods = []

    constructor: () ->
        return

class RenderDriver extends CoreInterface

    @export = 'private'
    @methods = []

    constructor: () ->
        return

class StringLoader extends RenderDriver
    # takes JS string template (Mustache {{x}} or Apptools [% x %] syntax) & returns prepared Template
    constructor: () ->

        @load = (pre_template) =>
            console.log(@constructor.name, 'Loading string templates currently stubbed.')
            return pre_template

        return @

class DOMLoader extends RenderDriver
    # takes pre-classed element and returns prepared Template
    constructor: () ->

        @load = (pre_template) =>
            console.log(@constructor.name, 'Loading DOM templates currently stubbed.')
            return pre_template

        return @

class ModelLoader extends RenderDriver
    # takes object model & returns prepped Template
    constructor: () ->

        @load = (pre_template) =>
            console.log(@constructor.name, 'Loading model templates currently stubbed.')
            return pre_template

        return @

class StorageLoader extends RenderDriver
    # takes StorageAPI key & returns stored Template
    constructor: () ->

        @load = (pre_template) =>
            console.log(@constructor.name, 'Loading templates from storage currently stubbed.')
            return pre_template

        return @


class TemplateContext extends Model
class RenderContext extends Model

    constructor: (ctxs=[]) ->

        for ctx in ctxs
            @[k] = v for own k, v of ctx

        return @

class RenderEnvironment extends Model

    @export = 'public'

    constructor: (options={}) ->
        ## Setup initial state & extend with user options

        @state = _.extend(true, {},

            template_loaded: false     # is template ready to render?

            template: null             # default template to use
            context: null              # base context
            loader: null               # loader
            loader_priority: []        # order in which to load

            filters: {}                # environment filters (currently stubbed)
            globals: {}                # base globals (probably not needed in JS?)
            shared: false              # can environment be reused/shared?

        , options)

        ## Internal methods

        @resolve_loader = () =>
            # If no loader set, resolve appropriate source loader via loader priority list.
            console.log('Resolving template loader...')

            priority = @state.loader_priority
            errors = []
            for driver in priority
                try
                    d = new driver()
                catch err
                    console.log('Invalid driver:', driver.toString())
                finally
                    break if d?
                    continue

            if errors.length is priority.length
                throw new RenderException(@constructor.name, 'Unable to resolve valid template loader.')
            else
                console.log('Template loader resolved.')
                return d

        @parse = () =>
            # parse Template and data object into pre-rendered Template
            console.log('Template parsing currently stubbed.')

            return @

        ## External methods

        # Template loading
        @set_loader = (@loader) =>
            # Manually sets template loader for this environment.
            console.log('Manually setting template loader.')

            return @

        @set_loader_priority = (p) =>
            # Manually sets priority array for template loaders
            console.log('Manually assigning template loader priority.')

            @state.loader_priority = p if _.is_array(p)
            return @

        @load = (name, loader=@loader) =>
            # Loads a named template, defaults to current loader.

            if _.is_array(name)
                return @select(name, loader)
            else
                return @

        @select = (names, loader=@loader) =>
            # Returns first found template in list of template names

            if !_.is_array(names)
                return @load(names, loader)
            else
                return @

        # Single-use manual loaders
        @load[k] = v for k, v of {
            from_string: (string) =>
                # Manually load template from string parameter.
                return @

            from_element: (element) =>
                # Manually load template from DOM element.
                return @

            from_model: (model) =>
                # Manually load template from model.
                return @
        }

        ## API methods
        @selfdestruct = () =>
            # Perform any final cleanup & trigger self-delete with Render API
            console.log('selfdestruct() currently stubbed. lucky you.');

            return @

        ## Init
        @_init = () =>
            if not @state.loader?
                try
                    @state.loader = @resolve_loader()
                catch err
                    console.error(@constructor.name, 'Couldn\'t resolve a template loader. Reraising...')
                    throw err

            return @

        return @



@__apptools_preinit.abstract_base_classes.push CoreRenderAPI, QueryDriver, AnimationDriver, RenderDriver, StringLoader, DOMLoader, ModelLoader, StorageLoader, RenderEnvironment
@__apptools_preinit.abstract_feature_interfaces.push {adapter: QueryDriver, name: "query"}, {adapter: RenderDriver, name: "render"}, {adapter: AnimationDriver, name: "animation"}
