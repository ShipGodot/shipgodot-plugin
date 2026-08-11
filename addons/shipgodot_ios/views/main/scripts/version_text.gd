@tool
extends RichTextLabel


func _ready() -> void:
	text = "v.%s alpha" % get_plugin_version()


func get_plugin_version() -> String:
	var cfg := ConfigFile.new()
	if cfg.load("res://addons/shipgodot_ios/plugin.cfg") != OK:
		return "?.?.?"
	return cfg.get_value("plugin", "version", "")
