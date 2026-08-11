class BuildStatus:
	extends RefCounted
	enum Status { QUEUED, DISPATCHED, RUNNING, SUCCEEDED, FAILED, CANCELLED, TIMED_OUT, UNKNOWN }

	var build_id: String
	var status: Status = Status.UNKNOWN
	var status_raw: String
	var created_at: int
	var started_at: int             ## 0 if not started
	var finished_at: int            ## 0 if not finished
	var billable_minutes: int       ## 0 until finished
	var error_summary: String       ## set when failed / timed_out
	var log_url: String             ## presigned log URL, may be empty

	const _STATUS_MAP := {
		"queued": Status.QUEUED, "dispatched": Status.DISPATCHED,
		"running": Status.RUNNING, "succeeded": Status.SUCCEEDED,
		"failed": Status.FAILED, "cancelled": Status.CANCELLED,
		"timed_out": Status.TIMED_OUT,
	}


	func get_duration_string() -> String:
		var seconds := 0
		if is_finished():
			seconds = finished_at - started_at
		elif started_at != 0:
			seconds = Time.get_unix_time_from_system() - started_at

		if seconds <= 0:
			return "Duration: 0s"

		var days := seconds / 86400
		var hours := (seconds % 86400) / 3600
		var minutes := (seconds % 3600) / 60
		var secs := seconds % 60

		var parts: Array[String] = []

		if days > 0:
			parts.append("%dd" % days)
		if hours > 0 or days > 0:
			parts.append("%dh" % hours)
		if minutes > 0 or hours > 0 or days > 0:
			parts.append("%dm" % minutes)
		parts.append("%ds" % secs)

		return "Duration: " + " ".join(parts)


	func get_creation_date_string() -> String:
		var datetime := Time.get_datetime_dict_from_unix_time(created_at)

		var months := [
			"January", "February", "March", "April", "May", "June",
			"July", "August", "September", "October", "November", "December"
		]

		var day: int = datetime["day"]
		var month: String = months[datetime["month"] - 1]
		var year: int = datetime["year"]

		var suffix := "th"
		if not (day in [11, 12, 13]):
			match day % 10:
				1: suffix = "st"
				2: suffix = "nd"
				3: suffix = "rd"

		var hours: String = "%02d" % datetime["hour"]
		var minutes: String = "%02d" % datetime["minute"]

		return "%s %d%s, %d %s:%s" % [month, day, suffix, year, hours, minutes]


	func is_finished() -> bool:
		return status in [Status.SUCCEEDED, Status.FAILED, Status.CANCELLED, Status.TIMED_OUT]

	func is_success() -> bool:
		return status == Status.SUCCEEDED

	func is_processing() -> bool:
		return status in [Status.RUNNING, Status.QUEUED, Status.DISPATCHED]

	static func from_dict(d: Dictionary) -> BuildStatus:
		var r := BuildStatus.new()
		r.build_id = str(d.get("build_id", ""))
		r.status_raw = str(d.get("status", ""))
		r.status = _STATUS_MAP.get(r.status_raw, Status.UNKNOWN)
		r.created_at = int(d.get("created_at", 0))
		r.started_at = int(d.get("started_at", 0))
		r.finished_at = int(d.get("finished_at", 0))
		r.billable_minutes = int(d.get("billable_minutes", 0))
		r.error_summary = str(d.get("error_summary", ""))
		r.log_url = str(d.get("log_url", ""))
		return r

