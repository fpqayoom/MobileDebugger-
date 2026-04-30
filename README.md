# Mobile Debugger - Xogot Plugin

---

## Installation

1. Copy the `addons/mobile_debugger/` folder into your project's `res://addons/` directory.
2. Open Godot → **Project → Project Settings → Plugins**.
3. Find **"Mobile Debugger"** and set it to **Enabled**.
4. The plugin automatically adds `MobileDebugger` as a project Autoload.
5. Run your game — a **"🐛 DEBUG"** button appears in the top-left corner.

---

## Public API

```gdscript
# Log a message to the console
MobileDebugger.log("Player spawned at " + str(position))
MobileDebugger.log("Low health!", "warning")
MobileDebugger.log("Crash detected", "error")

# Pin a live variable to the Watch panel (updates every frame)
func _process(delta):
    MobileDebugger.watch("player_pos", position)
    MobileDebugger.watch("velocity", velocity)
    MobileDebugger.watch("hp", health)

# Show/hide the debugger window
MobileDebugger.toggle()

# Listen for custom commands typed into the console
func _ready():
    MobileDebugger.custom_command_fired.connect(_on_debug_cmd)

func _on_debug_cmd(cmd: String, args: Array) -> void:
    match cmd:
        "godmode":
            is_invincible = true
            MobileDebugger.log("God mode ON", "system")
        "tp":
            # args[0] = x, args[1] = y
            if args.size() >= 2:
                position = Vector2(float(args[0]), float(args[1]))
```
