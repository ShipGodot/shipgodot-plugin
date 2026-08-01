@tool
extends Control

var current : SGModalData


func _ready() -> void:
	%Button.pressed.connect(close)
	_set_panel_visibility(false)


func _set_panel_visibility(value : bool) -> void:
	print("setting panel to")
	print(value)
	%Panel.visible = value


func open(data : SGModalData) -> void:
	print("opening the panel!")
	current = data
	%Pictogram.texture = data.icon
	%Pictogram.self_modulate = data.icon_tint
	%Title.text = data.title
	%TextContent.text = data.content
	%Button.text = data.button_text
	%AnimationPlayer.play("modal_in")
	call_deferred("_set_panel_visibility", true)


func close() -> void:
	%AnimationPlayer.play("modal_out")


func closed() -> void:
	current.modal_closed.emit()
