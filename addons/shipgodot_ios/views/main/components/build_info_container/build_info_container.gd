@tool
extends PanelContainer

const BuildStatus = preload("res://addons/shipgodot_ios/client/models/build_status.gd").BuildStatus

var build_id : String
var version : String
var build : ShipGodotBuild
var status : BuildStatus


func setup(b : ShipGodotBuild) -> void:
	build = b
	build_id = b.build_id
	version = b.version
	status = b._status
	build.updated.connect(_status_change)


func _ready() -> void:
	%BuildId.text = build_id
	%Version.text = version
	%CancelButton.pressed.connect(build.cancel_build)
	_status_change()


func _status_change() -> void:
	%Status.text = build.status_string
	status = build._status

	if not status:
		# TODO print error message
		return
	%Date.text = status.get_creation_date_string()
	%Duration.text = status.get_duration_string()

	if not status.log_url.is_empty():
		%LogLinkButton.visible = true
		%LogLinkButton.uri = status.log_url
		%CancelButton.visible = false

	if status.is_finished():
		%CancelButton.visible = false

	%Cogs.status = status
