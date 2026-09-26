extends CharacterBody2D

# Базовое движение
@export var speed: float = 320.0
@export var accel: float = 2400.0
@export var friction: float = 2800.0
@export var air_accel: float = 1600.0

# Прыжок и гравитация
@export var jump_velocity: float = -400.0
@export var gravity: float = 1650.0
@export var fall_gravity_mult: float = 1.6
@export var jump_cooldown: float = 0.15
var jump_timer: float = 0.0

# Настройки троса и анимации вылета
@export var swing_force: float = 750.0
@export var release_boost: float = 1.15
@export var rope_speed: float = 2400.0 # Скорость вылета крюка (пикселей/сек)
@export var max_rope_distance: float = 550.0 # Максимальная дальность

# Состояния троса
var rope_active: bool = false
var rope_launching: bool = false
var rope_target_point: Vector2 = Vector2.ZERO
var rope_tip_pos: Vector2 = Vector2.ZERO
var rope_length: float = 0.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var line_2d: Line2D = $Line2D
@onready var camera: Camera2D = $Camera2D

func _ready() -> void:
	line_2d.visible = false
	camera.zoom = Vector2(2.0, 2.0)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 10.0

func _physics_process(delta: float) -> void:
	if jump_timer > 0.0:
		jump_timer -= delta

	var move_dir: float = 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_action_pressed("ui_left"):
		move_dir -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_action_pressed("ui_right"):
		move_dir += 1.0

	# 1. Анимация вылета крюка
	if rope_launching:
		rope_tip_pos = rope_tip_pos.move_toward(rope_target_point, rope_speed * delta)
		
		# Отрисовка летящей нити
		draw_rope_visual(global_position, rope_tip_pos, false)

		# Крюк долетел до стены
		if rope_tip_pos.distance_to(rope_target_point) < 8.0:
			rope_launching = false
			rope_active = true
			rope_length = global_position.distance_to(rope_target_point)

	# 2. Физика раскачки (когда крюк уже зацепился)
	elif rope_active:
		velocity.y += gravity * delta
		
		if move_dir != 0:
			velocity.x += move_dir * swing_force * delta

		var to_hook = global_position - rope_target_point
		var current_dist = to_hook.length()

		if current_dist > rope_length:
			var normal = to_hook.normalized()
			global_position = rope_target_point + normal * rope_length
			
			var dot = velocity.dot(normal)
			if dot > 0:
				velocity -= normal * dot

		draw_rope_visual(global_position, rope_target_point, true)

	# 3. Обычное движение по земле и в воздухе
	else:
		line_2d.visible = false

		if not is_on_floor():
			var current_gravity = gravity
			if velocity.y > 0:
				current_gravity *= fall_gravity_mult
			velocity.y += current_gravity * delta

			if move_dir != 0:
				velocity.x = move_toward(velocity.x, move_dir * speed, air_accel * delta)
		else:
			if move_dir != 0:
				velocity.x = move_toward(velocity.x, move_dir * speed, accel * delta)
			else:
				velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	move_and_slide()
	update_animations(move_dir)

# Отрисовка троса с динамическим наконечником
func draw_rope_visual(start_pos: Vector2, end_pos: Vector2, is_locked: bool) -> void:
	line_2d.visible = true
	line_2d.clear_points()
	line_2d.add_point(to_local(start_pos))
	
	# Добавляем центральную легкую дугу во время полета
	if not is_locked:
		var mid = to_local((start_pos + end_pos) * 0.5) + Vector2(0, 10.0)
		line_2d.add_point(mid)
		
	line_2d.add_point(to_local(end_pos))

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_W or event.keycode == KEY_UP:
			if is_on_floor() and jump_timer <= 0.0 and not rope_active and not rope_launching:
				velocity.y = jump_velocity
				jump_timer = jump_cooldown

func update_animations(move_dir: float) -> void:
	if move_dir > 0:
		animated_sprite.flip_h = false
	elif move_dir < 0:
		animated_sprite.flip_h = true

	if rope_active or rope_launching or not is_on_floor():
		animated_sprite.play("jump")
	else:
		if abs(velocity.x) > 15.0:
			animated_sprite.play("run")
		else:
			animated_sprite.play("idle")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			try_attach_rope()
		else:
			detach_rope()

func try_attach_rope() -> void:
	var mouse_pos = get_global_mouse_position()
	
	# Ограничение по максимальной дистанции
	if global_position.distance_to(mouse_pos) > max_rope_distance:
		return

	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, mouse_pos)
	query.exclude = [self]
	
	var result = space_state.intersect_ray(query)
	
	if result:
		rope_target_point = result.position
		rope_tip_pos = global_position
		rope_launching = true
		rope_active = false

func detach_rope() -> void:
	if rope_active or rope_launching:
		rope_active = false
		rope_launching = false
		line_2d.visible = false
		velocity *= release_boost
