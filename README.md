# Dual Rail Planner
A Factorio mod which turns the standard rail planner into a two lane planner.

The goal of this mod is to replace "straight" segements in chunk aligned rail
blueprint books, specifically when building long railways to outposts where
chunk alignment is not necessary.

### This is an alpha, and is currently unstable.

## Usage
Use the new rail planner shortcut to begin placing rails. As you use this rail
planner, an opposite track will be automatically built. When done, simply clear
your cursor.

Be careful with left turns - if a turn is too sharp and the algorithm cannot
find a path for the opposite rail, then the planner will be cancelled.

## Known Issues
- The pathbuilding algorithm can give up in some circumstances, leaving the path
  incomplete.
- Elevated segments which are short won't produce a secondary path.
- Doesn't work in editor mode.


## Roadmap
- [ ] Automatic Power Poles
- [ ] Configuration GUI
- [ ] More build options
- [ ] Better mod compatibility
- [x] Better left turn algorithm
- [x] ~~4 and 6~~ configurable tile rail spacing
