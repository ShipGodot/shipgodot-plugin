class SessionInfo:
	extends RefCounted
	var tenant_status: String       ## "provisioning" | "active" | "suspended"
	var plan: String                ## "free" | "normal" | "enterprise"
	var license_status: String      ## "active" | "expired" | "disabled"
	var instance_name: String
	var subscription_minutes: int   ## minutes left from this cycle
	var topup_minutes: int          ## prepaid minutes (roll over)
	var minutes_available: int      ## subscription + topup

	func can_build() -> bool:
		return tenant_status == "active" and license_status == "active"

	static func from_dict(d: Dictionary) -> SessionInfo:
		var r := SessionInfo.new()
		r.tenant_status = str(d.get("tenant_status", ""))
		r.plan = str(d.get("plan", "free"))
		r.license_status = str(d.get("license_status", ""))
		r.subscription_minutes = int(d.get("subscription_minutes", 0))
		r.topup_minutes = int(d.get("topup_minutes", 0))
		r.minutes_available = int(d.get("minutes_available", 0))
		r.instance_name = str(d.get("instance_name", ""))
		return r
