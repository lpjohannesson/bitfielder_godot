class_name ClientLoginInfo

var game_version: String
var username: String

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
