@tool
class_name ShipGodotBuild
extends RefCounted

const BuildSlot = preload("res://addons/shipgodot_ios/client/models/build_slot.gd").BuildSlot
const BuildStatus = preload("res://addons/shipgodot_ios/client/models/build_status.gd").BuildStatus

var build_id : String
var version : String

var status_string : String:
	set(value):
		status_string = value
		updated.emit()

var _api : ShipGodotClient
var _uploader : ShipGodotUploader
var _zipper : ShipGodotZipper

var _poll_timer : Timer
var _status : BuildStatus: set = _set_status
var _cancelled := false
var _cancelling := false

signal updated
signal completed
signal failed(reason: String)


static func create(p_api: ShipGodotClient, poll_timer: Timer, backoff_timer: Timer) -> ShipGodotBuild:
	var b := ShipGodotBuild.new()
	
	var slot : BuildSlot = await p_api.request_build_slot()
	if not slot:
		return null

	b._api = p_api
	b.build_id = slot.build_id
	b.version = str(ProjectSettings.get_setting("application/config/version", ""))
	b._status = BuildStatus.new()
	b._poll_timer = poll_timer
	b._poll_timer.one_shot = true
	b._poll_timer.timeout.connect(b._on_poll_timeout)

	b._zipper = ShipGodotZipper.new()
	b._zipper.zip_finished.connect(b._zip_finished)
	b._zipper.failed.connect(b._fail)
	b._zipper.zip_dir_async("res://")
	b.status_string = "Preparing upload..."

	b._uploader = ShipGodotUploader.new(p_api, backoff_timer)
	b._uploader.progress.connect(b._uploader_progress)
	b._uploader.completed.connect(b._uploader_finished)
	b._uploader.failed.connect(b._fail)

	return b


func cancel_build() -> void:
	if _status.is_finished() or _cancelling:
		return

	status_string = "Cancelling..."
	_cancelling = true

	if _uploader.is_busy():
		_uploader.cancel()

	var cancel_status := await _api.cancel_build(build_id)
	if not cancel_status:
		_cancelling = false
		return
	_status = cancel_status

	if _status.error_summary.is_empty():
		_status.error_summary = "build cancelled"

	_cancelling = false
	_cancelled = true
	status_string = "Cancelled"


func _zip_finished(ok: bool) -> void:
	if not ok or _cancelled:
		return
	_uploader.upload(build_id, _zipper.ZIP_PATH)


func _uploader_progress(parts_done: int, parts_total: int) -> void:
	var percent = 100.0 * float(parts_done) / float(parts_total)
	status_string = "Uploading: %.1f%%" % percent


func _uploader_finished(size: int) -> void:
	if size == 0 or _cancelled:
		return

	var dispatch_status := await _api.dispatch_build(build_id, ShipGodotUtils.get_bundle_id(), ShipGodotUtils._get_engine_version())
	if not dispatch_status:
		_fail(_api.last_error.message)
		return
		
	_status = dispatch_status
	_poll_timer.start()


func _set_status(status : BuildStatus) -> void:
	# TODO: set other vars
	if status:
		_status = status
		if not _cancelling:
			match status.status_raw:
				"dispatched", "queued":
					status_string = "Waiting in queue…"
				"running":
					status_string = "Running…"
				"succeeded":
					status_string = "Completed"
				"failed":
					status_string = "Failed"
				"cancelled":
					status_string = "Cancelled"
				"timed_out":
					status_string = "Timed out"
				_:
					status_string = "Unknown status: %s" % status
		if status.is_finished():
			if not status.is_success():
				_fail(status.error_summary)
			completed.emit()


func _on_poll_timeout() -> void:
	_status = await _api.get_build_status(build_id)
	if _status and not _status.is_finished():
		_poll_timer.start()


func _fail(reason: String) -> void:
	push_error("Build [%s] failed: %s" % [build_id, reason])
	await cancel_build()
	status_string = "Error: %s" % reason
	failed.emit(reason)
