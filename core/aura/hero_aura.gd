class_name HeroAura
extends Node2D

var battle
var radius := 215.0
var elapsed := 0.0
var affected: Array = []

func tick(delta: float) -> void:
	if not is_instance_valid(battle.hero):
		return
	position = battle.hero.position
	radius = (float(Data.rules.aura.range) + float(battle.equipment_mods.get("aura_range", 0.0))) * (1.0 + float(battle.battle_modifiers.get("aura_range", 0.0)))
	elapsed -= delta
	if elapsed <= 0:
		elapsed = float(Data.rules.aura_interval)
		update_membership()
	queue_redraw()

func update_membership() -> void:
	var next: Array = battle.registry.nearby(position.x, radius, 0)
	for unit in affected:
		if is_instance_valid(unit) and not next.has(unit):
			unit.aura_active = false
	affected.clear()
	for unit in next:
		if not unit.is_hero and not unit.is_base:
			unit.aura_active = true
			affected.append(unit)

func remove(unit) -> void:
	unit.aura_active = false
	affected.erase(unit)

func clear() -> void:
	for unit in affected:
		if is_instance_valid(unit):
			unit.aura_active = false
	affected.clear()

func _draw() -> void:
	draw_set_transform(Vector2(0, 8), 0, Vector2(1, 0.27))
	draw_circle(Vector2.ZERO, radius, Color(0.38, 0.8, 0.7, 0.065))
	draw_arc(Vector2.ZERO, radius, 0, TAU, 96, Color(0.52, 0.87, 0.73, 0.48), 2.0, true)
	draw_arc(Vector2.ZERO, radius - 8, 0, TAU, 96, Color(0.52, 0.87, 0.73, 0.12), 1.0, true)

