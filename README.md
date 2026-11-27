# Hammerspoon Configuration

My personal [Hammerspoon](https://www.hammerspoon.org/) setup (symlinked to `~/.hammerspoon`). It is not meant to be copied 1:1.

## What it does

### Hyper key (`HyperController.lua`)

- Caps Lock is remapped to Escape in macOS.
- Hold it and press any key to send `⌃⌥⌘` + that key (an alert shows the combo).
- Tap it alone to send Escape.

### Adobe Premiere Pro (`AdobePremierePro.lua`)

Active only while Premiere (release or Beta) is frontmost. Not active while typing in a text field or holding Hyper.

- Single keys: `S` move playhead to the mouse, `D` move playhead and play at double speed, `M` add a timeline marker, `Z` play at double speed, `B` open a menu (`N` nest, `D` delete empty tracks, `O` make offline, `L` link media, `E` then `M` export markers or `E` export media).
- `Hyper + X` toggles the single keys. The `PR ●` / `PR ○` menubar item shows the state (click to toggle), and an alert stays up while they are off.
- The shortcuts Premiere has to have assigned are listed at the top of the file.

### Windows (`MoveWindow.lua`)

- `⌃⌥↓` moves the window to the next screen.
- `⌃⌥V` centers the window in a 9:16 portrait shape.

### Other

- `Option+Space` and `Shift+Option+Space` are swallowed so no non-breaking space gets typed.
- The config reloads itself when a `.lua` file changes.
- Set `DEBUG = true` in `init.lua` for verbose console output.

## Helper files

- `util.lua`: small helpers (alerts, focused element checks, window helpers).
- `AppWatcher.lua`: one shared `hs.application.watcher`; modules register for `activated`, `deactivated`, `launched` and so on.
- `_ClassSingleton.lua`: base for modules that must only exist once.
- `keys.lua`: shared modifier combinations.
- `Spoons/RecursiveBinderModified.spoon`: modal key menu used by the Premiere `B` menu (modified to sort keys, call an `onClose` function and expose `exitActive()`).

## graveyard/

Retired modules and experiments (DaVinci Resolve, Audition, Lightroom, iA Writer, image find, old `init.lua`, spaces binary, and more). They are not loaded and kept for reference only.
