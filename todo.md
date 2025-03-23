## Features

- Add another "rail" item so you can "replace" an existing rail to build the alternative path
- Improve left turn algorithm
- Add a UI when DPR is active, giving a few options:
    - rail spacing
    - Signal spacing
    - Behavior when left turns fail.
- Add automatic power poles between rails.
- Add support for modified rails, or non-standard rails.
    - Need mods to test with (boats mod?)

## Under the Hood

- Add "RailPath" class to manage paths.
    - RailBuilder will extend (or rewind) paths, instead of tracking history.
    - Support algorithm will march along a path to add supports.
    - Signal algorithm will march along the path, to add signals.
    - When a builder starts, path starts by finding existing rails behind builder.
    - Finds existing signals.
- Improve rail support algorithm.
    - Align supports on main and opposite path (using cheater supports, if possible.)
    - Add awareness for where the last support was.
    - Add checks and backsteps when supports cannot be placed (i.e. cliffs)
- Improve rail signal algorithm.
    - Respects distance since previous signal when starting a new builder.
    - Option to disable cosmetic aligned signals.
    - More alignment points on larger turns.
