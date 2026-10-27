extends RefCounted

var api : ShipGodotClient

signal progress(parts_done: int, parts_total: int)
signal completed(size: int)
signal failed(reason: String)

const PART_SIZE := 8 * 1024 * 1024
const MAX_RETRIES := 4
const PART_TIMEOUT := 800.0

var _busy := false
var _cancelled := false
var _timer : Timer


func upload(build_id: String, file_path: String) -> void:
	if _busy:
		return
	_busy = true
	_cancelled = false
 
	var f := FileAccess.open(file_path, FileAccess.READ)
	if f == null:
		_fail("cannot open %s: %s" % [file_path, error_string(FileAccess.get_open_error())])
		return
 
	var size := f.get_length()
	var total := maxi(1, ceili(float(size) / PART_SIZE))
 
	var upload_id := await api.init_multipart_upload(build_id)
	if upload_id == null:
		_fail("failed fetching upload_id")
		return

	var parts: Array = []
	progress.emit(0, total)
	for n in range(1, total + 1):
		if _cancelled:
			await api.abort_upload(build_id)
			_fail("cancelled")
			return
 
		f.seek((n - 1) * PART_SIZE)
		var chunk := f.get_buffer(PART_SIZE)
 
		var etag := await _upload_part(build_id, upload_id, n, chunk)
		if etag.is_empty():
			await api.abort_upload(build_id)
			_fail("cancelled" if _cancelled else "part %d failed after %d attempts" % [n, MAX_RETRIES])
			return
 
		parts.append({"part_number": n, "etag": etag})
		progress.emit(n, total)
 
	var uploaded := await _complete_upload(build_id, upload_id, parts)
	if not uploaded:
		await api.abort_upload(build_id)
		_fail("complete rejected")
	_busy = false
	completed.emit(uploaded)


func _upload_part(build_id: String, upload_id: String, n: int, chunk: PackedByteArray) -> String:
	var url := ""
	for attempt in MAX_RETRIES:
		if _cancelled:
			return ""
 
		# Fetch the presigned URL
		if url.is_empty():
			url = await api.presign_upload_part(build_id, upload_id, n)
			if url.is_empty():
				await _backoff(attempt)
				continue
 
		var etag := await api.upload_project_part(url, chunk)
		if etag.is_empty():
			await _backoff(attempt)
			continue
		return etag
 
	return ""


func _complete_upload(build_id: String, upload_id: String, parts: Array[Dictionary]) -> int:
	for attempt in MAX_RETRIES:
		var uploaded := await api.complete_multipart_upload(build_id, upload_id, parts)
		if not uploaded:
			await _backoff(attempt)
			continue
		return uploaded
	return 0


func _backoff(attempt: int) -> void:
	if _timer:
		_timer.start(2.0 * pow(2.0, attempt))
		await _timer.timeout

# TODO: Use api last_error ?
func _fail(reason: String) -> void:
	_busy = false
	failed.emit(reason)
