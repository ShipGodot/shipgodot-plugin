@tool
class_name ShipGodotUtils

static func _get_engine_version() -> String:
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

static func get_bundle_id() -> String:
	return ProjectSettings.get_setting(ShipGodotPlugin.BUNDLE_ID_SETTING, "")


static func set_bundle_id(value: String) -> Error:
	ProjectSettings.set_setting(ShipGodotPlugin.BUNDLE_ID_SETTING, value)
	return ProjectSettings.save()
