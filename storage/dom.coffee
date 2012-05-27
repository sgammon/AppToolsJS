class SimpleKeyEncoder extends KeyEncoder

	constructor: () ->

		## Key Operations
		@build_key = () =>
		@encode_key = () =>

		## Cluster Operations
		@build_cluster = () =>
		@encode_cluster = () =>

_simple_key_encoder = new SimpleKeyEncoder()


### === DOM Storage Engines === ###

## LocalStorage
class LocalStorageEngine extends StorageAdapter

	constructor: () ->

		# Async Methods
		@get_async = () =>
		@put_async = () =>
		@delete_async = () =>
		@clear_async = () =>

		# Non-Async Methods
		@get = () =>
		@put = () =>
		@delete = () =>
		@clear = () =>

		return

## SessionStorage
class SessionStorageEngine extends StorageAdapter

	constructor: () ->

		# Async Methods
		@get_async = () =>
		@put_async = () =>
		@delete_async = () =>
		@clear_async = () =>

		# Non-Async Methods
		@get = () =>
		@put = () =>
		@delete = () =>
		@clear = () =>

		return


### === DOM Storage Drivers === ###

## LocalStorage
class LocalStorageDriver extends StorageDriver

	constructor: () ->

		# Check compatibility
		@compatible = () =>

		# Construct a new backend
		@construct = () =>

		return


## SessionStorage
class SessionStorageDriver extends StorageDriver

	constructor: () ->

		# Check compatibility
		@compatible = () =>

		# Construct a new backend
		@construct = () =>

		return


@__apptools_preinit.detected_storage_engines.push {name: "LocalStorage", adapter: LocalStorageEngine, driver: LocalStorageDriver, key_encoder: _simple_key_encoder}
@__apptools_preinit.detected_storage_engines.push {name: "SessionStorage", adapter: SessionStorageEngine, driver: SessionStorageDriver, key_encoder: _simple_key_encoder}
