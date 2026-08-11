@tool
class_name SGModalData
extends Resource

enum Type { INFO, WARNING, ERROR }

@export var type : Type = Type.INFO
@export var icon : Texture2D
@export var icon_tint : Color = Color("#7e7bff2d")
@export var title : String
@export_multiline var content : String
@export var button_text : String


func wait_until_closed() -> void:
	await changed


func close() -> void:
	emit_changed()


static func error_modal(content : String = "Something went wrong.", title : String = "Error", button_text : String = "OK") -> SGModalData:
	var modal := SGModalData.new()
	modal.type = Type.ERROR
	modal.icon = load("res://addons/shipgodot_ios/components/modal/icons/error.svg")
	modal.icon_tint = Color("#ff24712d")
	modal.title = title
	modal.content = content
	modal.button_text = button_text
	return modal
