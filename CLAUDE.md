# godot — Godot 4.6 Project

## Setup (one-time)
```bash
godot-dev download-engine          # downloads Godot 4.6-stable to ~/.godot-kit/
godot-dev setup                    # installs gdtoolkit via pip3 (needs Python 3)
godot-dev download-export-templates # only needed before first export
```

## Workflow: editing and running
Always edit .gd and .tscn files directly with Read/Write/Edit tools.
After writing files, the editor auto-imports — use `godot-dev wait-import` if you need to confirm before querying the editor.

Launch the game (keep running in background):
```bash
godot-dev launch                   # starts Godot, debugger on :6007, game HTTP on :6009
```

While game is running, all `game` commands work over HTTP (port 6009):
```bash
godot-dev game tree                          # full scene tree with class names + paths
godot-dev game tree --depth 2                # limit depth
godot-dev game tree --filter CharacterBody2D # show only nodes of a class
godot-dev game node /root/Level/Player       # all exported properties of one node
godot-dev game eval "get_tree().paused"      # any GDScript expression, runs in ReplBridge context
godot-dev game set /root/Level/Player speed 500  # set any exported property by node path
godot-dev game call /root/Level/Player perform_jump  # call any method
godot-dev game call /root/Level/Player move_toward '[100,200]'  # method with args (JSON array)
godot-dev game signal /root/Level/Player jump  # emit a signal
godot-dev game globals                       # list all autoloads (root children)
godot-dev game perf                          # fps, memory, draw calls, physics objects
godot-dev game fps                           # just fps
godot-dev game logs                          # buffered print() output from game
godot-dev game logs --follow                 # stream new logs every 500ms
godot-dev game errors                        # buffered push_error() output
godot-dev game groups                        # all groups and member node paths
godot-dev game watch "velocity"              # poll expression every 500ms (returns watch id)
godot-dev game watches                       # show all active watch values
godot-dev game pause                         # toggle get_tree().paused
godot-dev game reload                        # reload current scene
godot-dev game repl                          # interactive GDScript REPL (Ctrl+C to exit)
```

## Editor commands (port 6008, Godot editor must be open with GodotKitBridge plugin active)
```bash
godot-dev editor tree                        # scene tree of currently open scene
godot-dev editor selected                    # currently selected nodes
godot-dev editor select /root/Level/Player   # select node in editor
godot-dev editor files                       # all project files (res://)
godot-dev editor autoloads                   # project autoloads from project.godot
godot-dev editor plugins                     # active editor plugins
godot-dev editor open res://scenes/level.tscn # open a scene
godot-dev editor save                        # save current scene
godot-dev editor play                        # press Play in editor
godot-dev editor stop                        # press Stop in editor
godot-dev editor create /root/Level Node2D MyNode   # create node (parent, type, name)
godot-dev editor delete /root/Level/MyNode   # delete node
godot-dev editor property /root/Level/Player position '{"x":100,"y":200}'  # set property via UndoRedo
godot-dev editor signals /root/Level/Player  # list all signals on a node
godot-dev editor inspector                   # show selected node's exported properties
godot-dev editor run "EditorInterface.get_base_control().get_class()"  # run GDScript in editor
godot-dev editor import-status               # is editor currently scanning/importing?
godot-dev editor repl                        # interactive editor GDScript REPL
```

## Debugger (TCP port 6007, game must be launched with godot-dev launch)
```bash
godot-dev repl                               # interactive REPL via TCP debugger
godot-dev inspect                            # one-shot scene tree dump via TCP
godot-dev logs                               # stream all print() output in real time
godot-dev attach                             # auto-detect TCP or HTTP and start REPL
```

## Code quality
```bash
godot-dev lint                               # gdlint all .gd files
godot-dev lint scripts/player.gd            # lint specific file
godot-dev format                             # gdformat all .gd files
godot-dev format --check                     # check without writing
godot-dev validate                           # lint + Godot 3.x deprecated API check
```

## Scene and file management
```bash
godot-dev scene new res://scenes/enemy.tscn         # create blank .tscn (Node2D root)
godot-dev scene new res://scenes/ui.tscn Control    # create with specific root type
godot-dev input-map list                             # list all input actions in project.godot
godot-dev wait-import                                # wait for editor import to finish (30s timeout)
godot-dev wait-import --timeout 60000               # custom timeout
```

## Testing and export
```bash
godot-dev test scripts/test_math.gd          # run GDScript headlessly, exits 0=pass 1=fail
godot-dev export "Windows Desktop"           # export by preset name (needs export templates)
godot-dev export "Web" --output ./build/web
godot-dev dashboard                          # live terminal UI: scene tree + perf + logs
```

## Real-world nuances

### Port 6007 vs 6009
- **6007 (TCP debugger)**: available only when launched via `godot-dev launch`. Gives raw debugger access (logs, scene tree via protocol). Use `godot-dev repl/inspect/logs`.
- **6009 (HTTP game bridge)**: available when game is running AND ReplBridge autoload is active. More capable: eval, set, call, watch, groups, physics. Use all `game` commands.
- **6008 (HTTP editor bridge)**: available when Godot editor is open with GodotKitBridge plugin enabled. Use all `editor` commands.
- Both 6009 and 6007 can be active simultaneously. `game` commands always use 6009.

### After writing .gd files
- Godot hot-reloads scripts automatically when the editor is open.
- The running game does NOT auto-reload scripts — use `godot-dev game reload` to reload the scene, or `godot-dev watch` to auto-reload on every .gd save.
- If you add new files, the editor must import them first. Check: `godot-dev editor import-status`.

### Node paths
- All node paths start with `/root/`. Use `godot-dev game tree` to discover exact paths.
- The game's root scene node is typically `/root/Level` (from level.tscn).
- Player is at `/root/Level/Player` after spawning via game.gd.

### GDScript eval context
- `game eval` runs in the ReplBridge node's context (an autoload at `/root/ReplBridge`).
- Access the tree: `get_tree().root`, find nodes: `get_node("/root/Level/Player")`.
- Can call any autoload directly: `ReplBridge.log_info("test")`.
- Expressions only — no multi-line. For complex ops use `game call` or write a method.

### Signal connections
- Signals in .tscn files must be connected either in the scene file or via code.
- Area2D/CollisionShape2D bodies: connect `body_entered` signal. Spike/Collectible/Goal use this pattern.
- To connect at runtime: `game eval "get_node('/root/Level/Goal').body_entered.connect(Callable(get_node('/root/Level'), '_on_goal_body_entered'))"`

### Export
- Export presets are defined in `export_presets.cfg` (not gitignored by default — add if it has credentials).
- Export templates must be installed: `godot-dev download-export-templates`.
- Headless export: `godot-dev export "Linux/X11"` (preset name must match exactly).

### Input actions
- Default actions (ui_left, ui_right, ui_accept, ui_focus_next) are built into Godot.
- Custom actions go in `[input]` section of project.godot. Use `godot-dev input-map list` to verify.
- Player dash uses `ui_focus_next` (Tab key) — remap in project.godot for real controls.

### GDScript conventions (Godot 4.6)
- `CharacterBody2D` (not KinematicBody2D), `move_and_slide()` uses `velocity` property.
- `@export var speed := 300.0` — typed with default, visible in inspector.
- `await signal_name` (not yield). `signal_name.emit()` (not emit_signal).
- `FileAccess.open()` static (not `File.new()`). `DirAccess.open()` (not `Directory`).
- `Time.get_ticks_msec()` (not `OS.get_ticks_msec()`).
- `instantiate()` (not `instance()`). `is_empty()` (not `empty()`).
