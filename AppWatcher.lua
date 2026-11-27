local util = require('util')

-- TODO: possibly improve to handle window resizing as well?
-- Resource for window resize tracking: https://gist.github.com/tmandry/a5b1ab6d6ea012c1e8c5

local Class = require('_ClassSingleton')()
function Class:constructor()
  if DEBUG then print('AppWatcher:constructor') end
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
  if DEBUG then print('AppWatcher:watch: '..appBundleId) end
  self.apps[appBundleId] = functions
  if (options and type(options) == 'table' and next(options) ~= nil) then
    if options.checkFirst then self:checkInitialState(appBundleId) end
  end
end

function Class:unwatch(appBundleId)
  if DEBUG then print('AppWatcher:unwatch: ' .. appBundleId) end
  self.apps[appBundleId] = nil
end

function Class:watched()
  if DEBUG then print('AppWatcher:watched') end
  for key, value in pairs(self.apps) do
    if DEBUG then print('\t' .. key) end
  end
end

function Class:enable()
  if DEBUG then print('AppWatcher:enable') end
  if self.enabled then return end
  if not self.watcher then self:buildEventtap() end
  self.enabled = true
  self.watcher:start()
  return self
end

function Class:disable()
  if DEBUG then print('AppWatcher:disable') end
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
  if DEBUG then print('AppWatcher:buildEventtap') end
  self.watcher = hs.application.watcher.new(function(appName, eventType, appObject)
    local appObjectBundleId = appObject and appObject:bundleID()
    if appObjectBundleId == nil then return end
    if DEBUG then print("SWITCHING APP: " .. appObjectBundleId .. " - " .. eventType .. " - " .. self.lookupAppWatchEvent[eventType]) end
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
