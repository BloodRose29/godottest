class_name DigPit3D
extends Area3D
## 3D контроллер ямы во дворе для Godot 4 (3D).
## Крепится к корневому узлу: Area3D (сцена DigPit3D.tscn).
## Обеспечивает послойное физическое углубление ямы, брызги почвы и выдачу реликвий.

signal layer_completed(layer_index: int, layer_name: String)
signal item_unearthed(item: ItemData)
signal dig_hit_performed(hits_left_in_layer: int)

@export_group("Настройки слоев")
@export var layers: Array[DigLayer3DData] = []
@export var current_layer_index: int = 0
@export var depth_step_meters: float = 0.55 ## На сколько метров дно опускается на каждом слое

@export_group("3D узлы геометрии и эффектов")
@onready var pit_mesh: MeshInstance3D = $PitHoleMesh
@onready var pit_bottom: Node3D = $PitBottomMarker
@onready var soil_particles: GPUParticles3D = $SoilParticles3D
@onready var dig_audio: AudioStreamPlayer3D = $DigAudio3D
@onready var find_audio: AudioStreamPlayer3D = $FindAudio3D
@onready var prompt_3d: Label3D = $PromptLabel3D
@onready var item_spawn_point: Marker3D = $ItemSpawnPoint3D

var hits_remaining: int = 0
var is_player_focused: bool = false
var is_locked: bool = false

func _ready() -> void:
	# Слой коллизии 2 (Interactable)
	collision_layer = 2
	collision_mask = 1
	
	if prompt_3d:
		prompt_3d.visible = false
		
	_setup_current_layer()

func _setup_current_layer() -> void:
	if current_layer_index >= layers.size():
		if prompt_3d:
			prompt_3d.text = "Дно ямы. Почва больше не поддаётся."
			prompt_3d.visible = true
		return
		
	var layer: DigLayer3DData = layers[current_layer_index]
	hits_remaining = layer.hits_required
	
	# Применяем материал почвы (пепел, черные корни, сырая плоть) к мешу ямы
	if layer.soil_material and pit_mesh:
		pit_mesh.material_override = layer.soil_material
		
	# Настраиваем цвет 3D частиц почвы
	if soil_particles and soil_particles.process_material is ParticleProcessMaterial:
		var mat = soil_particles.process_material as ParticleProcessMaterial
		mat.color = layer.particle_color
		
	_update_prompt_text()

## Вызывается игроком при нажатии ЛКМ / кнопки удара лопаты в сторону ямы
func interact_dig() -> void:
	if is_locked or current_layer_index >= layers.size():
		return
		
	var layer: DigLayer3DData = layers[current_layer_index]
	hits_remaining -= 1
	
	_play_dig_effects(layer)
	dig_hit_performed.emit(hits_remaining)
	
	if hits_remaining <= 0:
		_complete_layer(layer)
	else:
		_update_prompt_text()

func _play_dig_effects(layer: DigLayer3DData) -> void:
	# 1. Отдача и дрожание меша ямы
	var tween = create_tween()
	var original_pos = pit_mesh.position
	tween.tween_property(pit_mesh, "position:y", original_pos.y - 0.08, 0.04)
	tween.tween_property(pit_mesh, "position:y", original_pos.y, 0.08)
	
	# 2. Запуск 3D частиц летящей земли
	if soil_particles:
		soil_particles.restart()
		soil_particles.emitting = true
		
	# 3. Позиционированный 3D звук
	if dig_audio and layer.dig_sound:
		dig_audio.stream = layer.dig_sound
		dig_audio.pitch_scale = randf_range(0.88, 1.12)
		dig_audio.play()

func _complete_layer(layer: DigLayer3DData) -> void:
	layer_completed.emit(current_layer_index, layer.layer_name)
	
	# Плавное физическое углубление ямы в 3D вниз
	var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var target_y = -((current_layer_index + 1) * depth_step_meters)
	tween.tween_property(pit_bottom, "position:y", target_y, 0.8)
	
	# Если на слое лежит сюжетный артефакт — поднимаем его наверх
	if layer.unlocked_item:
		_unearth_item_3d(layer.unlocked_item)
		
	current_layer_index += 1
	_setup_current_layer()

func _unearth_item_3d(item: ItemData) -> void:
	if find_audio and find_audio.stream:
		find_audio.play()
		
	# Если задана 3D модель предмета — спавним её с вращением
	if item.item_3d_scene:
		var spawned = item.item_3d_scene.instantiate() as Node3D
		add_child(spawned)
		spawned.global_position = pit_bottom.global_position
		
		var lift_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		lift_tween.tween_property(spawned, "global_position", item_spawn_point.global_position, 1.2)
		lift_tween.parallel().tween_property(spawned, "rotation_degrees:y", 360.0, 1.2)
		
	InventoryManager.add_item(item)
	item_unearthed.emit(item)
	DreamManager.advance_dream_state(item.dream_shift_amount)
	
	is_locked = true
	await get_tree().create_timer(1.2).timeout
	is_locked = false

func _update_prompt_text() -> void:
	if not prompt_3d:
		return
	if current_layer_index >= layers.size():
		prompt_3d.text = "Дно ямы."
		return
	var layer = layers[current_layer_index]
	prompt_3d.text = "[E / ЛКМ] Копать: %s\nОсталось ударов: %d" % [layer.layer_name, hits_remaining]

## Вызывается лучом игрока (RayCast3D)
func set_player_hover(is_hovered: bool) -> void:
	is_player_focused = is_hovered
	if prompt_3d:
		prompt_3d.visible = is_hovered
