class_name ClientLoginInfo

var username: String

static func from_data(data: Dictionary) -> ClientLoginInfo:
	var login_info := ClientLoginInfo.new()
	login_info.username = data["user"]
	
	return login_info

func to_data() -> Dictionary:
	return { "user": username }
