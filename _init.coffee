# AppTools Init
class AppTools

	constructor: (window)  ->

		## Basic system properties
		@sys =
			version:
				major: 0
				minor: 1
				micro: 4
				build: 04282012 # m/d/y
				release: "BETA"
			state: null
			platform: {}
			integrations: []
			drivers:
				transport: {}
				storage: {}
				render: {}
				register: (type, name, mountpoint, registered, inited) =>
					@sys.drivers[type] = {name: name, mount: mountpoint, registered: registered, init: inited}
					return @

			go: () =>
				@dev.log('Core', 'All systems go.')
				@sys.state = 'ready'
				return @

		## System config + state
		@config =
				rpc:
					base_uri: '/_api/rpc'
					host: null
					enabled: true

				sockets:
					host: null
					enabled: false

		@state = {}

		## Library Bridge
		@lib = {}

		## Find and register libraries

		# Modernizr
		if window?.Modernizr?
			@lib.modernizr = window.Modernizr
			@sys.integrations.push 'modernizr'
			@load = (fragment) =>
				return @lib.modernizr.load(fragment)

		# BackboneJS
		if window?.Backbone?
			@lib.backbone = window.Backbone
			@sys.integrations.push 'backbone'
			AppToolsView::apptools = @
			AppToolsModel::apptools = @
			AppToolsRouter::apptools = @
			AppToolsCollection::apptools = @

		# Lawnchair
		if window?.Lawnchair?
			@sys.integrations.push 'lawnchair'
			@lib.lawnchair = window.Lawnchair

		# AmplifyJS
		if window?.amplify?
			@sys.integrations.push 'amplify'
			@lib.amplify = window.amplify

		# jQuery
		if window?.jQuery?
			@sys.integrations.push 'jquery'
			@lib.jquery = window.jQuery

		# Milk (mustache for coffeescript)
		if window?.Milk?
			@sys.integrations.push 'milk'
			@lib.milk = window.Milk

		# Mustache
		if window?.Mustache?
			@sys.integrations.push 'mustache'
			@lib.mustache = window.Mustache

		## Dev API (for logging/debugging)
		@dev = new CoreDevAPI(@, window)

		## Model API
		@model = new CoreModelAPI(@, window)

		## Events API
		@events = new CoreEventsAPI(@, window)

		## Agent API
		@agent = new CoreAgentAPI(@, window)
		@agent.discover()

		## Dispatch API
		@dispatch = new CoreDispatchAPI(@, window)

		## JSONRPC (service layer) API
		@api = new CoreRPCAPI(@, window)

		## Users API
		@user = new CoreUserAPI(@, window)

		## Live API
		@push = new CorePushAPI(@, window)

		## We're done!
		return @.sys.go()

# Export to window
window.AppTools = AppTools
window.apptools = new AppTools(window)

# Is jQuery around?
if window.jQuery?
	# Attach jQuery shortcut
	$.extend(apptools: window.apptools)

# No? I'll just let myself in.
else
	# Attach jQuery shim
	window.$ = (id) -> document.getElementById(id)
	window.$.apptools = window.apptools
