@tool
extends ShipGodotView


var main_scene = preload("res://addons/shipgodot_ios/views/main/main.tscn")

func _ready() -> void:
	%ContinueButton.pressed.connect(_on_continue)


func _on_continue() -> void:
	change_view.emit(main_scene)
