# Dual Rail Planner
A Factorio mod which turns the standard rail planner into a two lane planner.

### This is an early alpha, and is currently unstable.

## Usage
Use the new rail planner shortcut to begin placing rails. As you use this rail
planner, an opposite track will be automatically built. When done, simply clear
your cursor. This mod does not work on regular rail planners - it only activates
when using the shortcut.

Be careful with left turns - if a turn is too sharp and the algorithm cannot
find a path for the opposite rail, then the planner will be cancelled.

## Known Issues
- Poor elevated rail support.
- Left turn algorithm is incomplete.
- Does not work well with undo.

## Roadmap
- [ ] Automatic Rail Signals
- [ ] Automatic Power Poles
- [ ] Configuration GUI
- [ ] Better left turn algorithm
- [ ] Elevated Rail Support
- [ ] More build options
