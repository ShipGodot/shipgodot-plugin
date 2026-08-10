class AppleApiKey:
	extends RefCounted
	var key_id: String
	var issuer_id: String
	var p8: String                  ## PEM contents of the .p8 file

	# Key ID: 10 uppercase alphanumeric chars, e.g. "2X9R4HXF34"
	var _key_id_regex := RegEx.create_from_string(r"^[A-Z0-9]{10}$")
	# Issuer ID: lowercase UUID, e.g. "57246542-96fe-1a63-e053-0824d011072a"
	var _issuer_id_regex := RegEx.create_from_string(r"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$")
	# .p8 contents: PKCS#8 PEM block. Group 1 = base64 body (may span lines).
	var _p8_regex := RegEx.create_from_string(r"^\s*-----BEGIN PRIVATE KEY-----\s*([A-Za-z0-9+/=\s]+?)\s*-----END PRIVATE KEY-----\s*$")

	func _init(key_id: String = "", issuer_id: String = "", p8: String = "") -> void:
		key_id = key_id
		issuer_id = issuer_id
		p8 = p8

	func to_dict() -> Dictionary:
		return {"key_id": key_id, "issuer_id": issuer_id, "p8": p8}


	func validate_key_id() -> bool:
		return _key_id_regex.search(key_id) != null


	func validate_issuer_id() -> bool:
		return _issuer_id_regex.search(issuer_id) != null


	func validate_p8() -> bool:
		return _p8_regex.search(p8) != null
