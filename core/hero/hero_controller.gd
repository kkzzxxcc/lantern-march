class_name HeroController
extends UnitBase

func move_hero(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	position.x = clampf(position.x + direction * stat("move_speed") * delta, 125.0, float(battle.stage.length) - 140.0)
	if direction != 0:
		motion += delta * stat("move_speed") / 18.0

