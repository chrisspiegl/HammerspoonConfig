-- MODIFIED
-- Added output to "setState" so taht it alerts me of the state switch.
-- Added State display as alert which stays and shows either `muted` or `talking` top of the screen.
-- `talking` shows with red background color to be clear!
-- Added check when terminating one application which makes sure that no other application is actively running (basically runs the initialState() function again to make sure none of the defined apps is running)


--- === PushToTalk ===
---
--- Implements push-to-talk and push-to-mute functionality with `fn` key.
--- I implemented this after reading Gitlab remote handbook https://about.gitlab.com/handbook/communication/ about Shush utility.
---
--- My workflow:
---
--- When Zoom starts, PushToTalk automatically changes mic state from `default`
--- to `push-to-talk`, so I need to press `fn` key to unmute myself and speak.
--- If I need to actively chat in group meeting or it's one-on-one meeting,
--- I'm switching to `push-to-mute` state, so mic will be unmute by default and `fn` key mutes it.
---
--- PushToTalk has menubar with colorful icons so you can easily see current mic state.
---
--- Sample config: `spoon.SpoonInstall:andUse("PushToTalk", {start = true, config = { app_switcher = { ['zoom.us'] = 'push-to-talk' }}})`
--- and separate keybinding to toggle states with lambda function `function() spoon.PushToTalk.toggleStates({'push-to-talk', 'release-to-talk'}) end`
---
--- Check out my config: https://github.com/skrypka/hammerspoon_config/blob/master/init.lua

local util = require("./util")

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "PushToTalk"
obj.version = "0.1"
obj.author = "Roman Khomenko <roman.dowakin@gmail.com>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

obj.defaultState = 'mute'

obj.state = obj.defaultState
obj.pushed = false

--- PushToTalk.app_switcher
--- Variable
--- Takes mapping from application name to mic state.
--- For example this `{ ['zoom.us'] = 'push-to-talk' }` will switch mic to `push-to-talk` state when Zoom app starts.
obj.app_switcher = {}

--- PushToTalk.detect_on_start
--- Variable
--- Check running applications when starting PushToTalk.
--- Defaults to false for backwards compatibility. With this disabled, PushToTalk will only change state when applications are launched or quit while PushToTalk is already active. Enable this to look through list of running applications when PushToTalk is started. If multiple apps defined in app_switcher are running, it will set state to the first one it encounters.
obj.detect_on_start = false
obj.alert = nil
local pushTalkAlertStyleMuted = {
  radius = 0,
  atScreenEdge = 1,
  strokeColor = { white = 1, alpha = 0 },
  fadeInDuration = 0,
  fadeOutDuration = 0,
  strokeWidth = 0,
  textSize = 12,
}
local pushTalkAlertStyleTalking = {
  radius = 0,
  atScreenEdge = 1,
  fillColor = hs.drawing.color.x11.tomato,
  strokeColor = hs.drawing.color.x11.red,
  fadeInDuration = 0,
  fadeOutDuration = 0,
  strokeWidth = 0,
  textSize = 12,
}


local function showState()
    if obj.alert then hs.alert.closeSpecific(obj.alert) end
    local device = hs.audiodevice.defaultInputDevice()
    local muted = false
    if obj.state == 'unmute' then
        obj.menubar:setIcon(hs.spoons.resourcePath("speak.pdf"))
    elseif obj.state == 'mute' then
        obj.menubar:setIcon(hs.spoons.resourcePath("muted.pdf"))
        muted = true
    elseif obj.state == 'push-to-talk' then
        if obj.pushed then
            obj.menubar:setIcon(hs.spoons.resourcePath("record.pdf"), false)
        else
            obj.menubar:setIcon(hs.spoons.resourcePath("unrecord.pdf"))
            muted = true
        end
    elseif obj.state == 'release-to-talk' then
        if obj.pushed then
            obj.menubar:setIcon(hs.spoons.resourcePath("unrecord.pdf"))
            muted = true
        else
            obj.menubar:setIcon(hs.spoons.resourcePath("record.pdf"), false)
        end
    end

    device:setMuted(muted)
    if (obj.state == 'push-to-talk' or obj.state == 'release-to-talk') then
        obj.alert = hs.alert(muted and 'Mic: muted' or 'Mic: talking', muted and pushTalkAlertStyleMuted or pushTalkAlertStyleTalking, 'indefinite')
    end
end

function obj.setState(s)
    util.printAlert('Mic Toggle\nFrom: ' .. obj.state .. '\nTo: ' .. s)
    obj.state = s
    showState()
end

obj.menutable = {
    { title = "UnMuted", fn = function() obj.setState('unmute') end },
    { title = "Muted", fn = function() obj.setState('mute') end },
    { title = "Push-to-talk (fn)", fn = function() obj.setState('push-to-talk') end },
    { title = "Release-to-talk (fn)", fn = function() obj.setState('release-to-talk') end },
}

local function appWatcher(appName, eventType, appObject)
    local new_app_state = obj.app_switcher[appName];
    if (new_app_state) then
        if (eventType == hs.application.watcher.launching) then
            obj.setState(new_app_state)
        elseif (eventType == hs.application.watcher.terminated) then
            obj.setState(pushTalkInitialState())
        end
    end
end

local function eventTapWatcher(event)
    device = hs.audiodevice.defaultInputDevice()
    if event:getFlags()['fn'] then
        obj.pushed = true
    else
        obj.pushed = false
    end
    showState()
end

function pushTalkInitialState()
    local apps = hs.application.runningApplications()

    for i, app in pairs(apps) do
        for name, state in pairs(obj.app_switcher) do
            if app:name() == name then
                return state
            end
        end
    end

    return obj.defaultState
end

--- PushToTalk:init()
--- Method
--- Initial setup. It's empty currently
function obj:init()
end

--- PushToTalk:init()
--- Method
--- Starts menu and key watcher
function obj:start()
    self:stop()
    obj.appWatcher = hs.application.watcher.new(appWatcher)
    obj.appWatcher:start()

    obj.eventTapWatcher = hs.eventtap.new({hs.eventtap.event.types.flagsChanged}, eventTapWatcher)
    obj.eventTapWatcher:start()

    -- obj.menubar = hs.menubar.new():setTitle("PushToTalk"):setTooltip("PushToTalk")
    obj.menubar = hs.menubar.new():setTooltip("PushToTalk")
    obj.menubar:setMenu(obj.menutable)
    if obj.detect_on_start then obj.state = pushTalkInitialState() end
    obj.setState(obj.state)
end

--- PushToTalk:stop()
--- Method
--- Stops PushToTalk
function obj:stop()
    if obj.appWatcher then obj.appWatcher:stop() end
    if obj.eventTapWatcher then obj.eventTapWatcher:stop() end
    if obj.menubar then obj.menubar:delete() end
end

--- PushToTalk:toggleStates()
--- Method
--- Cycle states in order
---
--- Parameters:
---  * states - A array of states to toggle. For example: `{'push-to-talk', 'release-to-talk'}`
function obj:toggleStates(states)
    new_state = states[1]
    for i, v in pairs(states) do
        if v == obj.state then
            new_state = states[(i % #states) + 1]
        end
    end
    obj.setState(new_state)
end

return obj
