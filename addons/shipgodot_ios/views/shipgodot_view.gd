class_name ShipGodotView
extends Control

const ShipGodotStore = preload("res://addons/shipgodot_ios/shipgodot_store.gd").ShipGodotStore

signal change_view(next: PackedScene)
signal request_modal(data: SGModalData)
signal processing(value : bool)


var api : ShipGodotClient
var store : ShipGodotStore


func _display_last_api_error() -> void:
	var error_modal = SGModalData.error_modal(api.get_last_error_formatted())
	request_modal.emit(error_modal)


func _paste_from_clipboard(where: LineEdit) -> void:
	var clipboard = DisplayServer.clipboard_get()
	if clipboard.length() > 0:
		where.text = clipboard
