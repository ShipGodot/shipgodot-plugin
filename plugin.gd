@tool
extends Control

var first_scene = preload("res://addons/shipgodot_ios/views/license_redeem/license_redeem.tscn")
var current : ShipGodotView

func _ready() -> void:
	change_scene(first_scene)


func change_scene(next : PackedScene) -> void:
	if current:
		remove_child(current)
	current = next.instantiate()
	current.api = %ShipGodotClient
	current.change_view.connect(change_scene)
	add_child(current)
