extends CanvasLayer
## HUD уровня: индикатор глубины сна и подсказка о последней находке.

@onready var dream_label: Label = $Margin/VBox/DreamLabel
@onready var dream_bar: ProgressBar = $Margin/VBox/DreamBar
@onready var item_label: Label = $Margin/VBox/ItemLabel

func _ready() -> void:
	DreamManager.dream_depth_changed.connect(_on_dream_depth_changed)
	InventoryManager.item_added.connect(_on_item_added)
	_on_dream_depth_changed(DreamManager.dream_depth)
	item_label.visible = false

func _on_dream_depth_changed(new_depth: int) -> void:
	dream_bar.value = new_depth
	dream_label.text = "Глубина сна: %d%%" % new_depth

func _on_item_added(item: ItemData) -> void:
	item_label.text = "Найдено: %s" % item.item_name
	item_label.visible = true
	var tween = create_tween()
	tween.tween_interval(2.5)
	tween.tween_callback(func(): item_label.visible = false)
