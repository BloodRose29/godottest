extends Area2D

# Настройки анимации парения/подпрыгивания
@export var bounce_height: float = 6.0    # Высота подпрыгивания (в пикселях)
@export var bounce_speed: float = 4.0     # Скорость колебания

# Настройки свечения
@export var glow_color: Color = Color(1.4, 1.4, 0.9, 1.0) # Значения выше 1.0 дают неоновое свечение в HDR/WorldEnvironment
@export var glow_speed: float = 3.0       # Скорость пульсации света

var start_y: float = 0.0
var time_passed: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D # Либо AnimatedSprite2D, если у тебя анимация

func _ready() -> void:
	start_y = position.y
	
	# Подключаем сигнал столкновения с игроком
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	time_passed += delta
	
	# 1. Плавное подпрыгивание вверх-вниз по синусоиде
	position.y = start_y + sin(time_passed * bounce_speed) * bounce_height
	
	# 2. Пульсация свечения через цвет модулятора (Modulate)
	var pulse = (sin(time_passed * glow_speed) + 1.0) * 0.5 # Значение от 0.0 до 1.0
	var current_intensity = lerp(1.1, 1.8, pulse)
	
	if sprite:
		sprite.modulate = glow_color * current_intensity

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("Player"):
		# Логика победы / перехода на следующий уровень или в меню
		get_tree().change_scene_to_file("res://Scene/main_menu.tscn")
