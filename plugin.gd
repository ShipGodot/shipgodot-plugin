@tool
class_name ShipGodotPlugin
extends Control

const BUNDLE_ID_SETTING := "shipgodot/ios/bundle_id"

var first_scene = preload("res://addons/shipgodot_ios/views/license_redeem/license_redeem.tscn")
var current : ShipGodotView

func _enter_tree() -> void:
	register_project_settings()


func _ready() -> void:
	_change_scene(first_scene)


func _change_scene(next : PackedScene) -> void:
	if current:
		_disconnect_signals()
		remove_child(current)
	current = next.instantiate()
	current.api = %ShipGodotClient
	_connect_signals()
	add_child(current)
	move_child(current, 0)


func _open_modal(data : SGModalData) -> void:
	%Modal.open(data)

func _set_processing(value : bool) -> void:
	%Processing.visible = value


func _connect_signals() -> void:
	current.change_view.connect(_change_scene)
	current.request_modal.connect(_open_modal)
	current.processing.connect(_set_processing)


func _disconnect_signals() -> void:
	current.change_view.disconnect(_change_scene)
	current.request_modal.disconnect(_open_modal)
	current.processing.disconnect(_set_processing)


static func register_project_settings() -> void:
	if not ProjectSettings.has_setting(BUNDLE_ID_SETTING):
		ProjectSettings.set_setting(BUNDLE_ID_SETTING, "")
	ProjectSettings.set_initial_value(BUNDLE_ID_SETTING, "")
	ProjectSettings.add_property_info({
		"name": BUNDLE_ID_SETTING,
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_PLACEHOLDER_TEXT,
		"hint_string": "com.studio.mygame",
	})
	ProjectSettings.set_as_basic(BUNDLE_ID_SETTING, true)
