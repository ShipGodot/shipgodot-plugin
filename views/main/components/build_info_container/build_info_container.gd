@tool
extends PanelContainer

const BuildStatus = preload("res://addons/shipgodot_ios/client/models/build_status.gd").BuildStatus

const LOG_URL_TEMPLATE : String = "[code][url=%s/]build log[/url][/code]"

@export var _poll_frequency : float = 4.0

var api : ShipGodotClient
var build_id : String


func _ready() -> void:
	%ProjectName.text = ProjectSettings.get_setting("application/config/name")
	%Version.text = ProjectSettings.get_setting("application/config/version")
	%BuildId.text = build_id
	%LogLink.text = ""

	var timer := Timer.new()
	timer.wait_time = _poll_frequency
	timer.autostart = true
	timer.timeout.connect(_on_tick)
	add_child(timer)
	_on_tick()


func _on_tick() -> void:
	if not api:
		return
	var status = await api.get_build_status(build_id)
	if not status:
		return
	%Status.text = status.status_raw
	%Date.text = status.get_creation_date_string()
	%Duration.text = status.get_duration_string()
	if not status.log_url.is_empty():
		%LogLink.text = LOG_URL_TEMPLATE % status.log_url
	%Cogs.status = status
