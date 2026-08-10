@tool
class_name ShipGodotPlugin
extends Control

const BUNDLE_ID_SETTING := "shipgodot/ios/bundle_id"
const SessionInfo = preload("res://addons/shipgodot_ios/client/models/session_info.gd").SessionInfo
const ShipGodotStore := preload("res://addons/shipgodot_ios/shipgodot_store.gd").ShipGodotStore

var _license_redeem_view := preload("res://addons/shipgodot_ios/views/license_redeem/license_redeem.tscn")
var _project_setup_view := preload("res://addons/shipgodot_ios/views/project_setup/project_setup.tscn")
var _store : ShipGodotStore = ShipGodotStore.new()
var _start_view : PackedScene
var _session_info : SessionInfo

var current : ShipGodotView


func _enter_tree() -> void:
	register_project_settings()


func _ready() -> void:
	_start_view = _license_redeem_view
	await _get_session_info()
	if _session_info:
		_start_view = _project_setup_view
	_change_scene(_start_view)


func _change_scene(next : PackedScene) -> void:
	if current:
		_disconnect_signals()
		remove_child(current)
	current = next.instantiate()
	current.api = %ShipGodotClient
	current.store = _store
	_connect_signals()
	add_child(current)
	move_child(current, 0)


func _connect_signals() -> void:
	current.change_view.connect(_change_scene)
	current.request_modal.connect(_open_modal)
	current.processing.connect(_set_processing)


func _disconnect_signals() -> void:
	current.change_view.disconnect(_change_scene)
	current.request_modal.disconnect(_open_modal)
	current.processing.disconnect(_set_processing)


func _get_session_info() -> void:
	if not _store.has_seat_token():
		print("no token!")
		return

	%ShipGodotClient.seat_token = _store.get_seat_token()
	_session_info = await %ShipGodotClient.get_session()
	if not _session_info:
		# TODO: open modal invalid session token info
		%ShipGodotClient.seat_token = ""
		_store.clear_credentials()


func _open_modal(data : SGModalData) -> void:
	%Modal.open(data)


func _set_processing(value : bool) -> void:
	%Processing.visible = value


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
