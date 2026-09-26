class_name ItemData
extends Resource
## Сюжетный предмет, извлеченный из 3D ямы снов.

@export var id: String = ""
@export var item_name: String = "Забытая вещь"
@export_multiline var surreal_description: String = ""
@export_multiline var flavor_quote: String = ""
@export var icon: Texture2D
@export var item_3d_scene: PackedScene ## Low-poly 3D меш артефакта
@export var target_npc_id: String = "" ## Кому принадлежит вещь ("marfa", "blacksmith", "boatman")
@export_range(5, 50, 5) var dream_shift_amount: int = 25
