class Activation:
	extends RefCounted
	var activation_id: int
	var device_id: String
	var instance_name: String
	var status: String              ## "active" | "deactivated"
	var activated_at: int
	var last_seen_at: int
	var is_this_device: bool

	static func from_dict(d: Dictionary) -> Activation:
		var r := Activation.new()
		r.activation_id = int(d.get("activation_id", 0))
		r.device_id = str(d.get("device_id", ""))
		r.instance_name = str(d.get("instance_name", ""))
		r.status = str(d.get("status", ""))
		r.activated_at = int(d.get("activated_at", 0))
		r.last_seen_at = int(d.get("last_seen_at", 0))
		r.is_this_device = bool(d.get("is_this_device", false))
		return r

