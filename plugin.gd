@tool
extends Control

var first_scene = preload("res://addons/shipgodot_ios/views/license_redeem/license_redeem.tscn")
var current : ShipGodotView


func _ready() -> void:
	_change_scene(first_scene)


func _change_scene(next : PackedScene) -> void:
	if current:
		_disconnect_signals()
		remove_child(current)
	current = next.instantiate()
	current.api = %ShipGodotClient
	_connect_signals()
	add_child(current)
	move_child(current, 0)


func _open_modal(data : SGModalData) -> void:
	%Modal.open(data)

func _set_processing(value : bool) -> void:
	%Processing.visible = value


func _connect_signals() -> void:
	current.change_view.connect(_change_scene)
	current.request_modal.connect(_open_modal)
	current.processing.connect(_set_processing)


func _disconnect_signals() -> void:
	current.change_view.disconnect(_change_scene)
	current.request_modal.disconnect(_open_modal)
	current.processing.disconnect(_set_processing)
