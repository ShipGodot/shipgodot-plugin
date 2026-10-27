@tool
extends ShipGodotView

const BuildSlot = preload("res://addons/shipgodot_ios/client/models/build_slot.gd").BuildSlot
const BuildInfoContainer = preload("res://addons/shipgodot_ios/views/main/components/build_info_container/build_info_container.gd")

const ZIP_PATH := "user://project_upload.zip"

@export var build_component : PackedScene

var _default_excludes := [".godot", ".git", ".import"]
var _current_build_container : BuildInfoContainer


func _ready() -> void:
	update_session()
	%RunButton.pressed.connect(_create_new_build)


func update_session() -> void:
	var session := await api.get_session()
	if not session:
		_display_last_api_error()
		return
	%LicenseStatus.text = session.license_status
	%BuildMinutes.text = str(session.minutes_available)


func _create_new_build() -> void:
	processing.emit(true)
	if _current_build_container and not _current_build_container.status.is_finished():
		processing.emit(false)
		var error_modal = SGModalData.error_modal("You can request a new build once the current one is done.", "Build in progress")
		request_modal.emit(error_modal)
		return

	var poll_timer := Timer.new()
	var backoff_timer := Timer.new()
	add_child(poll_timer)
	add_child(backoff_timer)
	var build : ShipGodotBuild = await ShipGodotBuild.create(api, poll_timer, backoff_timer)
	if not build:
		processing.emit(false)
		_display_last_api_error()
		return
	build.completed.connect(update_session)

	%EmptyText.visible = false

	if _current_build_container:
		_current_build_container.build.completed.disconnect(update_session)

	_current_build_container = build_component.instantiate()
	_current_build_container.setup(build)
	%BuildsContainer.add_child(_current_build_container)
	%BuildsContainer.move_child(_current_build_container, 0)

	processing.emit(false)
