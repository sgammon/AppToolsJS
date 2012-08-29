
class YepNopeDriver extends Driver

	name: 'yepnope'
	library: window.yepnope
	interface: [
		LoadAssetInterface
	]

	constructor: (library) ->

		## Asset Loading
		@load =
			script: () =>
			styles: () =>

		return @


YepNopeDriver.install(window)