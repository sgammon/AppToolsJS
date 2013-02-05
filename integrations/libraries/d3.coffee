
class D3Driver extends Driver

	name: 'd3'
	library: window.d3
	interface: [
		QueryInterface,
		AnimationInterface,
		RPCInterface
	]


D3Driver.install(window)