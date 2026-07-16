class BuildStatus:
	extends RefCounted
	enum Status { QUEUED, DISPATCHED, RUNNING, SUCCEEDED, FAILED, CANCELLED, TIMED_OUT, UNKNOWN }

	var build_id: String
	var status: Status = Status.UNKNOWN
	var status_raw: String
	var bundle_id: String
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

	func is_finished() -> bool:
		return status in [Status.SUCCEEDED, Status.FAILED, Status.CANCELLED, Status.TIMED_OUT]

	func is_success() -> bool:
		return status == Status.SUCCEEDED

	static func from_dict(d: Dictionary) -> BuildStatus:
		var r := BuildStatus.new()
		r.build_id = str(d.get("build_id", ""))
		r.status_raw = str(d.get("status", ""))
		r.status = _STATUS_MAP.get(r.status_raw, Status.UNKNOWN)
		r.bundle_id = str(d.get("bundle_id", ""))
		r.created_at = int(d.get("created_at", 0))
		r.started_at = int(d.get("started_at", 0))
		r.finished_at = int(d.get("finished_at", 0))
		r.billable_minutes = int(d.get("billable_minutes", 0))
		r.error_summary = str(d.get("error_summary", ""))
		r.log_url = str(d.get("log_url", ""))
		return r

