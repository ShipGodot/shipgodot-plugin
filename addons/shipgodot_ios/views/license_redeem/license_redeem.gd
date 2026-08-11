@tool
extends ShipGodotView

@export_multiline var malformed_license_message : String = ""
@export_multiline var empty_dev_name_message : String = ""

var _apple_cred_scene = preload("res://addons/shipgodot_ios/views/apple_credentials/apple_credentials.tscn")
var _project_setup_scene = preload("res://addons/shipgodot_ios/views/project_setup/project_setup.tscn")
var _UUID_regex := RegEx.create_from_string(
	"^(?i)[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"
)

func _ready() -> void:
	%PasteLicenseButton.pressed.connect(_paste_from_clipboard.bind(%LicenseKeyInput))
	%ContinueButton.pressed.connect(_on_continue)


func _on_continue() -> void:
	var license : String = %LicenseKeyInput.get_text().strip_edges()
	var dev_name : String = %DeviceIDInput.get_text().strip_edges()

	if not _check_prompts(license, dev_name):
		return

	api.license_key = license
	store.set_device_name(dev_name)
	processing.emit(true)
	var act = await api.activate(api.license_key, store.get_device_name(), store.get_device_id())
	processing.emit(false)
	if not act:
		# First redemption without Apple credentials
		if api.last_error.code == "apple_credentials_required":
			change_view.emit(_apple_cred_scene)
		var error_modal = SGModalData.error_modal(api.get_last_error_formatted())
		request_modal.emit(error_modal)
		return

	api.seat_token = act.seat_token
	store.set_seat_token(act.seat_token)
	change_view.emit(_project_setup_scene)


# TODO: add subtler indicators that there's an error
func _check_prompts(license : String, dev_name : String) -> bool:
	if _UUID_regex.search(license) == null:
		var error_modal = SGModalData.error_modal(malformed_license_message)
		request_modal.emit(error_modal)
		return false

	if dev_name.is_empty():
		var error_modal = SGModalData.error_modal(empty_dev_name_message)
		request_modal.emit(error_modal)
		return false

	return true
