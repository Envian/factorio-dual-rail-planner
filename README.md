# Dual Rail Planner
A Factorio mod which turns the standard rail planner into a two lane planner.

### This is an early alpha, and is currently unstable.

## Usage
Use the new rail planner shortcut to begin placing rails. As you use this rail
planner, an opposite track will be automatically built. When done, simply clear
your cursor.

Be careful with left turns - if a turn is too sharp and the algorithm cannot
find a path for the opposite rail, then the planner will be cancelled.

## Known Issues
- Left turn algorithm is incomplete.
- Elevated rails are not fully tested.
    - When building elevated rails, start from an existing rail ghost.

## Roadmap
- [ ] Automatic Power Poles
- [ ] Configuration GUI
- [ ] Better left turn algorithm
- [ ] More build options
- [ ] 4 and 6 tile rail spacing
