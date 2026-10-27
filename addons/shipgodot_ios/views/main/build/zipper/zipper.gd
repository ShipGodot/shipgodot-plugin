class_name ShipGodotZipper
extends RefCounted

const ZIP_PATH := "user://project_upload.zip"
var _default_excludes : Array[String] = [".godot", ".git", ".import"]

signal failed(reason: String)
signal zip_finished(ok: bool)

func zip_dir_async(dir_path: String, excludes: Array[String] = []) -> void:
	WorkerThreadPool.add_task(zip_dir.bind(dir_path, excludes))

func _zip_task(paths: PackedStringArray, out_path: String) -> void:
	var zip := ZIPPacker.new()
	if zip.open(out_path) != OK:
		return
	for path in paths:
		var data := FileAccess.get_file_as_bytes(path)
		zip.start_file(path.get_file())
		zip.write_file(data)
		zip.close_file()
	zip.close()
	_done.call_deferred(true)


func zip_dir(dir_path: String, excludes: Array[String] = []) -> void:
	if excludes.is_empty():
		excludes = _default_excludes

	var files: Array[String] = []
	_collect_files(dir_path, files, excludes)
	if files.is_empty():
		_fail("No files found under %s" % dir_path)
		_done.call_deferred(false)
		return

	var packer := ZIPPacker.new()
	var open_err := packer.open(ZIP_PATH)
	if open_err != OK:
		_fail("Could not create zip: %s" % error_string(open_err))
		_done.call_deferred(false)
		return

	for f in files:
		packer.start_file(f.substr("res://".length()))
		packer.write_file(FileAccess.get_file_as_bytes(f))
		packer.close_file()
	packer.close()

	_done.call_deferred(true)


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


func _done(ok: bool) -> void:
	zip_finished.emit(ok)


func _fail(reason: String) -> void:
	failed.emit("Failed to pack project files: " % reason)
