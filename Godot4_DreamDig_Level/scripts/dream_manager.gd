extends Node
## Autoload: DreamManager
## Управляет погружением в лимб сна (0% - 100%).

signal dream_depth_changed(new_depth: int)
signal finale_triggered

var dream_depth: int = 0:
	set(value):
		dream_depth = clampi(value, 0, 100)
		dream_depth_changed.emit(dream_depth)
		if dream_depth >= 100:
			finale_triggered.emit()

func advance_dream_state(amount: int) -> void:
	dream_depth += amount
