@tool
extends ShipGodotView


var warning_scene = preload("res://addons/shipgodot_ios/views/settings_change_alert/settings_change_alert.tscn")

func _ready() -> void:
	%ContinueButton.pressed.connect(_on_continue)


func _on_continue() -> void:
	change_view.emit(warning_scene)
