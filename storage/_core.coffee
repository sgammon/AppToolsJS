class StorageDriver extends CoreInterface

    @methods = ['compatible', 'construct']
    @export = "public"

    constructor: () ->

		# Check compatibility
		@compatible = () =>

		# Construct a new backend
		@construct = () =>

        return


class StorageAdapter extends CoreInterface

	@methods = ['get', 'put', 'delete', 'clear', 'get_async', 'put_async', 'delete_async', 'clear_async']
	@export = "public"

	constructor: () ->
		return


class KeyEncoder extends CoreInterface

	@methods = ['build_key', 'encode_key', 'build_cluster', 'encode_cluster']
	@export = "public"

	constructor: () ->
		return


# Setup preinit
if @__apptools_preinit?
    if not @__apptools_preinit.abstract_base_classes?
        @__apptools_preinit.abstract_base_classes = []
    if not @__apptools_preinit.deferred_core_modules?
        @__apptools_preinit.deferred_core_modules = []
else
    @__apptools_preinit =
        abstract_base_classes: []
        deferred_core_modules: []

# Add detected storage engines to the preinit
@__apptools_preinit.detected_storage_engines = []

# Push classes
@__apptools_preinit.abstract_base_classes.push StorageDriver
@__apptools_preinit.abstract_base_classes.push StorageAdapter

# Push interfaces
@__apptools_preinit.abstract_feature_interfaces.push {adapter: StorageDriver, name: "storage"}
