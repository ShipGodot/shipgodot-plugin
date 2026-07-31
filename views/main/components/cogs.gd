@tool
@icon("res://addons/shipgodot_ios/views/icons/cog.svg")
extends Control

const BuildStatus = preload("res://addons/shipgodot_ios/client/models/build_status.gd").BuildStatus
@export var rotation_speed : float = 0.4

@export var success_color : Color = Color.GREEN
@export var failed_color : Color = Color.RED
@export var normal_color : Color = Color.WHITE_SMOKE


var status : BuildStatus:
	get:
		return status
	set(value):
		status = value
		set_process(true)


func _ready() -> void:
	modulate = normal_color
	set_process(false)


func _process(delta: float) -> void:
	if status.is_finished() and not status.is_success():
		modulate = failed_color
		set_process(false)
	elif status.is_finished():
		modulate = success_color
		set_process(false)
	elif status.is_processing():
		modulate = normal_color
		%Cog1.rotation = %Cog1.rotation + delta * rotation_speed
		%Cog2.rotation = %Cog2.rotation - delta * rotation_speed
	else:
		modulate = normal_color
		set_process(false)
