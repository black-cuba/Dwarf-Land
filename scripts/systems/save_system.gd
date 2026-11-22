class_name ColonySaveSystem
extends RefCounted

const SCHEMA_VERSION := 1
const SAVE_DIRECTORY := "user://saves"
const SAVE_FILE_NAME := "colony_save.json"

var save_directory: String


func _init(p_save_directory: String = SAVE_DIRECTORY) -> void:
	save_directory = p_save_directory


func save_snapshot(snapshot: Dictionary) -> bool:
	var absolute_directory := ProjectSettings.globalize_path(save_directory)
	if DirAccess.make_dir_recursive_absolute(absolute_directory) != OK and not DirAccess.dir_exists_absolute(absolute_directory):
		return false

	var target_path := absolute_directory.path_join(SAVE_FILE_NAME)
	var temporary_path := target_path + ".tmp"
	var backup_path := target_path + ".bak"
	var envelope := {
		"schema_version": SCHEMA_VERSION,
		"saved_at_unix": Time.get_unix_time_from_system(),
		"snapshot": _to_json_safe(snapshot)
	}

	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(envelope))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		return false

	if FileAccess.file_exists(target_path):
		if FileAccess.file_exists(backup_path):
			DirAccess.remove_absolute(backup_path)
		if DirAccess.rename_absolute(target_path, backup_path) != OK:
			DirAccess.remove_absolute(temporary_path)
			return false

	if DirAccess.rename_absolute(temporary_path, target_path) != OK:
		if FileAccess.file_exists(backup_path):
			DirAccess.rename_absolute(backup_path, target_path)
		return false
	return true


func load_snapshot() -> Dictionary:
	var absolute_directory := ProjectSettings.globalize_path(save_directory)
	var target_path := absolute_directory.path_join(SAVE_FILE_NAME)
	var backup_path := target_path + ".bak"

	var primary := _read_snapshot_file(target_path)
	if bool(primary.get("success", false)):
		primary["used_backup"] = false
		return primary

	var backup := _read_snapshot_file(backup_path)
	if bool(backup.get("success", false)):
		backup["used_backup"] = true
		return backup

	return {"success": false, "data": {}, "used_backup": false}


func _read_snapshot_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"success": false, "data": {}}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"success": false, "data": {}}
	var content := file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(content)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"success": false, "data": {}}
	if int(parsed.get("schema_version", -1)) != SCHEMA_VERSION:
		return {"success": false, "data": {}}
	if typeof(parsed.get("snapshot")) != TYPE_DICTIONARY:
		return {"success": false, "data": {}}
	return {"success": true, "data": _from_json_safe(parsed["snapshot"])}


func _to_json_safe(value: Variant) -> Variant:
	match typeof(value):
		TYPE_STRING_NAME:
			return String(value)
		TYPE_VECTOR2I:
			return {"__vector2i": true, "x": value.x, "y": value.y}
		TYPE_VECTOR3I:
			return {"__vector3i": true, "x": value.x, "y": value.y, "z": value.z}
		TYPE_VECTOR2:
			return {"__vector2": true, "x": value.x, "y": value.y}
		TYPE_DICTIONARY:
			var result: Dictionary = {}
			for key in value:
				result[String(key)] = _to_json_safe(value[key])
			return result
		TYPE_ARRAY:
			var result: Array = []
			for item in value:
				result.append(_to_json_safe(item))
			return result
	return value


func _from_json_safe(value: Variant) -> Variant:
	if typeof(value) == TYPE_DICTIONARY:
		if value.get("__vector2i", false):
			return Vector2i(int(value.get("x", 0)), int(value.get("y", 0)))
		if value.get("__vector3i", false):
			return Vector3i(int(value.get("x", 0)), int(value.get("y", 0)), int(value.get("z", 0)))
		if value.get("__vector2", false):
			return Vector2(float(value.get("x", 0.0)), float(value.get("y", 0.0)))
		var result: Dictionary = {}
		for key in value:
			result[key] = _from_json_safe(value[key])
		return result
	if typeof(value) == TYPE_ARRAY:
		var result: Array = []
		for item in value:
			result.append(_from_json_safe(item))
		return result
	return value
