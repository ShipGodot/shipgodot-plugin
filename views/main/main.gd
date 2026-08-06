@tool
extends ShipGodotView

const BuildSlot = preload("res://addons/shipgodot_ios/client/models/build_slot.gd").BuildSlot

const ZIP_PATH := "user://project_upload.zip"

@export var build_component : PackedScene

var _default_excludes := [".godot", ".git", ".import"]


func _ready() -> void:
	%RunButton.pressed.connect(_create_new_build)


func _get_engine_version() -> String:
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

func _create_new_build() -> void:
	var slot : BuildSlot = await api.request_build_slot()
	var build = build_component.instantiate()
	build.api = api
	build.build_id = slot.build_id
	if %EmptyText:
		%EmptyText.queue_free()
	%BuildsContainer.add_child(build)
	await zip_and_upload_project(slot.upload_url)
	api.dispatch_build(slot.build_id, get_bundle_id(), _get_engine_version())


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

	# Upload the zip file
	return await api.upload_project_zip(presigned_url, ZIP_PATH)


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
