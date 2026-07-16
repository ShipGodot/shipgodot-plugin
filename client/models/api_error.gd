class ApiError:
	extends RefCounted
	var http_code: int = 0          ## 0 = transport-level failure (no response)
	var code: String = ""           ## machine-readable, e.g. "activation_limit_reached"
	var message: String = ""

	static func from_response(http_code_: int, body: Dictionary) -> ApiError:
		var e := ApiError.new()
		e.http_code = http_code_
		# Chanfana validation envelope: {"success": false, "errors": [{code, message, path}]}
		if body.has("errors") and body["errors"] is Array and not (body["errors"] as Array).is_empty():
			var first: Dictionary = body["errors"][0]
			e.code = "invalid_input"
			var path: String = ""
			if first.has("path") and first["path"] is Array:
				path = " (" + "/".join(PackedStringArray(first["path"])) + ")"
			e.message = str(first.get("message", "")) + path
			return e
		# Business-error envelope: {"error": code, "message": detail}
		e.code = str(body.get("error", "http_%d" % http_code_))
		e.message = str(body.get("message", ""))
		return e

	static func transport(msg: String) -> ApiError:
		var e := ApiError.new()
		e.code = "transport_error"
		e.message = msg
		return e

	func _to_string() -> String:
		return "[%d %s] %s" % [http_code, code, message]

