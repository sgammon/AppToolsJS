
class ModernizrDriver extends Driver

	name: 'modernizr'
	library: window.Modernizr
	interface: [
		LoadAssetInterface
	]

	constructor: (library) ->

		## Asset Loading
		@load =
			script: () =>
			styles: () =>

		return @


ModernizrDriver.install(window)