extends Node
# Путь к файлу сохранения
const SAVE_PATH = "user://game_stats.cfg"
const SECTION = "settings"

var _config: ConfigFile = ConfigFile.new()


func _ready():
	_load_config()


# Загружает статистику по названию
func take(key: String):
	if _config.has_section_key(SECTION, key):
		return _config.get_value(SECTION, key)
	return null


# Сохраняет статистику
func save(key: String, value) -> void:
	_config.set_value(SECTION, key, value)
	_config.save(SAVE_PATH)


# Проверяет наличие значения
func has(key: String) -> bool:
	return _config.has_section_key(SECTION, key)


# Удаляет значение
func delete(key: String) -> void:
	if _config.has_section_key(SECTION, key):
		_config.erase_section_key(SECTION, key)
		_config.save(SAVE_PATH)


# Очищает все данные
func clear() -> void:
	if _config.has_section(SECTION):
		_config.erase_section(SECTION)
	_config.save(SAVE_PATH)


# Получает все ключи статистики
func get_all_keys() -> PackedStringArray:
	if _config.has_section(SECTION):
		return _config.get_section_keys(SECTION)
	return PackedStringArray()


# Приватная функция загрузки конфига
func _load_config() -> void:
	if _config.load(SAVE_PATH) != OK:
		# Если файл не существует, создаем пустой конфиг
		_config = ConfigFile.new()


func rm_dir(dir_path):
	var dir = DirAccess.open(dir_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			# Игнорируем специальные записи "." и ".."
			if file_name != "." and file_name != "..":
				var full_path = dir_path.path_join(file_name)
				if dir.current_is_dir():
					# Рекурсивный вызов для подпапки
					rm_dir(full_path)
				else:
					# Удаление файла
					DirAccess.remove_absolute(full_path)
			
			# Переход к следующему элементу должен быть в любом случае, 
			# после обработки текущего элемента (файла или папки).
			file_name = dir.get_next()
			
		dir.list_dir_end()
		# После удаления всего содержимого, удаляем саму папку
		DirAccess.remove_absolute(dir_path)
	else:
		print("Не удалось открыть директорию: " + dir_path)
