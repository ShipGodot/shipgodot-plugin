@tool
@icon("res://addons/shipgodot_ios/client/client.svg")
class_name ShipGodotClient
extends Node

signal request_failed(error: ApiError)

const BASE_URL := "https://shipgodot-automate-ios-testing.shipgodot.workers.dev"

var seat_token: String = ""
var license_key: String = ""
var timeout_seconds: float = 30.0
var last_error: ApiError = null

const ApiError = preload("res://addons/shipgodot_ios/client/models/api_error.gd").ApiError
const AppleApiKey = preload("res://addons/shipgodot_ios/client/models/apple_api_key.gd").AppleApiKey
const ActivateResponse = preload("res://addons/shipgodot_ios/client/models/activate_response.gd").ActivateResponse
const SessionInfo = preload("res://addons/shipgodot_ios/client/models/session_info.gd").SessionInfo
const BuildSlot = preload("res://addons/shipgodot_ios/client/models/build_slot.gd").BuildSlot
const BuildStatus = preload("res://addons/shipgodot_ios/client/models/build_status.gd").BuildStatus
const Activation = preload("res://addons/shipgodot_ios/client/models/activation.gd").Activation

# ------------------------------------------------------------
# Endpoints
# ------------------------------------------------------------

## POST /v1/activate — activate this device; provisions the tenant on first
## redemption. apple_key/apple_team_id required only on first redemption
## (pass them again any time to rotate the stored Apple credentials).
func activate(license_key_: String, device_id: String, instance_name: String = "",
		apple_team_id: String = "", apple_key: AppleApiKey = null) -> ActivateResponse:
	var body := {"license_key": license_key_, "device_id": device_id}
	if not instance_name.is_empty():
		body["instance_name"] = instance_name
	if not apple_team_id.is_empty():
		body["apple_team_id"] = apple_team_id
	if apple_key != null:
		body["apple_api_key"] = apple_key.to_dict()
	var d := await _request_json(HTTPClient.METHOD_POST, "/v1/activate", body, _Auth.NONE)
	if d == null:
		return null
	license_key = license_key_
	return ActivateResponse.from_dict(d)


## GET /v1/me — validate the seat token / subscription state on startup.
func get_session() -> SessionInfo:
	var d := await _request_json(HTTPClient.METHOD_GET, "/v1/me", {}, _Auth.SEAT_TOKEN)
	return null if d == null else SessionInfo.from_dict(d)


## POST /v1/builds — request a build slot + presigned upload URL.
func request_build_slot() -> BuildSlot:
	var d := await _request_json(HTTPClient.METHOD_POST, "/v1/builds", {}, _Auth.SEAT_TOKEN)
	return null if d == null else BuildSlot.from_dict(d)


## PUT <presigned URL> — upload the project zip straight to R2.
## Not part of the Worker API; no auth header (the signature is in the URL).
func upload_project_zip(upload_url: String, zip_path: String) -> bool:
	last_error = null
	var bytes := FileAccess.get_file_as_bytes(zip_path)
	if bytes.is_empty() and FileAccess.get_open_error() != OK:
		_fail(ApiError.transport("Cannot read zip: %s" % zip_path))
		return false
	var http := _make_http()
	var err := http.request_raw(upload_url, PackedStringArray(["Content-Type: application/zip"]),
			HTTPClient.METHOD_PUT, bytes)
	if err != OK:
		http.queue_free()
		_fail(ApiError.transport("HTTPRequest.request_raw failed: %d" % err))
		return false
	var resp: Array = await http.request_completed
	http.queue_free()
	var code := int(resp[1])
	if resp[0] != HTTPRequest.RESULT_SUCCESS:
		_fail(ApiError.transport("Upload transport error: %d" % resp[0]))
		return false
	if code < 200 or code >= 300:
		_fail(ApiError.from_response(code, {"error": "upload_failed"}))
		return false
	return true


## POST /v1/builds/{id}/dispatch — start the build after the upload succeeded.
func dispatch_build(build_id: String, bundle_id: String, godot_version: String = "") -> BuildStatus:
	var body := {"bundle_id": bundle_id}
	if not godot_version.is_empty():
		body["godot_version"] = godot_version
	var d := await _request_json(HTTPClient.METHOD_POST,
			"/v1/builds/%s/dispatch" % build_id.uri_encode(), body, _Auth.SEAT_TOKEN)
	return null if d == null else BuildStatus.from_dict(d)


## GET /v1/builds/{id} — poll build status.
func get_build_status(build_id: String) -> BuildStatus:
	var d := await _request_json(HTTPClient.METHOD_GET,
			"/v1/builds/%s" % build_id.uri_encode(), {}, _Auth.SEAT_TOKEN)
	return null if d == null else BuildStatus.from_dict(d)


## POST /v1/builds/{id}/cancel — cancel a queued/running build.
func cancel_build(build_id: String) -> BuildStatus:
	var d := await _request_json(HTTPClient.METHOD_POST,
			"/v1/builds/%s/cancel" % build_id.uri_encode(), {}, _Auth.SEAT_TOKEN)
	return null if d == null else BuildStatus.from_dict(d)


## POST /v1/deactivate — deactivate THIS device; frees an activation slot.
## Returns true on success (clears the stored seat token).
func deactivate_self() -> bool:
	var d := await _request_json(HTTPClient.METHOD_POST, "/v1/deactivate", {}, _Auth.SEAT_TOKEN)
	if d == null:
		return false
	seat_token = ""
	return true


## POST /v1/topup — buy extra build minutes (license-key auth; charged via
## Lemon Squeezy immediately, minutes land asynchronously — re-poll get_session()).
## Returns the number of pending minutes, or -1 on failure.
func request_topup(units: int = 1) -> int:
	var d := await _request_json(HTTPClient.METHOD_POST, "/v1/topup", {"units": units}, _Auth.LICENSE_KEY)
	if d == null:
		return -1
	return int(d.get("minutes", 0))


## GET /v1/activations — list devices on this license (license-key auth,
## works from a brand-new device). Requires `license_key` to be set.
func list_activations() -> Array[Activation]:
	var arr := await _request_json_array(HTTPClient.METHOD_GET, "/v1/activations", _Auth.LICENSE_KEY)
	if arr == null:
		return []
	var out: Array[Activation] = []
	for item in arr:
		if item is Dictionary:
			out.append(Activation.from_dict(item))
	return out


## DELETE /v1/activations/{id} — deactivate ANOTHER device (dead-machine
## escape hatch). License-key auth. Returns true on success.
func deactivate_by_id(activation_id: int) -> bool:
	var d := await _request_json(HTTPClient.METHOD_DELETE,
			"/v1/activations/%d" % activation_id, {}, _Auth.LICENSE_KEY)
	return d != null

# ------------------------------------------------------------
# Internals
# ------------------------------------------------------------

enum _Auth { NONE, SEAT_TOKEN, LICENSE_KEY }

func _make_http() -> HTTPRequest:
	var http := HTTPRequest.new()
	http.timeout = timeout_seconds
	add_child(http)
	return http

func _headers_for(auth: _Auth) -> PackedStringArray:
	var h := PackedStringArray(["Content-Type: application/json", "Accept: application/json"])
	match auth:
		_Auth.SEAT_TOKEN:
			h.append("Authorization: Bearer %s" % seat_token)
		_Auth.LICENSE_KEY:
			h.append("X-License-Key: %s" % license_key)
		_Auth.NONE:
			pass
	return h

func _fail(err: ApiError) -> Variant:
	last_error = err
	request_failed.emit(err)
	return null   # bool contexts coerce null → false via explicit checks

## Performs a request and returns the parsed JSON body as a Dictionary,
## or null on any failure ({} for empty 2xx bodies).
func _request_json(method: HTTPClient.Method, path: String, body: Dictionary, auth: _Auth) -> Variant:
	last_error = null
	if auth == _Auth.SEAT_TOKEN and seat_token.is_empty():
		return _fail(ApiError.transport("No seat token — call activate() first."))
	if auth == _Auth.LICENSE_KEY and license_key.is_empty():
		return _fail(ApiError.transport("No license key set."))

	var http := _make_http()
	var body_str := "" if body.is_empty() and method == HTTPClient.METHOD_GET else JSON.stringify(body)
	var err := http.request(BASE_URL + path, _headers_for(auth), method, body_str)
	if err != OK:
		http.queue_free()
		return _fail(ApiError.transport("HTTPRequest.request failed: %d" % err))

	var resp: Array = await http.request_completed
	http.queue_free()

	var result := int(resp[0])
	var code := int(resp[1])
	var raw: PackedByteArray = resp[3]

	if result != HTTPRequest.RESULT_SUCCESS:
		return _fail(ApiError.transport("Transport error: %d" % result))

	var parsed: Variant = {}
	if not raw.is_empty():
		parsed = JSON.parse_string(raw.get_string_from_utf8())
		if parsed == null:
			parsed = {}

	if code >= 200 and code < 300:
		return parsed if parsed is Dictionary else {}
	return _fail(ApiError.from_response(code, parsed if parsed is Dictionary else {}))

## Same as _request_json but for endpoints returning a JSON array.
func _request_json_array(method: HTTPClient.Method, path: String, auth: _Auth) -> Variant:
	# Reuse _request_json's plumbing by requesting manually (arrays aren't Dictionaries).
	last_error = null
	if auth == _Auth.LICENSE_KEY and license_key.is_empty():
		return _fail(ApiError.transport("No license key set."))
	if auth == _Auth.SEAT_TOKEN and seat_token.is_empty():
		return _fail(ApiError.transport("No seat token — call activate() first."))

	var http := _make_http()
	var err := http.request(BASE_URL + path, _headers_for(auth), method)
	if err != OK:
		http.queue_free()
		return _fail(ApiError.transport("HTTPRequest.request failed: %d" % err))
	var resp: Array = await http.request_completed
	http.queue_free()

	if int(resp[0]) != HTTPRequest.RESULT_SUCCESS:
		return _fail(ApiError.transport("Transport error: %d" % int(resp[0])))
	var code := int(resp[1])
	var parsed: Variant = JSON.parse_string((resp[3] as PackedByteArray).get_string_from_utf8())
	if code >= 200 and code < 300:
		return parsed if parsed is Array else []
	return _fail(ApiError.from_response(code, parsed if parsed is Dictionary else {}))
