class BuildSlot:
	extends RefCounted
	var build_id: String
	var upload_url: String          ## presigned R2 PUT URL for the project zip
	var upload_expires_at: int      ## unix epoch seconds

	static func from_dict(d: Dictionary) -> BuildSlot:
		var r := BuildSlot.new()
		r.build_id = str(d.get("build_id", ""))
		r.upload_url = str(d.get("upload_url", ""))
		r.upload_expires_at = int(d.get("upload_expires_at", 0))
		return r
