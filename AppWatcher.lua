local util = require('./util')

-- TODO: possibly improve to handle window resizing as well?
-- Resource for window resize tracking: https://gist.github.com/tmandry/a5b1ab6d6ea012c1e8c5

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
  -- Prefix match: Beta uses a distinct full bundle id (e.g. …PremierePro.Beta); applicationsForBundleID is exact-only.
  local anyRunning = false
  for _, app in pairs(hs.application.runningApplications()) do
    local bid = app:bundleID()
    if bid and util.bundleIdHasPrefix(bid, appBundleId) then
      anyRunning = true
      break
    end
  end
  if anyRunning then
    local fnLaunched = currentApp[self.lookupAppWatchEvent[hs.application.watcher.launched]]
    if fnLaunched then fnLaunched() end
  end
  local frontApp = hs.application.frontmostApplication()
  local frontAppBundleID = frontApp and frontApp:bundleID()
  if frontAppBundleID and util.bundleIdHasPrefix(frontAppBundleID, appBundleId) then
    local fnActivated = currentApp[self.lookupAppWatchEvent[hs.application.watcher.activated]]
    if fnActivated then fnActivated() end
  end
end

function Class:buildEventtap()
  print('AppWatcher:buildEventtap')
  self.watcher = hs.application.watcher.new(function(appName, eventType, appObject)
    local appObjectBundleId = appObject and appObject:bundleID()
    if appObjectBundleId == nil then return end
    print("SWITCHING APP: " .. appObjectBundleId .. " - " .. eventType .. " - " .. self.lookupAppWatchEvent[eventType])
    for appBundleId, appEventFunctions in pairs(self.apps) do
      local appIsWatched = util.bundleIdHasPrefix(appObjectBundleId, appBundleId)
      if (appIsWatched) then
        local fn = appEventFunctions[self.lookupAppWatchEvent[eventType]]
        if fn then fn() end
      end
    end
  end)
end

return Class
