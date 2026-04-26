extends HSlider

@export var key: String

func _ready() -> void:
	# Подключаем сигнал окончания ввода (когда нажали Enter или сменили фокус)
	drag_ended.connect(_on_save)
	
	# Загрузка данных
	if DiskControl.has(key):
		var val = DiskControl.take(key)
		value = float(val)
		apply(value)

func _on_save(cchanged: bool = false) -> void:
	if !cchanged: return
	apply(value)
	
	# Сохраняем, если значение изменилось
	if DiskControl.has(key):
		if float(DiskControl.take(key)) != value:
			DiskControl.save(key, value)
	else:
		# Если ключа еще нет в DiskControl, просто сохраняем
		DiskControl.save(key, value)

func apply(_val: float) -> void: pass
