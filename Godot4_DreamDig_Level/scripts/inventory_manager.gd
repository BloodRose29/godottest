extends Node
## Autoload: InventoryManager
## Централизованное хранилище выкопанных артефактов деревни снов.

signal item_added(item: ItemData)
signal item_removed(item: ItemData)

var items: Array[ItemData] = []

func add_item(item: ItemData) -> void:
	if item == null:
		return
	items.append(item)
	item_added.emit(item)

func remove_item(item: ItemData) -> void:
	var idx = items.find(item)
	if idx != -1:
		items.remove_at(idx)
		item_removed.emit(item)

func has_item(item_id: String) -> bool:
	for it in items:
		if it.id == item_id:
			return true
	return false

func get_item_for_npc(npc_id: String) -> ItemData:
	for it in items:
		if it.target_npc_id == npc_id:
			return it
	return null
