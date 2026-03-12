# Godot 4.x Development with godot-kit

This project uses the `godot-dev` CLI for agentic Godot development.

## Available Commands
- `godot-dev launch` — launch game with remote debugger (:6007)
- `godot-dev game tree` — inspect runtime scene tree (:6009)
- `godot-dev game eval "<expr>"` — evaluate GDScript at runtime
- `godot-dev editor tree` — inspect editor scene tree (:6008)
- `godot-dev editor save` — save current scene
- `godot-dev validate` — lint + Godot 3→4 migration check
- `godot-dev watch` — hot-reload .gd files on change
- `godot-dev test <script.gd>` — headless script test

## GDScript Conventions (Godot 4.6)
- Typed variables: `var speed: float = 300.0`
- Export: `@export var max_speed := 300.0`
- Signals: `signal jumped`, `jumped.emit()`
- `CharacterBody2D` (not KinematicBody2D)
- `move_and_slide()` uses `velocity` property
- `await` (not `yield`)
- `FileAccess.open()` (not `File.new()`)

## Godot Upgrade Skill: Manual Migration Guide (3.x to 4.6)

This document provides the explicit, manual find-and-replace instructions required to upgrade Godot projects from version 3.x through 4.6. Do not rely on automated tools; execute these exact changes in your script editor.

### Godot 3 to 4.0

#### Global & Core API
| Old Godot 3 API | New Godot 4 API |
| :--- | :--- |
| `instance()` | `instantiate()` |
| `File` / `Directory` | `FileAccess` / `DirAccess` (Use static methods, e.g., `FileAccess.open()`) |
| `OS` Screen/Window methods | `DisplayServer` (e.g., `DisplayServer.screen_get_size()`) |
| `OS` Time/Date methods | `Time` singleton (e.g., `Time.get_ticks_msec()`) |
| Virtual Methods | Add leading underscore (e.g., `AnimationNode.process()` ➔ `_process()`) |

#### Node Method Renames
| Class | Old Method | New Method |
| :--- | :--- | :--- |
| **AcceptDialog** | `set_autowrap()` | `set_autowrap_mode()` |
| **AnimationPlayer** | `add_animation()` | `add_animation_library()` |
| **AnimationTree** | `set_process_mode()` | `set_process_callback()` |
| **Array** | `empty()` | `is_empty()` |
| **Array** | `invert()` | `reverse()` |
| **Array** | `remove()` | `remove_at()` |
| **AStar2D / 3D** | `get_points()` | `get_points_id()` |
| **BaseButton** | `set_event()` | `set_shortcut()` |
| **Camera2D** | `get_h_offset()` | `get_drag_horizontal_offset()` |
| **Camera2D** | `get_v_offset()` | `get_drag_vertical_offset()` |
| **Camera2D** | `set_h_offset()` | `set_drag_horizontal_offset()` |
| **Camera2D** | `set_v_offset()` | `set_drag_vertical_offset()` |
| **CanvasItem** | `raise()` | `move_to_front()` |
| **CanvasItem** | `update()` | `queue_redraw()` |
| **Control** | `get_stylebox()` | `get_theme_stylebox()` |

#### Class & Resource Renames
| Old Godot 3 Name | New Godot 4 Name |
| :--- | :--- |
| `AnimatedSprite` | `AnimatedSprite2D` |
| `ARVR*` | `XR*` |
| `BoxShape` / `CapsuleShape` / `PlaneShape` | `BoxShape3D` / `CapsuleShape3D` / `WorldBoundaryShape3D` |
| `CubeMesh` | `BoxMesh` |
| `GIProbe` / `GIProbeData` | `VoxelGI` / `VoxelGIData` |
| `KinematicBody` / `KinematicBody2D` | `CharacterBody3D` / `CharacterBody2D` |
| `NavigationMeshInstance` | `NavigationRegion3D` |
| `NavigationPolygonInstance` | `NavigationRegion2D` |
| `PanoramaSky` | `Sky` |
| `Particles` / `Particles2D` | `GPUParticles3D` / `GPUParticles2D` |
| `ParticlesMaterial` | `ParticleProcessMaterial` |
| `Position2D` / `Position3D` | `Marker2D` / `Marker3D` |
| `Spatial` | `Node3D` |
| `SpatialMaterial` | `StandardMaterial3D` |
| `Sprite` | `Sprite2D` |
| `StreamTexture` | `CompressedTexture2D` |

### Godot 4.0 to 4.1
* **AnimationNode**: `_process()` and `blend_input()` add optional `test_only` parameter.
* **PathFollow2D**: `lookahead` property removed entirely.
* **NavigationAgent2D & 3D**: Replace `set_velocity()` with `velocity` property. Split `time_horizon` into `time_horizon_agents` and `time_horizon_obstacles`.
* **NavigationAgent3D**: Rename `agent_height_offset` to `path_height_offset`. Remove `ignore_y`.
* **AnimationTrackEditPlugin**: Class removed entirely.
* **EditorInterface**: Now inherits `Object`. Replace `set_movie_maker_enabled()` with `movie_maker_enabled` property.

### Godot 4.1 to 4.2
* **Node**: `NOTIFICATION_NODE_RECACHE_REQUESTED` removed.
* **GraphNode** now inherits `GraphElement` (not `Control`).
* **AnimationMixer** new base class — methods moved: `add_animation_library`, `advance`, `clear_caches`, `find_animation`, `get_animation`, `get_animation_list`, `has_animation`. Renamed: `method_call_mode` → `callback_mode_method`, `playback_active` → `active`.

### Godot 4.2 to 4.3
* **BoneAttachment3D**: Replace `on_bone_pose_update` with `on_skeleton_update`.
* **EditorSceneFormatImporterFBX** renamed to `EditorSceneFormatImporterFBX2GLTF`.
* **GDExtension**: `close_library`, `initialize_library`, `open_library` removed.
* **NavigationRegion2D**: `avoidance_layers` and `constrain_avoidance` removed.
* **Skeleton3D**: `add_bone` returns `int32`. Replace `bone_pose_changed` with `skeleton_updated`.
* **RenderingDevice**: `compute_list_begin` removed `allow_draw_overlap`. `draw_list_begin` removed `storage_textures`. Removed `post_barrier` from 8 methods.

### Godot 4.3 to 4.4
* **FileAccess**: `open_encrypted()` added optional `iv`. All 14 `store_*` methods return `bool`.
* **GraphEdit**: `connect_node()` added optional `keep_alive`.
* **RenderingDevice**: `draw_list_begin()` added optional `breadcrumb`.

### Godot 4.4 to 4.5
* **CanvasItem / Font**: Added optional `oversampling` to all draw methods.
* **Physics (Jolt 3D)**: `Area3D` and `StaticBody3D` overlaps reported by default.
* **RichTextLabel**: `add_image` adds `alt_text`, `width_in_percent`, `height_in_percent`.

### Godot 4.5 to 4.6
* **AnimationPlayer**: `assigned_animation`, `autoplay`, `current_animation` are now `StringName`.
* **Control**: `grab_focus()` added optional `hide_focus`.
* **EditorFileDialog**: `add_side_menu()` removed. 18 methods moved to base `FileDialog`.
* **Environment**: Default `glow_blend_mode` is 1, `glow_intensity` is 0.3.
* **FileAccess**: `create_temp()` mode flag is `FileAccess.ModeFlags`. `get_as_text()` removed `skip_cr`.
* **MeshInstance3D**: `skeleton` property default is `""`.

## Godot 4.6 GDScript Cheatsheet (Code Perspective)

### 1. Script Structure & Annotations
```gdscript
@icon("res://icon.svg")
@tool
class_name MyClass
extends Node2D

@export var health: int = 100
@onready var sprite = $Sprite2D
@rpc("any_peer") func sync_position(): pass
@warning_ignore("unused_variable")
```

Full Annotations:
- `@export` - Inspector editable: `@export var speed := 200`
- `@export_category` - Groups: `@export_category("Stats")`
- `@export_group` / `@export_subgroup` - Hierarchical: `@export_group("Movement")`
- `@export_range` - Slider: `@export_range(0, 100, 5) var damage`
- `@export_enum` / `@export_flags` - Dropdown: `@export_enum("Idle","Run") var state`
- `@export_file` / `@export_dir` - File picker: `@export_file("*.png") var texture_path`
- `@export_node_path` - NodePath: `@export_node_path("Sprite2D") var target`
- `@export_tool_button` - Inspector button: `@export_tool_button("Test") var btn = test_func`
- `@onready` - Before _ready(): `@onready var player = $Player`
- `@tool` - Runs in editor
- `@rpc` - Multiplayer: `@rpc("authority", "call_remote") func foo()`
- `@abstract` - Must subclass: `@abstract class Shape:`
- `@icon` - Scene icon: `@icon("res://icon.svg")`
- `@warning_ignore` - Suppress: `@warning_ignore("return_value_discarded")`

Initialization order: static defaults → variable initializers → _init() → exported values → @onready → _ready()

### 2. Variables, Types & Constants
```gdscript
var a = 5                     # Variant (dynamic)
var b: int = 10               # Typed
var c := Vector2(1, 2)        # Inferred
const MAX_HEALTH = 100
var arr: Array[int] = [1, 2, 3]
var dict: Dictionary[String, int]
var bytes := PackedByteArray([1, 2, 3])
```

### 3. Control Flow
```gdscript
match value:
    1, 2, 3: print("small")
    var x when x > 10: print("big")
    [1, ..]: print("starts with 1")
    {"health": var h}: print("health = ", h)
    _: print("default")

for i: int in range(10):
    pass
```

### 4. Functions & Classes
```gdscript
func shoot(damage: int = 10) -> void:
    pass

class Bullet:
    var speed := 300

func _init(p_name := "Player"):
    print("Created ", p_name)

func _ready():
    super()
```

### 5. Signals & await
```gdscript
signal health_changed(old: int, new: int)

func take_damage(amount):
    var old = health
    health -= amount
    health_changed.emit(old, health)

button.pressed.connect(_on_button_pressed)
health_changed.connect(_on_health_changed.bind("Player"))

func wait_for_input():
    await $Button.button_up
    return true
```

### 6. Node Lifecycle
Order: _enter_tree() → _ready() → _exit_tree()

- `_process(delta)` - every frame
- `_physics_process(delta)` - fixed physics tick
- `_input(event)` - all input
- `_unhandled_input(event)` - gameplay input
- `_draw()` - custom drawing
- `_get_configuration_warnings()` - editor warnings
- `_gui_input(event)` - Control UI

### 7. Physics / CharacterBody2D
```gdscript
func _physics_process(delta):
    if not is_on_floor():
        velocity.y += GRAVITY * delta
    velocity.x = Input.get_axis("move_left", "move_right") * SPEED
    move_and_slide()
```

### 8. Input
```gdscript
if Input.is_action_just_pressed("jump"):
    velocity.y = JUMP_FORCE
if Input.is_action_pressed("move_right"):
    velocity.x = SPEED
var dir := Input.get_vector("left", "right", "up", "down")
```

### 9. Scene Management
```gdscript
get_tree().change_scene_to_file("res://level2.tscn")
get_tree().change_scene_to_packed(preload("res://level2.tscn"))
get_tree().reload_current_scene()

var extra = preload("res://ui.tscn").instantiate()
get_tree().root.add_child(extra)
```

### 10. Node Shortcuts
```gdscript
var player = $Player
var enemy = %Enemy            # unique name
var sprite = get_node(^"../Sprite")
var scene = preload("res://enemy.tscn")
var texture = load("res://icon.png")
```

Quick Tips:
- Use typed variables for performance and warnings
- `await` replaced old `yield`
- Always multiply movement by `delta`
- Use `@onready` for node references
- `match` with patterns + guards is powerful

## Searching the Codebase
Use codebasesearch to find code semantically:
  npx codebasesearch "player jump logic"
  npx codebasesearch "collision detection"
  npx codebasesearch "scene transitions"
