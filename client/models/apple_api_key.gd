class AppleApiKey:
	extends RefCounted
	var key_id: String
	var issuer_id: String
	var p8: String                  ## PEM contents of the .p8 file

	func _init(key_id_: String = "", issuer_id_: String = "", p8_: String = "") -> void:
		key_id = key_id_
		issuer_id = issuer_id_
		p8 = p8_

	func to_dict() -> Dictionary:
		return {"key_id": key_id, "issuer_id": issuer_id, "p8": p8}
