extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	# Проверяем, что в зону упал именно наш персонаж (Player)
	if body is CharacterBody2D:
		# Перезапускаем текущую сцену
		get_tree().reload_current_scene()
