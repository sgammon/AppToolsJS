@IndexedDBEngine = class IndexedDBEngine extends StorageAdapter

	constructor: () ->
		return


@IndexedDBDriver = class IndexedDBDriver extends StorageDriver

	constructor: () ->
		return

@__apptools_preinit.detected_storage_engines.push {name: "IndexedDB", adapter: IndexedDBEngine, driver: IndexedDBDriver}
@__apptools_preinit.abstract_base_classes.push IndexedDBEngine, IndexedDBDriver