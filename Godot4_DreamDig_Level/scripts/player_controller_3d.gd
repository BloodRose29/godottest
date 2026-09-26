class_name PlayerController3D
extends CharacterBody3D
## Контроллер игрока от 1-го лица для психологического хоррора в Godot 4.
## Управление: WASD для шага, мышь для обзора, ЛКМ/[E] — копать яму, [F] — фонарик.

@export_group("Параметры движения")
@export var walk_speed: float = 3.2
@export var mouse_sensitivity: float = 0.002
@export var bob_frequency: float = 2.4
@export var bob_amplitude: float = 0.06

@export_group("Связанные 3D узлы")
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var shovel_mesh: Node3D = $Head/Camera3D/ShovelPivot/ShovelMesh
@onready var raycast: RayCast3D = $Head/Camera3D/InteractionRayCast3D
@onready var flashlight: SpotLight3D = $Head/Camera3D/FlashlightSpot
@onready var step_audio: AudioStreamPlayer3D = $StepAudio3D

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var bob_time: float = 0.0
var is_swinging_shovel: bool = false
var current_interactable: Area3D = null

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	# Обзор мышью
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clampf(head.rotation.x, deg_to_rad(-80), deg_to_rad(85))

	# Включение / выключение фонарика на [F]
	if event.is_action_pressed("flashlight") or (event is InputEventKey and event.pressed and event.keycode == KEY_F):
		if flashlight:
			flashlight.visible = not flashlight.visible

	# Удар лопатой на ЛКМ или [E]
	if (event.is_action_pressed("interact") or event.is_action_pressed("dig") or 
	   (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)):
		swing_shovel()

func _physics_process(delta: float) -> void:
	# Гравитация
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Ввод передвижения (WASD)
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction != Vector3.ZERO:
		velocity.x = direction.x * walk_speed
		velocity.z = direction.z * walk_speed
		bob_time += delta * bob_frequency
		head.position.y = 1.6 + sin(bob_time) * bob_amplitude
	else:
		velocity.x = move_toward(velocity.x, 0, walk_speed)
		velocity.z = move_toward(velocity.z, 0, walk_speed)
		head.position.y = move_toward(head.position.y, 1.6, delta * 2.0)

	move_and_slide()
	_check_interaction_ray()

func _check_interaction_ray() -> void:
	if not raycast:
		return
		
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider is DigPit3D:
			if current_interactable != collider:
				if current_interactable and current_interactable.has_method("set_player_hover"):
					current_interactable.set_player_hover(false)
				current_interactable = collider
				current_interactable.set_player_hover(true)
			return
			
	if current_interactable:
		if current_interactable.has_method("set_player_hover"):
			current_interactable.set_player_hover(false)
		current_interactable = null

## Анимация удара лопатой (быстрый процедурный замах)
func swing_shovel() -> void:
	if is_swinging_shovel or not shovel_mesh:
		return
		
	is_swinging_shovel = true
	var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Замах и резкий удар вниз в землю
	tween.tween_property(shovel_mesh, "rotation_degrees", Vector3(-45, 20, -30), 0.08)
	tween.tween_property(shovel_mesh, "rotation_degrees", Vector3(10, 0, 0), 0.12)
	
	await tween.finished
	
	# Если перед нами яма — передаем команду копания
	if current_interactable is DigPit3D:
		current_interactable.interact_dig()
		
	is_swinging_shovel = false
