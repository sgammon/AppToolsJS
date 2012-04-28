## Setup preinit container (picked up in _init.coffee on AppTools init)
if @.__apptools_preinit?
  @.__apptools_preinit.lib = {}
  @.__apptools_preinit.abstract_base_classes = []
else
  @.__apptools_preinit =
    lib: {} # Holds shortcuts libraries that are detected
    abstract_base_classes: [] # Holds base classes that are setup before init

## CoreAPI: Holds a piece of AppTools core functionality.
class CoreAPI
@.__apptools_preinit.abstract_base_classes.push CoreAPI

## Check for Backbone.JS
if @.Backbone?
  # Mark it as found
  @.__apptools_preinit.lib.backbone =
    enabled: true
    reference: @.Backbone

  # Create Backbone.JS base classes
  class AppToolsView extends Backbone.View
  class AppToolsModel extends Backbone.Model
  class AppToolsRouter extends Backbone.Router
  class AppToolsCollection extends Backbone.Collection

else
  # No backbone :(
  @.__apptools_preinit.lib.backbone =
    enabled: false
    reference: null

  # Still export the classes...
  class AppToolsView
  class AppToolsModel
  class AppToolsRouter
  class AppToolsCollection

# Export to base classes
@.__apptools_preinit.abstract_base_classes.push AppToolsView
@.__apptools_preinit.abstract_base_classes.push AppToolsModel
@.__apptools_preinit.abstract_base_classes.push AppToolsRouter
@.__apptools_preinit.abstract_base_classes.push AppToolsCollection

## We might be running server side...
if exports?
  exports[key] = Milk[key] for key of Milk
  exports['CoreAPI'] = CoreAPI
  exports['AppToolsView'] = AppToolsView
  exports['AppToolsModel'] = AppToolsModel
  exports['AppToolsRouter'] = AppToolsRouter
  exports['AppToolsCollection'] = AppToolsCollection

else
  # We're not running sever side... export to the window...
  @.Milk = Milk
  @.CoreAPI = CoreAPI

  # Milk is embedded
  @.__apptools_preinit.lib.milk =
    enabled: true
    reference: @.Milk

  @.AppToolsView = AppToolsView
  @.AppToolsModel = AppToolsModel
  @.AppToolsRouter = AppToolsRouter
  @.AppToolsCollection = AppToolsCollection

  @.__AppToolsBaseClasses =
    AppToolsView: AppToolsView,
    AppToolsModel: AppToolsModel,
    AppToolsRouter: AppToolsRouter,
    AppToolsCollection: AppToolsCollection