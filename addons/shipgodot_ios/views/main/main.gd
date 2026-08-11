@tool
extends ShipGodotView

const BuildSlot = preload("res://addons/shipgodot_ios/client/models/build_slot.gd").BuildSlot
const BuildInfoContainer = preload("res://addons/shipgodot_ios/views/main/components/build_info_container/build_info_container.gd")

const ZIP_PATH := "user://project_upload.zip"

@export var build_component : PackedScene

var _default_excludes := [".godot", ".git", ".import"]
var _current_build_container : BuildInfoContainer


func _ready() -> void:
	update_session()
	%RunButton.pressed.connect(_create_new_build)


func update_session() -> void:
	var session := await api.get_session()
	if not session:
		_display_last_api_error()
		return
	%LicenseStatus.text = session.license_status
	%BuildMinutes.text = str(session.minutes_available)


func _create_new_build() -> void:
	processing.emit(true)

	var slot : BuildSlot = await api.request_build_slot()
	if not slot:
		processing.emit(false)
		_display_last_api_error()
		return

	%EmptyText.visible = false

	if _current_build_container:
		_current_build_container.finished.disconnect(update_session)

	_current_build_container = build_component.instantiate()
	_current_build_container.api = api
	_current_build_container.build_id = slot.build_id
	_current_build_container.version = str(ProjectSettings.get_setting("application/config/version", ""))
	_current_build_container.finished.connect(update_session)
	%BuildsContainer.add_child(_current_build_container)
	%BuildsContainer.move_child(_current_build_container, 0)

	if not await zip_and_upload_project(slot.upload_url):
		await _current_build_container.cancel_build()
		processing.emit(false)
		return

	if not await api.dispatch_build(slot.build_id, get_bundle_id(), _get_engine_version()):
		_display_last_api_error()
		await _current_build_container.cancel_build()
	processing.emit(false)



# TODO: Upload in parts
func zip_and_upload_project(presigned_url: String, excludes: Array = []) -> bool:
	if excludes.is_empty():
		excludes = _default_excludes

	# Gather every file under res://
	var files: Array[String] = []
	_collect_files("res://", files, excludes)
	if files.is_empty():
		push_error("No files found under res://")
		return false

	# Pack them into a zip in user://
	var packer := ZIPPacker.new()
	var open_err := packer.open(ZIP_PATH)
	if open_err != OK:
		push_error("Could not create zip: %s" % error_string(open_err))
		return false

	for f in files:
		packer.start_file(f.substr("res://".length()))   # relative path inside archive
		packer.write_file(FileAccess.get_file_as_bytes(f))
		packer.close_file()
	packer.close()

	if not await api.upload_project_zip(presigned_url, ZIP_PATH):
		_display_last_api_error()
		return false

	return true


func _collect_files(dir_path: String, out: Array, excludes: Array) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.include_hidden = true
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		var full := dir_path.path_join(name)
		var rel := full.substr("res://".length())
		var skip := false
		for ex in excludes:
			if rel == ex or rel.begins_with(ex + "/"):
				skip = true
				break
		if not skip:
			if dir.current_is_dir():
				_collect_files(full, out, excludes)
			else:
				out.append(full)
		name = dir.get_next()
	dir.list_dir_end()
