extends CanvasLayer

@onready var sprite = $Sprite2D
@onready var timer = $IdleTimer

var speed = 300.0
var velocity = Vector2(1, 1).normalized()
var screen_size

func _ready():
	screen_size = get_viewport().get_visible_rect().size
	sprite.hide() # Прячем логотип при старте

func _input(event):
	# Если нажата клавиша или сдвинута мышь
	if event is InputEventMouseMotion or event is InputEventKey or event is InputEventMouseButton:
		reset_screensaver()

func _process(delta):
	if sprite.visible:
		move_logo(delta)

func move_logo(delta):
	sprite.position += velocity * speed * delta
	
	var half_size = (sprite.texture.get_size() * sprite.scale) / 2.0
	
	# Отскоки
	if sprite.position.x + half_size.x >= screen_size.x or sprite.position.x - half_size.x <= 0:
		velocity.x *= -1
		sprite.modulate = Color(randf(), randf(), randf())
		
	if sprite.position.y + half_size.y >= screen_size.y or sprite.position.y - half_size.y <= 0:
		velocity.y *= -1
		sprite.modulate = Color(randf(), randf(), randf())

func reset_screensaver():
	# Прячем логотип и сбрасываем таймер
	if sprite.visible:
		sprite.hide()
	timer.start() # Перезапуск отсчета 5 минут


func _on_idle_timer_timeout() -> void:
	# По истечении 5 минут показываем логотип
	sprite.position = screen_size / 2.0
	sprite.show()
