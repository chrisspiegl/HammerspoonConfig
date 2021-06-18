# Hammerspoon Configuration

[Hammerspoon](https://www.hammerspoon.org/) is an incredible tool to automate keybaord shortcuts and much more on macOS. You can code things in [LUA](https://learnxinyminutes.com/docs/lua/) and make use of tones of [Spoons](https://www.hammerspoon.org/Spoons/) as integrations.

This repository contains my personal configuration and extensions I have built to use Hammerspoon with Adobe Premiere Pro, Adobe audition, and more.

## Status

This is my repository, it is evolving and not really meant to be copied 1=1. It's not even made to be modular really. But if you dive deeply enough, you may be able to figure out how things work and then you can make use of whatever part you like.

## Future Ideas

- Make individual Spoons
    + This would help make these more useful for others to include in their Hyperspoon installations.
    + HyperController
    + AdobePremierePro
    + AdobeAudition
    + AppWatcher
    + KeyboardAsMidi
- etc?

## Things I do with Hammerspoon

### General

- Move Windows Around into Certain Places
- Move Windows between Spaces
- Move Windows between External Screens
- Abilityto use the `hyper` Keybard Combination (CMD + CTRL + OPTION)
- Have a Dynamic App Launcher & Action Interface ready at all times
- Launch Applications via Shortcuts
- Open Projects in Sublime Text
- Generic Toggle Mic Mute/Active via Shortcuts
- Color the Menubar based on my Keyboard Layout (useful to know when I am in German layout and when I am in my default which is the U.S. Layout)
- etc.

### Premiere Pro

- Playback at Double Speed via one Key Press
- Apply Effects Presets via Actions Panel
- Export Media & Markers via Actions Panel
- Move Playhead by Clicking into the Timeline (instead of having to click on the top bar where the time markers are displayed)
- Cut + Move about 2 seconds in front of cut + Continue Fast Playback
- Ripple Delete + Move about 2 seconds in front of cut + Continue Fast Playback
- Add Timeline Marker (usually markers are placed onto the selected clip and when using the "auto select clip under playhead" that can be annoying, with my shorcut here it deselects everything and then sets the marker onto the timeline)

### Audition

- Playback at Double Speed via one Key Press
- Ripple Delete (similar to Premiere Pro Ripple Delete)
- Ripple Delete + Continue Fast Playback
- Cut + Continue Fast Playback
- Export Media & Markers via Actions Panel
- Import Markers via Actions Panel
- Go into Wave Editor, Heal Selection, and go back to Multi Track Editor

## Helper Files

### Utilities

The whole `util.lua` file is full of small functions which are quite useful to have things more accessible and with logical names.

### Class & ClassSingleton

The `_Class.lua` and `_ClassSingleton.lua` are utilitiy modules to be able to build Object Oriented modules with context and all. The Singleton — ofcourse — tries to make sure you only ever end up with one instance of whatever you are trying to open.

Specifically the `_ClassSingleton.lua` is used for things like the `AppWatcher` because the whole purpose of the `HyperController.lua`, `AppWatcher`, and others is that they only ever exist once in the whole application.

### AppWatcher

A module which starts a `hs.application.watcher` and I can then tell it to let me know when specific applications are `activated`, `deactivated`, `hidden`, `launched`, `launching`, `terminated`, or `unhidden`. This makes it so that there is only one `hs.application.watcher` and I don't have to implement that part of the logic in every other file.

Additionally, the purpose is to not tax the system with multiple `hs.application.watcher` processes and instead just have one which does that watching for me.

## Contact / Developer

Chris Spiegl - [ChrisSpiegl.com](https://ChrisSpiegl.com)
