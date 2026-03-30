extends LineEdit

@export var key: String

func _ready() -> void:
	# Подключаем сигнал окончания ввода (когда нажали Enter или сменили фокус)
	text_submitted.connect(_on_text_submitted)
	
	# Загрузка данных
	if DiskControl.has(key):
		var val = DiskControl.take(key)
		text = str(val)
		apply(text)

func _on_text_submitted(new_text: String) -> void:
	apply(new_text)
	
	# Сохраняем, если значение изменилось
	if DiskControl.has(key):
		if str(DiskControl.take(key)) != new_text:
			DiskControl.save(key, new_text)
	else:
		# Если ключа еще нет в DiskControl, просто сохраняем
		DiskControl.save(key, new_text)

func apply(_val: String) -> void: pass
