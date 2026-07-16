@tool
extends PanelContainer

const BuildStatus = preload("res://addons/shipgodot_ios/client/models/build_status.gd").BuildStatus

var api : ShipGodotClient
var build_id : String = ""

func _ready() -> void:
	var timer := Timer.new()
	timer.wait_time = 10.0
	timer.autostart = true          # start as soon as it's in the tree
	timer.timeout.connect(_on_tick)
	add_child(timer)

func _on_tick() -> void:
	var status = await api.get_build_status(build_id)
	%Status.text = status.status_raw
