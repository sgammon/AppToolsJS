
class ModernizrDriver extends Driver

	name: 'modernizr'
	library: window.Modernizr
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


ModernizrDriver.install(window)