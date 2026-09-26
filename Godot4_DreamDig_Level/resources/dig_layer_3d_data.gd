class_name DigLayer3DData
extends Resource
## 3D ресурс слоя раскопок для Godot 4.
## Настраивается в FileSystem -> New Resource -> DigLayer3DData.

@export var layer_name: String = "Слой серого дёрна"
@export var hits_required: int = 4
@export var soil_material: Material ## Стандартный или PSX шейдерный материал
@export var particle_color: Color = Color("44403c")
@export var dig_sound: AudioStream
@export var unlocked_item: ItemData ## Предмет, выкапываемый на этом слое
