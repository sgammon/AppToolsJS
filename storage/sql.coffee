class WebSQLEngine extends StorageAdapter

	constructor: () ->
		return


class WebSQLDriver extends StorageDriver

	constructor: () ->
		return

@__apptools_preinit.detected_storage_engines.push {name: "WebSQL", adapter: WebSQLEngine, driver: WebSQLDriver}
