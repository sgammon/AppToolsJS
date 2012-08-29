
class JackedDriver extends Driver

	name: 'jacked'
	library: window.Jacked
	interface: [
		AnimationInterface
	]

	constructor: (library) ->

		## Animation
		@animation =
			animate: (to, settings) =>
			element: (to, settings) =>


JackedDriver.install(window)