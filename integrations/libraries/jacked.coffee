
class JackedDriver extends Driver

	name: 'jacked'
	library: window.Jacked
	interface: [
		AnimationInterface
	]

	constructor: (library, apptools, window) ->

		## Animation
		@animation =

			## Generate library bindings
			tween: (el, to, settings) => return library.tween(el, to, settings)
			animate: (to, settings) => return library.tween(@, to, settings)
			element: (to, settings) => return @jacked(to, settings)
			special: (el, settings) => return library.special(el, settings)
			fade_in: (el, settings) => return library.fadeIn(el, settings)
			fade_out: (el, settings) => return library.fadeOut(el, settings)
			stop_all: (complete) => return library.stopAll(complete)
			transform: (el, to, settings, fallback) => return library.transform(el, to, settings, fallback)
			percentage: (el, anim, settings) => return library.percentage(el, anim, settings)

		## Bind animation methods to HTMLElement's prototype
		window.Element::animate = (to, settings) ->
			if settings.complete? then settings.callback = settings.complete
			return @jacked(to, settings)

		window.Element::fadeIn = @animation.fade_in
		window.Element::fadeOut = @animation.fade_out
		window.Element::transform = @animation.transform

		window.Element::stopAnimation = (complete, do_callback) ->
			return library.stopTween(@, complete, do_callback)


JackedDriver::install(window, JackedDriver)