
class jQueryDriver extends Driver

	name: 'jquery'
	library: window.jQuery
	interface: [
		QueryInterface,
		AnimationInterface,
		RPCInterface
	]

	constructor: (library) ->

		## DOM Querying
		@query =
			get: (selector) =>
				return library(selector)

			element_by_id: (id) =>
				return library(["#", id].join(""))

			elements_by_tag: (tagname) =>
				return library(tagname)

			elements_by_class: (classname) =>
				return library([".", classname].join(""))

		## RPC/Transport
		@rpc =
			factory: (context) =>
				return $.ajaxSettings.xhr(context)

			fulfill: (xhr, request, dispatch) =>

		## Animation
		@animation =
			animate: (to, settings) =>
			element: (to, settings) =>

		return @


jQueryDriver.install(window)