class_name SGModalData
extends Resource

signal modal_closed

enum Type { INFO, WARNING, ERROR }

@export var type : Type = Type.INFO
@export var icon : Texture2D
@export var icon_tint : Color = Color("#7e7bff2d")
@export var title : String
@export_multiline var content : String
@export var button_text : String
