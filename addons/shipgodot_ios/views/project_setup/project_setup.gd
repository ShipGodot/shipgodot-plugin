@tool
extends ShipGodotView

const SGModalData = preload("res://addons/shipgodot_ios/components/modal/sg_modal_data.gd")

var main_scene = preload("res://addons/shipgodot_ios/views/main/main.tscn")

@export var bundle_id_error : SGModalData
@export var settings_change_info : SGModalData

func _ready() -> void:
	%ContinueButton.pressed.connect(_on_continue)
	if not get_bundle_id().is_empty():
		%BundleID.text = get_bundle_id()
		_on_continue()


func _on_continue() -> void:
	var bundle_id : String = %BundleID.get_text()
	if bundle_id.length() == 0:
		request_modal.emit(bundle_id_error)
		return
	set_bundle_id(bundle_id)

	var changes = check_ios_settings()
	if changes:
		settings_change_info.content = "• " + "\n• ".join(changes)
		request_modal.emit(settings_change_info)
		await settings_change_info.wait_until_closed()
		check_ios_settings(true)
		settings_change_info.content = ""

	change_view.emit(main_scene)


func check_ios_settings(apply: bool = false) -> Array[String]:
	var changes: Array[String] = []

	var etc2_key := "rendering/textures/vram_compression/import_etc2_astc"
	# pre Godot 4.3 setting name.
	if not ProjectSettings.has_setting(etc2_key):
		etc2_key = "rendering/textures/vram_compression/import_etc2"

	if ProjectSettings.get_setting(etc2_key, false) != true:
		changes.append("Enable ETC2/ASTC VRAM compression")
		if apply:
			ProjectSettings.set_setting(etc2_key, true)

	var version := str(ProjectSettings.get_setting("application/config/version", "")).strip_edges()
	if version.is_empty():
		changes.append("Set project version to 1.0.0")
		if apply:
			ProjectSettings.set_setting("application/config/version", "1.0.0")

	var method := str(ProjectSettings.get_setting("rendering/renderer/rendering_method", ""))
	if method == "gl_compatibility":
		changes.append("Switch renderer from Compatibility to Mobile")
		if apply:
			ProjectSettings.set_setting("rendering/renderer/rendering_method", "mobile")

	var mobile_method := str(ProjectSettings.get_setting("rendering/renderer/rendering_method.mobile", ""))
	if mobile_method == "gl_compatibility":
		changes.append("Switch mobile renderer override to Mobile")
		if apply:
			ProjectSettings.set_setting("rendering/renderer/rendering_method.mobile", "mobile")

	if apply and not changes.is_empty():
		ProjectSettings.save()

	return changes
