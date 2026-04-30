@tool
extends EditorPlugin

const AUTOLOAD_NAME := "MobileDebugger"
const AUTOLOAD_PATH := "res://addons/mobile_debugger/Debugger.tscn"


func _enable_plugin() -> void:
	# Add the Debugger scene as a project autoload
	if not ProjectSettings.has_setting("autoload/" + AUTOLOAD_NAME):
		add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)
		print("[MobileDebugger] Autoload '%s' added." % AUTOLOAD_NAME)
	else:
		print("[MobileDebugger] Autoload '%s' already exists, skipping." % AUTOLOAD_NAME)


func _disable_plugin() -> void:
	# Remove the autoload when the plugin is disabled
	if ProjectSettings.has_setting("autoload/" + AUTOLOAD_NAME):
		remove_autoload_singleton(AUTOLOAD_NAME)
		print("[MobileDebugger] Autoload '%s' removed." % AUTOLOAD_NAME)
