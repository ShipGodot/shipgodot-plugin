@tool
extends ShipGodotView


var apple_cred_scene = preload("res://addons/shipgodot_ios/views/apple_credentials/apple_credentials.tscn")

func _ready() -> void:
	%PasteLicenseButton.pressed.connect(_paste_from_clipboard.bind(%LicenseKeyInput))
	%ContinueButton.pressed.connect(_on_continue)




func _on_continue() -> void:
	api.license_key = %LicenseKeyInput.get_text()
	change_view.emit(apple_cred_scene)
