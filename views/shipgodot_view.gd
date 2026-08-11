class_name ShipGodotView
extends Control

const ShipGodotStore = preload("res://addons/shipgodot_ios/shipgodot_store.gd").ShipGodotStore

signal change_view(next: PackedScene)
signal request_modal(data: SGModalData)
signal processing(value : bool)


var api : ShipGodotClient
var store : ShipGodotStore


func _display_last_api_error() -> void:
	var error_modal = SGModalData.error_modal(api.get_last_error_formatted())
	request_modal.emit(error_modal)


func _paste_from_clipboard(where: LineEdit) -> void:
	var clipboard = DisplayServer.clipboard_get()
	if clipboard.length() > 0:
		where.text = clipboard


static func _get_engine_version() -> String:
	var info := Engine.get_version_info()
	var major: int = info["major"]
	var minor: int = info["minor"]
	var patch: int = info["patch"]
	var status: String = info["status"]

	if patch > 0:
		#return "%d.%d.%d-%s" % [major, minor, patch, status]
		return "%d.%d.%d" % [major, minor, patch]

	#return "%d.%d-%s" % [major, minor, status]
	return "%d.%d" % [major, minor]

static func get_bundle_id() -> String:
	return ProjectSettings.get_setting(ShipGodotPlugin.BUNDLE_ID_SETTING, "")


static func set_bundle_id(value: String) -> Error:
	ProjectSettings.set_setting(ShipGodotPlugin.BUNDLE_ID_SETTING, value)
	return ProjectSettings.save()
