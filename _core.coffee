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

  install: (window, cls) ->
    if window.apptools?
      window.apptools.sys.modules.install(cls)
    window.__apptools_preinit.deferred_core_modules.push cls
    return cls

## CoreObject: Holds an interactive object that is usually attached to a CoreAPI in some way.
class CoreObject

  install: (window, cls) ->
    window.__apptools_preinit.abstract_base_classes.push cls
    return cls

## CoreDriver: Specifies integration bridges, that must conform to at least one CoreInterface.
class CoreDriver extends CoreObject

  name: null        # shortname for this driver
  library: null     # library that this driver bridges to, if any
  interface: []     # list of interfaces this driver fulfills

  install: (window, cls) ->
    if window.apptools?
      window.apptools.sys.drivers.install(cls)
    window.__apptools_preinit.installed_drivers.push(cls)
    return cls

## CoreInterface: Specifies an interface, usually used to adapt multiple libraries/modules to one task.
class CoreInterface extends CoreObject

  parent: null      # interface parent for this capability
  required: []      # methods that must be on implementation drivers
  capability: null  # shortname for this capability, used as a prefix on drivers that implement this interface

  install: (window, cls) ->
    if window.apptools?
      window.apptools.sys.interfaces.install(cls)
    window.__apptools_preinit.abstract_feature_interfaces.push(cls)
    return cls

## CoreException: Abstract exception class
class CoreException extends Error

  constructor: (@module, @message, @context) ->
  toString: () ->
    return '[' + @module + '] CoreException: ' + @message

  install: (window, cls) ->
    window.__apptools_preinit.abstract_base_classes.push(cls)
    return cls

CoreException::install(window, CoreException)

##### ==== AppTools Internals ==== #####
class AppToolsDriver extends CoreDriver
class AppToolsException extends CoreException

##### ==== AppTools Extension Points ==== #####

# Extended capabilities
class Driver extends CoreDriver
class Interface extends CoreInterface


@__apptools_preinit.abstract_base_classes.push  CoreAPI,
                                                CoreObject,
                                                CoreInterface,
                                                CoreDriver,
                                                CoreException,
                                                AppToolsException,
                                                Driver,
                                                Interface