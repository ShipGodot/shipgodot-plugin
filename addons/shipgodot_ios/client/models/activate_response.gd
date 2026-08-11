class ActivateResponse:
	extends RefCounted
	var seat_token: String
	var activation_id: int
	var tenant_status: String       ## "provisioning" | "active" | "suspended"
	var provisioned: bool           ## true if this call created the tenant

	static func from_dict(d: Dictionary) -> ActivateResponse:
		var r := ActivateResponse.new()
		r.seat_token = str(d.get("seat_token", ""))
		r.activation_id = int(d.get("activation_id", 0))
		r.tenant_status = str(d.get("tenant_status", ""))
		r.provisioned = bool(d.get("provisioned", false))
		return r
