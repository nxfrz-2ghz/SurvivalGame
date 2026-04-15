extends OptionButton

const WORLDS_PATH := "user://worlds/"
@export var key := "choosed_world"

func _ready() -> void:
	# 1. Сначала сканируем папки
	scan_worlds()
	
	# 2. Пытаемся восстановить прошлый выбор
	if DiskControl.has(key):
		var saved_val: String = DiskControl.take(key)
		var idx = find_item_by_text(saved_val)
		
		if idx != -1:
			selected = idx # Устанавливаем визуальный выбор
		else:
			# Если сохраненного мира больше нет, сбрасываем сохранение или выбираем первый
			if item_count > 0:
				_on_item_selected(0)


# Заменяем bool на возврат индекса (так полезнее)
func find_item_by_text(txt: String) -> int:
	for i in range(item_count):
		if get_item_text(i) == txt:
			return i
	return -1

func scan_worlds() -> void:
	clear()
	
	# Проверяем существование папки, чтобы избежать ошибок в консоли
	if not DirAccess.dir_exists_absolute(WORLDS_PATH):
		DirAccess.make_dir_recursive_absolute(WORLDS_PATH)
		return

	# Современный способ получения списка папок в Godot 4
	var dirs = DirAccess.get_directories_at(WORLDS_PATH)
	
	for dir_name in dirs:
		add_item(dir_name)
	
	# Если список пуст, можно добавить заглушку или задизейблить кнопку
	disabled = (item_count == 0)

func _on_item_selected(index: int) -> void:
	var choosed_world: String = get_item_text(index)
	
	# Упрощаем: если значение новое — сохраняем
	if not DiskControl.has(key) or DiskControl.take(key) != choosed_world:
		DiskControl.save(key, choosed_world)
