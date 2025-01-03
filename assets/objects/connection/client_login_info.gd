class_name ClientLoginInfo

const LOGIN_PARAMS := ["user", "version"]

var game_version: String
var username: String

static func is_data_valid(data: Variant) -> bool:
	if not data is Dictionary:
		return false
	
	if not data.get("user") is String:
		return false
	
	if not data.get("version") is String:
		return false
	
	return true

static func from_data(data: Dictionary) -> ClientLoginInfo:
	var login_info := ClientLoginInfo.new()
	
	login_info.game_version = data["version"]
	login_info.username = data["user"]
	
	return login_info

func to_data() -> Dictionary:
	return {
		"version": game_version,
		"user": username
	}
