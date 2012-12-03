@WebSQLEngine = class WebSQLEngine extends StorageAdapter

	constructor: () ->
		return


@WebSQLDriver = class WebSQLDriver extends StorageDriver

	constructor: () ->
		return

@__apptools_preinit.detected_storage_engines.push {name: "WebSQL", adapter: WebSQLEngine, driver: WebSQLDriver}
@__apptools_preinit.abstract_base_classes.push WebSQLEngine, WebSQLDriver
