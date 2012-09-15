
class YepNopeDriver extends Driver

	name: 'yepnope'
	library: window.yepnope
	interface: [
		LoadAssetInterface
	]

	constructor: (library) ->

		## Asset Loading
		@load =
			script: (fragments...) =>
				return library.load fragments...

			styles: (fragments...) =>
				return library.load fragments...

		return @


YepNopeDriver.install(window)