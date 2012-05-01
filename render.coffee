# Dispatch API
class CoreRenderAPI extends CoreAPI

    @mount = 'render'
    @events = []
    @export = "private"

    constructor: (apptools, window) ->
		return

	_init: () ->
		return



class RenderDriver extends CoreInterface

	@export = "private"
	@methods = []

	constructor: () ->
		return


class QueryDriver extends CoreInterface

	@export = "private"
	@methods = []

	constructor: () ->
		return


@__apptools_preinit.abstract_base_classes.push QueryDriver
@__apptools_preinit.abstract_base_classes.push RenderDriver
@__apptools_preinit.abstract_base_classes.push CoreRenderAPI
@__apptools_preinit.abstract_feature_interfaces.push {adapter: RenderDriver, name: "render"}
