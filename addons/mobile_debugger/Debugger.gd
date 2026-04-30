extends CanvasLayer

#Public
#   MobileDebugger.print_console(message)       -> Add line to console
#   MobileDebugger.print_console(message, "warning")
#   MobileDebugger.print_console(message, "error")
#   MobileDebugger.watch(key, value)                -> Pin a live variable
#   MobileDebugger.toggle()                         -> Show/hide window
#
#Global Signal
#   MobileDebugger.custom_command_fired(cmd: String, args: Array)


signal custom_command_fired(cmd: String, args: Array)

@onready var _window: Panel              = $DebugWindow
@onready var _title_bar: Panel           = $DebugWindow/VBox/TitleBar
@onready var _close_btn: Button          = $DebugWindow/VBox/TitleBar/HBox/CloseBtn
@onready var _resize_handle: Control     = $DebugWindow/VBox/TitleBar/HBox/ResizeBtn
@onready var _watch_label: RichTextLabel = $DebugWindow/VBox/WatchPanel/WatchLabel
@onready var _stats_label: Label         = $DebugWindow/VBox/StatsBar/StatsLabel
@onready var _log_scroll: ScrollContainer = $DebugWindow/VBox/LogScroll
@onready var _log_label: RichTextLabel   = $DebugWindow/VBox/LogScroll/LogLabel
@onready var _cmd_input: LineEdit        = $DebugWindow/VBox/InputRow/CmdInput
@onready var _send_btn: Button           = $DebugWindow/VBox/InputRow/SendBtn
@onready var _pause_btn: Button          = $DebugWindow/VBox/ToolsRow1/PauseBtn
@onready var _restart_btn: Button        = $DebugWindow/VBox/ToolsRow1/RestartBtn
@onready var _hitbox_btn: Button         = $DebugWindow/VBox/ToolsRow1/HitboxBtn
@onready var _clear_btn: Button          = $DebugWindow/VBox/ToolsRow1/ClearBtn
@onready var _copy_btn: Button           = $DebugWindow/VBox/ToolsRow1/CopyBtn
@onready var _speed_slider: HSlider      = $DebugWindow/VBox/ToolsRow2/SpeedSlider
@onready var _speed_label: Label         = $DebugWindow/VBox/ToolsRow2/SpeedLabel
@onready var _toggle_btn: Button         = $ToggleButton



var _resizing_active: bool = false
var _is_visible: bool = false
var _drag_active: bool = false
var _drag_offset: Vector2 = Vector2.ZERO
var _watch_data: Dictionary = {}
var _hitboxes_visible: bool = true
var _log_lines: PackedStringArray = []
const MAX_LOG_LINES: int = 200

const COLOR_DEFAULT := "[color=#e0e0e0]"
const COLOR_WARNING := "[color=#ffcc00]"
const COLOR_ERROR   := "[color=#ff5555]"
const COLOR_SYSTEM  := "[color=#88ccff]"
const COLOR_END     := "[/color]"


func _ready() -> void:
	layer = 128
	_close_btn.pressed.connect(_on_close_pressed)
	_resize_handle.gui_input.connect(_on_resize_handle_input)
	_send_btn.pressed.connect(_on_send_pressed)
	_cmd_input.text_submitted.connect(_on_cmd_submitted)
	_pause_btn.pressed.connect(_on_pause_pressed)
	_restart_btn.pressed.connect(_on_restart_pressed)
	_hitbox_btn.pressed.connect(_on_hitbox_pressed)
	_clear_btn.pressed.connect(_on_clear_log_pressed)
	_copy_btn.pressed.connect(_on_copy_log_pressed)
	_speed_slider.value_changed.connect(_on_speed_changed)
	_toggle_btn.pressed.connect(toggle)
	_title_bar.gui_input.connect(_on_title_bar_input)
	_window.visible = false
	_speed_slider.value = 1.0
	_speed_label.text = "Speed: 1.00x"
	_size_window_to_screen()
	_print_system("Mobile Debugger XoGot")
	_print_system("Type 'help' for built-in commands.")

func _process(_delta: float) -> void:
	if not _is_visible:
		return
	_update_stats()
	_update_watch_display()


# PUBLIC API
func print_console(message: String, level: String = "default") -> void:
	var color: String
	match level:
		"warning": color = COLOR_WARNING
		"error":   color = COLOR_ERROR
		"system":  color = COLOR_SYSTEM
		_:         color = COLOR_DEFAULT
	var line := color + str(message) + COLOR_END
	_log_lines.append(line)
	if _log_lines.size() > MAX_LOG_LINES:
		_log_lines.remove_at(0)
	_rebuild_log()


func watch(key: String, value: Variant) -> void:
	_watch_data[key] = value


func toggle() -> void:
	_is_visible = !_is_visible
	_window.visible = _is_visible
	if _is_visible:
		_size_window_to_screen()


# INTERNAL
func _update_stats() -> void:
	var fps    := Engine.get_frames_per_second()
	var ram_mb := float(OS.get_static_memory_usage()) / 1_048_576.0
	var obj_ct := Performance.get_monitor(Performance.OBJECT_COUNT)
	_stats_label.text = "FPS: %d  |  RAM: %.1f MB  |  Objects: %d" % [fps, ram_mb, int(obj_ct)]


func _update_watch_display() -> void:
	if _watch_data.is_empty():
		_watch_label.text = "[color=#888888]No variables watched.[/color]"
		return
	var text := ""
	for key in _watch_data:
		text += "[color=#88ccff]%s[/color] = [color=#ffdd88]%s[/color]\n" % [key, str(_watch_data[key])]
	_watch_label.text = text.strip_edges()


func _rebuild_log() -> void:
	_log_label.text = "\n".join(_log_lines)
	_scroll_to_bottom_auto()

func _scroll_to_bottom_auto() -> void:
	await get_tree().process_frame
	var v_bar := _log_scroll.get_v_scroll_bar()
	v_bar.value = v_bar.max_value
	
	var h_bar := _log_scroll.get_h_scroll_bar()
	h_bar.value = 0 



func _scroll_log_to_bottom() -> void:
	_log_scroll.scroll_vertical = _log_scroll.get_v_scroll_bar().max_value


func _print_system(msg: String) -> void:
	print_console(msg, "system")


func _size_window_to_screen() -> void:
	var screen_size := get_viewport().get_visible_rect().size
	_window.size     = screen_size * 0.6
	_window.position = screen_size * 0.09


func _on_title_bar_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_drag_active = true
			get_viewport().set_input_as_handled()
		else:
			_drag_active = false
			
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_drag_active = event.pressed
			get_viewport().set_input_as_handled()

	elif _drag_active:
		if event is InputEventScreenDrag or event is InputEventMouseMotion:
			_window.position += event.relative
			_clamp_window_to_screen()
			get_viewport().set_input_as_handled()



func _clamp_window_to_screen() -> void:
	var screen_size := get_viewport().get_visible_rect().size
	_window.position.x = clamp(_window.position.x, 0.0, screen_size.x - _window.size.x)
	_window.position.y = clamp(_window.position.y, 0.0, screen_size.y - _window.size.y)


func _on_close_pressed() -> void:
	toggle()


func _on_pause_pressed() -> void:
	get_tree().paused = !get_tree().paused
	_pause_btn.text = "Resume" if get_tree().paused else "Pause"
	_print_system("Game " + ("PAUSED" if get_tree().paused else "RESUMED"))


func _on_restart_pressed() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	_speed_slider.value = 1.0
	_print_system("Restarting scene...")
	get_tree().reload_current_scene()


func _on_hitbox_pressed() -> void:
	_hitboxes_visible = !_hitboxes_visible
	_toggle_collision_shapes(get_tree().root, _hitboxes_visible)
	_hitbox_btn.text = "Hide Hitboxes" if _hitboxes_visible else "Show Hitboxes"
	_print_system("Hitboxes " + ("visible" if _hitboxes_visible else "hidden"))


func _toggle_collision_shapes(node: Node, visible_state: bool) -> void:
	for child in node.get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			child.visible = visible_state
		_toggle_collision_shapes(child, visible_state)

func _on_clear_log_pressed() -> void:
	_log_lines.clear()
	_rebuild_log()
	_print_system("Log cleared.")

func _on_copy_log_pressed() -> void:
	var full_text = _log_label.get_parsed_text()
	DisplayServer.clipboard_set(full_text)
	_print_system("Log copied to clipboard!")


func _on_speed_changed(value: float) -> void:
	Engine.time_scale = value
	_speed_label.text = "Speed: %.2fx" % value


func _on_send_pressed() -> void:
	_process_command(_cmd_input.text)


func _on_cmd_submitted(text: String) -> void:
	_process_command(text)


func _process_command(raw: String) -> void:
	var trimmed := raw.strip_edges()
	if trimmed.is_empty():
		return
	print_console("> " + trimmed)
	_cmd_input.text = ""
	var parts := trimmed.split(" ", false)
	var cmd   := parts[0].to_lower()
	var args  := parts.slice(1)

	match cmd:
		"help":
			_print_system("Built-in commands:")
			_print_system("  help           - show this help")
			_print_system("  clear          - clear the log")
			_print_system("  fps            - print current FPS")
			_print_system("  pause          - toggle pause")
			_print_system("  restart        - reload current scene")
			_print_system("  timescale <n>  - set Engine.time_scale (0.0-2.0)")
			_print_system("  hitboxes       - toggle collision shapes")
			_print_system("  unwatch <key>  - stop watching a variable")
			_print_system("  clearwatch     - clear all watched variables")
			_print_system("  <anything>     - fires custom_command_fired signal")
			return
		"clear":
			_log_lines.clear()
			_rebuild_log()
			return
		"fps":
			_print_system("FPS: %d" % Engine.get_frames_per_second())
			return
		"pause":
			_on_pause_pressed()
			return
		"restart":
			_on_restart_pressed()
			return
		"timescale":
			if args.size() == 0:
				print_console("Usage: timescale <value>", "warning")
				return
			var val := clamp(float(args[0]), 0.0, 2.0)
			Engine.time_scale = val
			_speed_slider.value = val
			_print_system("time_scale set to %.2f" % val)
			return
		"hitboxes":
			_on_hitbox_pressed()
			return
		"unwatch":
			if args.size() > 0 and _watch_data.has(args[0]):
				_watch_data.erase(args[0])
				_print_system("Unwatched: " + args[0])
			return
		"clearwatch":
			_watch_data.clear()
			_print_system("Watch list cleared.")
			return

	custom_command_fired.emit(cmd, args)
	_print_system("Command forwarded: '%s' args=%s" % [cmd, str(args)])
	
	
	
func _on_resize_handle_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_resizing_active = true
		else:
			_resizing_active = false
	
	elif event is InputEventScreenDrag and _resizing_active:
		var new_size = _window.size + event.relative
		
		new_size.x = clamp(new_size.x, 300, get_viewport().get_visible_rect().size.x)
		new_size.y = clamp(new_size.y, 400, get_viewport().get_visible_rect().size.y)
		
		_window.size = new_size

	# Desktop
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_resizing_active = event.pressed
	
	elif event is InputEventMouseMotion and _resizing_active:
		var new_size = _window.size + event.relative
		new_size.x = clamp(new_size.x, 300, get_viewport().get_visible_rect().size.x)
		new_size.y = clamp(new_size.y, 400, get_viewport().get_visible_rect().size.y)
		_window.size = new_size

