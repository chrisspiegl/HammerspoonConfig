-- Remap Caps Lock -> F18 at the HID level (HyperController listens for F18).
-- hidutil mappings do not survive sleep/unlock/keyboard reconnects reliably, so re-apply them then.
local hidmap = {}

local MAPPING = '{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x70000006D}]}'

function hidmap.apply()
  local task = hs.task.new("/usr/bin/hidutil", function(exitCode, _, stdErr)
    if exitCode ~= 0 then
      print("hidmap: hidutil failed (" .. tostring(exitCode) .. "): " .. tostring(stdErr))
    end
  end, { "property", "--set", MAPPING })
  if task then task:start() end
end

function hidmap.start()
  hidmap.apply()

  -- Globals so the watchers are not garbage collected.
  hidmap_caffeinateWatcher = hs.caffeinate.watcher.new(function(event)
    if event == hs.caffeinate.watcher.systemDidWake
      or event == hs.caffeinate.watcher.screensDidUnlock then
      hidmap.apply()
    end
  end):start()

  local usbTimer
  hidmap_usbWatcher = hs.usb.watcher.new(function(device)
    if device.eventType == "added" then
      if usbTimer then usbTimer:stop() end
      usbTimer = hs.timer.doAfter(1, hidmap.apply)
    end
  end):start()
end

return hidmap
