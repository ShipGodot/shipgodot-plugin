@tool
extends ShipGodotView

const AppleApiKey = preload("res://addons/shipgodot_ios/client/models/apple_api_key.gd").AppleApiKey
const ActivateResponse = preload("res://addons/shipgodot_ios/client/models/activate_response.gd").ActivateResponse
const SGModalData = preload("res://addons/shipgodot_ios/components/modal/sg_modal_data.gd")


var project_setup_scene = preload("res://addons/shipgodot_ios/views/project_setup/project_setup.tscn")

var apple_team_id : String = ""
var apple_key : AppleApiKey
var dialog : FileDialog

@export var security_info : SGModalData

@export_multiline var malformed_team_id_message : String = ""
@export_multiline var malformed_key_id_message : String = ""
@export_multiline var malformed_issuer_id_message : String = ""
@export_multiline var malformed_p8_key_message : String = ""


var _team_id_regex := RegEx.create_from_string("^[A-Z0-9]{10}$")


func _ready() -> void:
	apple_key = AppleApiKey.new()
	%PasteTeamIDButton.pressed.connect(_paste_from_clipboard.bind(%TeamID))
	%PasteKeyIDButton.pressed.connect(_paste_from_clipboard.bind(%KeyID))
	%PasteIssuerIDButton.pressed.connect(_paste_from_clipboard.bind(%IssuerID))
	
	%P8APIKeyButton.pressed.connect(_on_load_key_button_pressed)
	%ContinueButton.pressed.connect(_on_continue)
	request_modal.emit(security_info)


func _on_load_key_button_pressed() -> void:
	dialog = FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.use_native_dialog = true
	dialog.add_filter("*.p8, *.p8.txt", "App Store Connect API Key")

	dialog.file_selected.connect(_on_key_file_selected)
	dialog.close_requested.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)

	add_child(dialog)
	dialog.popup_centered(Vector2i(800, 600))


func _on_key_file_selected(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		var error_msg := "Could not open %s: %s" % [path, error_string(FileAccess.get_open_error())]
		dialog.queue_free()
		var error_modal = SGModalData.error_modal(error_msg)
		request_modal.emit(error_modal)
		return
	apple_key.p8 = file.get_as_text()
	dialog.queue_free()


func _on_continue() -> void:
	apple_team_id = %TeamID.get_text().strip_edges()
	apple_key.key_id = %KeyID.get_text().strip_edges()
	apple_key.issuer_id = %IssuerID.get_text().strip_edges()

	if not _check_credentials():
		return

	processing.emit(true)
	var act := await api.activate(api.license_key, store.get_device_id(), store.get_device_name(), apple_team_id, apple_key)
	processing.emit(false)

	if not act:
		var error_modal = SGModalData.error_modal(api.get_last_error_formatted())
		request_modal.emit(error_modal)
		return

	api.seat_token = act.seat_token
	store.set_seat_token(act.seat_token)
	change_view.emit(project_setup_scene)


# TODO: add subtler indicators that there's an error
func _check_credentials() -> bool:
	if _team_id_regex.search(apple_team_id) == null:
		var error_modal = SGModalData.error_modal(malformed_team_id_message)
		request_modal.emit(error_modal)
		return false

	if not apple_key.validate_key_id():
		var error_modal = SGModalData.error_modal(malformed_key_id_message)
		request_modal.emit(error_modal)
		return false

	if not apple_key.validate_issuer_id():
		var error_modal = SGModalData.error_modal(malformed_issuer_id_message)
		request_modal.emit(error_modal)
		return false

	if not apple_key.validate_p8():
		var error_modal = SGModalData.error_modal(malformed_p8_key_message)
		request_modal.emit(error_modal)
		return false

	return true
