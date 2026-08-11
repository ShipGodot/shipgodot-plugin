@tool
extends PanelContainer

const BuildStatus = preload("res://addons/shipgodot_ios/client/models/build_status.gd").BuildStatus

var _cancelling := false
var _cancel_timer := Timer.new()
var _cancel_retries := 0

@export var _poll_frequency : float = 4.0

var api : ShipGodotClient
var build_id : String
var version : String
var timer := Timer.new()
var status : BuildStatus

signal finished


func cancel_build() -> void:
	%CancelButton.visible = false
	_cancelling = true
	_cancel_retries += 1

	var cancel_status = await api.cancel_build(build_id)

	if cancel_status or status.is_finished():
		_cancel_timer.stop()
	elif not cancel_status and _cancel_retries == 1:
		_cancel_timer.start()
	elif not cancel_status and _cancel_retries > 10:
		_cancel_timer.stop()
		_cancel_retries = 0
		_cancelling = false
		%CancelButton.visible = true


func _ready() -> void:
	%BuildId.text = build_id
	%Version.text = version
	timer.wait_time = _poll_frequency
	timer.autostart = true
	timer.timeout.connect(_on_tick)
	_cancel_timer.wait_time = _poll_frequency
	_cancel_timer.timeout.connect(cancel_build)
	%CancelButton.pressed.connect(cancel_build)
	add_child(timer)
	add_child(_cancel_timer)
	_on_tick()


func _on_tick() -> void:
	if not api:
		return
	status = await api.get_build_status(build_id)

	if not status:
		# TODO print error message
		return
	%Status.text = status.status_raw
	%Date.text = status.get_creation_date_string()
	%Duration.text = status.get_duration_string()

	if not status.log_url.is_empty():
		%LogLinkButton.visible = true
		%LogLinkButton.uri = status.log_url
		%CancelButton.visible = false

	if status.is_finished():
		%CancelButton.visible = false
		timer.stop()
		finished.emit()
	elif _cancelling:
		%Status.text = "cancelling..."

	%Cogs.status = status
