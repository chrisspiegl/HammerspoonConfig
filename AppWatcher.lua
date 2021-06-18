local Class = require('_ClassSingleton')()
function Class:constructor()
  print('AppWatcher:constructor')
  self.apps = {}
  self.enabled = false
  self.watcher = nil

  self.lookupAppWatchEvent = {
    [hs.application.watcher.activated] = "activated",
    [hs.application.watcher.deactivated] = "deactivated",
    [hs.application.watcher.hidden] = "hidden",
    [hs.application.watcher.launched] = "launched",
    [hs.application.watcher.launching] = "launching",
    [hs.application.watcher.terminated] = "terminated",
    [hs.application.watcher.unhidden] = "unhidden",
  }
end

function Class:watch(appBundleId, functions, options)
  print('AppWatcher:watch: '..appBundleId)
  self.apps[appBundleId] = functions
  if (options and type(options) == 'table' and next(options) ~= nil) then
    if options.checkFirst then self:checkInitialState(appBundleId) end
  end
end

function Class:unwatch(appBundleId)
  print('AppWatcher:unwatch: ' .. appBundleId)
  self.apps[appBundleId] = nil
end

function Class:watched()
  print('AppWatcher:watched')
  for key, value in pairs(self.apps) do
    print('\t' .. key)
  end
end

function Class:enable()
  print('AppWatcher:enable')
  if self.enabled then return end
  if not self.watcher then self:buildEventtap() end
  self.enabled = true
  self.watcher:start()
  return self
end

function Class:disable()
  print('AppWatcher:disable')
  if not self.enabled then return end
  self.enabled = false
  self.watcher:stop()
  return self
end

function Class:checkInitialState(appBundleId)
  local currentApp = self.apps[appBundleId]
  -- Cheeck if the app is running on initiation and if so run the `launched` function
  if next(hs.application.applicationsForBundleID(appBundleId)) ~= nil then
    local fnLaunched = currentApp[self.lookupAppWatchEvent[hs.application.watcher.launched]]
    fnLaunched()
  end
  -- Check if the app is the front most app and if so run `activated` function
  local frontAppBundleID = hs.application.frontmostApplication():bundleID()
  if frontAppBundleID:find("^"..appBundleId) then
    local fnActivated = currentApp[self.lookupAppWatchEvent[hs.application.watcher.activated]]
    fnActivated()
  end
end

function Class:buildEventtap()
  print('AppWatcher:buildEventtap')
  self.watcher = hs.application.watcher.new(function(appName, eventType, appObject)
    local appObjectBundleId = appObject:bundleID()
    print(appObjectBundleId)
    if (appObjectBundleId == nil) then return end
    for appBundleId, appEventFunctions in pairs(self.apps) do
      local appIsWatched = appObjectBundleId:find("^" .. appBundleId)
      if (appIsWatched) then
        local fn = appEventFunctions[self.lookupAppWatchEvent[eventType]]
        if fn then fn() end
      end
    end
  end)
end

return Class
