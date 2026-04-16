extends LineEdit

@export var key: String

func _ready() -> void:
	# Подключаем сигнал окончания ввода (когда нажали Enter или сменили фокус)
	editing_toggled.connect(_on_save)
	
	# Загрузка данных
	if DiskControl.has(key):
		var val = DiskControl.take(key)
		text = str(val)
		apply(text)

func _on_save(toggle: bool = false) -> void:
	if toggle: return
	apply(text)
	
	# Сохраняем, если значение изменилось
	if DiskControl.has(key):
		if str(DiskControl.take(key)) != text:
			DiskControl.save(key, text)
	else:
		# Если ключа еще нет в DiskControl, просто сохраняем
		DiskControl.save(key, text)

func apply(_val: String) -> void: pass
