@tool
extends Label

@export var setting_path : String


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and is_visible_in_tree():
		refresh()


func _ready() -> void:
	refresh()
	ProjectSettings.settings_changed.connect(refresh)


func refresh() -> void:
	var v := str(ProjectSettings.get_setting(setting_path, ""))
	text = v if not v.is_empty() else "not set"
