@tool
extends ShipGodotView

const AppleApiKey = preload("res://addons/shipgodot_ios/client/models/apple_api_key.gd").AppleApiKey
const ActivateResponse = preload("res://addons/shipgodot_ios/client/models/activate_response.gd").ActivateResponse


var bundle_id_scene = preload("res://addons/shipgodot_ios/views/project_setup/project_setup.tscn")

var apple_team_id : String = ""
var apple_key : AppleApiKey

func _ready() -> void:
	apple_key = AppleApiKey.new()
	%P8APIKeyButton.pressed.connect(_on_load_key_button_pressed)
	%ContinueButton.pressed.connect(_on_continue)

func _on_load_key_button_pressed() -> void:
	var dialog := FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.use_native_dialog = true
	dialog.add_filter("*.p8", "App Store Connect API Key")

	dialog.file_selected.connect(_on_key_file_selected)
	dialog.close_requested.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)

	add_child(dialog)
	dialog.popup_centered(Vector2i(800, 600))

func _on_key_file_selected(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Could not open %s: %s" % [path, error_string(FileAccess.get_open_error())])
		return
	apple_key.p8 = file.get_as_text()

func _on_continue() -> void:
	apple_team_id = %TeamID.get_text()
	apple_key.key_id = %KeyID.get_text()
	apple_key.issuer_id = %IssuerID.get_text()
	# TODO: Uncomment when ready to test API
	# var act := await api.activate(api.license_key, "demo_device", "demo_instance", apple_team_id, apple_key)
	# if act:
	# 	api.seat_token = act.seat_token
	change_view.emit(bundle_id_scene)
