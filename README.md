# Dual Rail Planner
A Factorio mod which turns the standard rail planner into a two lane planner.

The goal of this mod is to replace "straight" segements in chunk aligned rail
blueprint books, specifically when building long railways to outposts where
chunk alignment is not necessary.

### This is an alpha, and is currently unstable.

Multiplayer should work in theory, but is curently untested.

## Usage
Use the new rail planner shortcut to begin placing rails. As you place rails,
an opposite track will be automatically built. When done, simply clear your
cursor. Does not currently support placing ramps, so all paths must be either
fully elevated, or fully grounded.

There are options to control the gap between rails, whether or not to add
signals, and how far to place signals apart.

## Supported Rails
- Vanilla Factorio 2.0
- Elevated Rails

## Unsupported Rails
These mods can still be used alongside Dual Rail Planner, but their custom rails
will not be available.

- [Space Exploration](https://mods.factorio.com/mod/space-exploration) Space Rails - support planned

## Known Issues
* Sharp left turns will cause the path builder to give up.
* Short elevated paths are not supported. If this happens, add more rail.
* There are edge cases that can result in broken tracks.
* Doesn't work with cheat mode (i.e. Editor mode).
* Placing rail over an existing track results in gaps.

Take a look at the
[Github Issues](https://github.com/Envian/factorio-dual-rail-planner/issues)
page to see more known issues, or to report bugs.

## Roadmap
- Automatic Power Poles
- Configuration GUI
- More build options
- Hotkeys
