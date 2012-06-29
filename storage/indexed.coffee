class IndexedDBEngine extends StorageAdapter

	constructor: () ->
		return


class IndexedDBDriver extends StorageDriver

	constructor: () ->
		return

@__apptools_preinit.detected_storage_engines.push {name: "IndexedDB", adapter: IndexedDBEngine, driver: IndexedDBDriver}
