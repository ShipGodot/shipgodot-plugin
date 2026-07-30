class_name ShipGodotView
extends Control

signal change_view(next: PackedScene)

var api : ShipGodotClient

func _paste_from_clipboard(where: LineEdit) -> void:
	var clipboard = DisplayServer.clipboard_get()
	if clipboard.length() > 0:
		where.text = clipboard
