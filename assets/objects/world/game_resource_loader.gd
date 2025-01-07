class_name GameResourceLoader

static func load_resources(
		folder_path: String,
		resource_list: Array,
		resource_map: Dictionary,
		name_setter: Callable) -> void:
	
	var resource_paths := DirAccess.get_files_at(folder_path)
	
	for resource_path in resource_paths:
		var resource_full_path := folder_path.path_join(resource_path)
		
		var resource := load(resource_full_path)
		var resource_name := resource_path.get_basename()
		
		name_setter.call(resource, resource_name)
		
		# Assign name to list index
		resource_map[resource_name] = resource_list.size()
		resource_list.push_back(resource)
