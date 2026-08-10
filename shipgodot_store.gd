# Device-scoped: seat token + device id.
# Lives in the OS user config dir so it is shared by every Godot project on
# this machine, and is never inside res:// or user://
#
#
#   Linux   ~/.config/ShipGodot/credentials.cfg
#   Windows %APPDATA%\ShipGodot\credentials.cfg
#   macOS   ~/Library/Application Support/ShipGodot/credentials.cfg
#   iOS   ??? -> TODO: Check in Xogot where's the config_dir
class ShipGodotStore:
	extends RefCounted

	const DIR_NAME := "ShipGodot"
	const FILE_NAME := "credentials.cfg"
	const SECTION := "auth"
	const PERMISSION_FLAGS := FileAccess.UNIX_READ_OWNER | FileAccess.UNIX_WRITE_OWNER

	var cfg : ConfigFile:
		get:
			if not cfg:
				cfg = ConfigFile.new()
				cfg.load(_path())
			return cfg


	func _dir() -> String:
		return OS.get_config_dir().path_join(DIR_NAME)


	func _path() -> String:
		return _dir().path_join(FILE_NAME)


	func _save() -> Error:
		DirAccess.make_dir_recursive_absolute(_dir())
		var err := cfg.save(_path())
		if err == OK:
			FileAccess.set_unix_permissions(_path(), PERMISSION_FLAGS)
		return err


	func get_seat_token() -> String:
		return cfg.get_value(SECTION, "seat_token", "")


	func has_seat_token() -> bool:
		return not get_seat_token().is_empty()


	func set_seat_token(token: String) -> Error:
		cfg.set_value(SECTION, "seat_token", token)
		return _save()


	func get_device_id() -> String:
		# Minted once, then persisted. Sent to /v1/activate.
		var id: String = cfg.get_value(SECTION, "device_id", "")
		if id.is_empty():
			id = _uuid_v4()
			cfg.set_value(SECTION, "device_id", id)
			_save()
		return id


	func set_device_name(name: String) -> Error:
		cfg.set_value(SECTION, "device_name", name)
		return _save()


	func get_device_name() -> String:
		var id: String = cfg.get_value(SECTION, "device_name", "")
		return id


	func clear_credentials() -> void:
		# Call after /v1/deactivate, or on 401 from /v1/me.
		# Keep device_id so the same machine reactivates into the same activation.
		cfg.set_value(SECTION, "seat_token", "")
		_save()


	func _uuid_v4() -> String:
		var b := PackedByteArray()
		b.resize(16)
		for i in 16:
			b[i] = randi() % 256
		b[6] = (b[6] & 0x0f) | 0x40
		b[8] = (b[8] & 0x3f) | 0x80
		var h := b.hex_encode()
		return "%s-%s-%s-%s-%s" % [h.substr(0, 8), h.substr(8, 4), h.substr(12, 4), h.substr(16, 4), h.substr(20, 12)]
