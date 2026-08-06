class_name ShipGodotView
extends Control

signal change_view(next: PackedScene)

signal request_modal(data: SGModalData)
signal processing(value : bool)


var api : ShipGodotClient

func _paste_from_clipboard(where: LineEdit) -> void:
	var clipboard = DisplayServer.clipboard_get()
	if clipboard.length() > 0:
		where.text = clipboard

static func get_bundle_id() -> String:
	return ProjectSettings.get_setting(ShipGodotPlugin.BUNDLE_ID_SETTING, "")

static func set_bundle_id(value: String) -> Error:
	ProjectSettings.set_setting(ShipGodotPlugin.BUNDLE_ID_SETTING, value)
	return ProjectSettings.save()
