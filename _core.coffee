##### ==== Boot/Preinit Operations List ==== #####

__apptools_preinit_bootlist = [
  'installed_drivers'              # Holds base classes that are setup before init.
  'installed_integrations',        # Holds core modules that are setup during init.
  'abstract_base_classes',         # Holds interfaces that wrap drivers and libraries.
  'abstract_feature_interfaces',   # Holds libraries detected before init.
  'deferred_core_modules',         # Holds installed AppTools integrations for init detection.
  'deferred_library_integrations'  # Holds installed drivers that must be instantiated during init.
]

## Setup preinit container (picked up in _init.coffee on AppTools init)
@__apptools_preinit = {}
for boot in __apptools_preinit_bootlist
  @__apptools_preinit[boot] = []


##### ==== Core APIs and Objects ==== #####

## CoreAPI: Holds a piece of AppTools core functionality.
class CoreAPI

  install: (window, i) ->
    if window.apptools?
      window.apptools.sys.modules.install(i)
    window.__apptools_preinit.deferred_core_modules.push i
    return i

  constructor: (apptools, window) ->

    if apptools?.events?
      @events = apptools.events
    return

window.CoreAPI = CoreAPI

## CoreObject: Holds an interactive object that is usually attached to a CoreAPI in some way.
class CoreObject

  install: (window, i) ->
    window.__apptools_preinit.abstract_base_classes.push i
    return i
window.CoreObject = CoreObject

## CoreDriver: Specifies integration bridges, that must conform to at least one CoreInterface.
class CoreDriver extends CoreObject

  name: null        # shortname for this driver
  library: null     # library that this driver bridges to, if any
  interface: []     # list of interfaces this driver fulfills

  constructor: (apptools) -> @

  install: (window, i) ->
    if window.apptools?
      window.apptools.sys.drivers.install(i)
    window.__apptools_preinit.installed_drivers.push(i)
    window[i.name] = i
    return i
window.CoreDriver = CoreDriver

## CoreInterface: Specifies an interface, usually used to adapt multiple libraries/modules to one task.
class CoreInterface extends CoreObject

  parent: null      # interface parent for this capability
  required: []      # methods that must be on implementation drivers
  capability: null  # shortname for this capability, used as a prefix on drivers that implement this interface
  static: true      # specifies that once a driver is resolved, it can be used for the lifetime of the session without perfoming checks again

  constructor: (apptools) ->
    @drivers =
      adapters: {}
      priority: []
      selected: null

  install: (window, i) ->
    if window.apptools?
      window.apptools.sys.interfaces.install(i)
    window.__apptools_preinit.abstract_feature_interfaces.push(i)
    window[i.name] = i
    return i

  add: (driver) ->
    @drivers.adapters[driver.name] = driver
    @drivers.priority.push driver.name
    return

  resolve: (name) ->
    if name?
      if @drivers.adapters[name]?
        return @drivers.adapters[name]
      return false
    if @static and @drivers.selected?
      return @drivers.adapters[@drivers.selected]
    else
      start_p = -1
      for driver in @drivers.priority
        if driver.priority? and driver.priority > start_p
          @drivers.selected = driver
        else
          if not driver.priority?
            @drivers.selected = driver
          continue
      if @drivers.selected == null
        return false
      return @drivers.adapters[@drivers.selected]
window.CoreInterface = CoreInterface

## CoreException: Abstract exception class
class CoreException extends Error

  constructor: (@module, @message, @context) ->
  toString: () ->
    return '[' + @module + '] CoreException: ' + @message

  install: (window, i) ->
    window.__apptools_preinit.abstract_base_classes.push(i)
    return i

window.CoreException = CoreException

##### ==== AppTools Internals ==== #####
class AppToolsDriver extends CoreDriver
class AppToolsException extends CoreException

window.AppToolsDriver = AppToolsDriver
window.AppToolsException = AppToolsException


##### ==== AppTools Extension Points ==== #####

# Extended capabilities
class Driver extends CoreDriver
class Interface extends CoreInterface

window.Driver = Driver
window.Interface = Interface

@__apptools_preinit.abstract_base_classes.push  CoreAPI,
                                                CoreObject,
                                                CoreInterface,
                                                CoreDriver,
                                                CoreException,
                                                AppToolsException,
                                                Driver,
                                                Interface