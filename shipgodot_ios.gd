@tool
extends EditorPlugin

var dock : EditorDock

func _enable_plugin() -> void:
	pass


func _disable_plugin() -> void:
	pass


func _enter_tree() -> void:
	# Load the dock scene and instantiate it.
	var dock_scene = preload("res://addons/shipgodot_ios/plugin.tscn").instantiate()

	# Create the dock and add the loaded scene to it.
	dock = EditorDock.new()
	dock.add_child(dock_scene)

	dock.title = "ShipGodot"

	dock.default_slot = EditorDock.DOCK_SLOT_BOTTOM

	dock.available_layouts = EditorDock.DOCK_LAYOUT_HORIZONTAL | EditorDock.DOCK_LAYOUT_FLOATING

	add_dock(dock)


func _exit_tree() -> void:
	remove_dock(dock)
