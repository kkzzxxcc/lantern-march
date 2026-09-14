class_name UnitBase
extends Node2D

signal died(unit)
var battle
var stats: Dictionary = {}
var team := 0
var hp := 100.0
var max_hp := 100.0
var alive := true
var is_hero := false
var is_base := false
var target = null
var attack_timer := 0.0
var search_timer := 0.0
var aura_active := false
var support_time := 0.0
var flash := 0.0
var motion := 0.0
var attack_pose := 0.0
var radius := 22.0
var visual: UnitVisual
var invincible := false
var support_anchor := 320.0

func configure(data: Dictionary, side: int, manager, at: Vector2) -> void:
	stats = data.duplicate(true)
	team = side
	battle = manager
	position = at
	max_hp = float(stats.hp)
	hp = max_hp
	is_base = stats.role == "base"
	is_hero = stats.role == "hero"
	radius = 50.0 if is_base else (36.0 if stats.role in ["tank", "siege", "boss"] else 22.0)
	search_timer = fmod(float(get_instance_id()), 17.0) / 100.0
	visual = UnitVisual.new()
	visual.unit = self
	add_child(visual)

func stat(key: String) -> float:
	var value := float(stats.get(key, 0.0))
	if aura_active and Data.rules.aura.has(key):
		value *= 1.0 + float(Data.rules.aura[key])
	if support_time > 0 and key in ["attack", "attack_speed"]:
		value *= 1.15
	if team == 0 and key == "attack":
		value *= 1.0 + float(battle.battle_modifiers.get("attack", 0.0))
	return value

func tick(delta: float) -> void:
	if not alive:
		return
	flash = maxf(0.0, flash - delta)
	attack_pose = maxf(0.0, attack_pose - delta * 4.0)
	support_time = maxf(0.0, support_time - delta)
	attack_timer = maxf(0.0, attack_timer - delta)
	if is_base:
		visual.queue_redraw()
		return
	search_timer -= delta
	if search_timer <= 0:
		search_timer = float(Data.rules.target_interval)
		target = battle.registry.find_target(self)
	if not is_instance_valid(target) or not target.alive:
		target = null
	var in_range: bool = target != null and edge_distance(target) <= stat("attack_range")
	if is_hero:
		move_hero(delta)
	elif stats.attack_type in ["heal", "buff"]:
		move_support(delta)
	elif not in_range:
		position.x += (1.0 if team == 0 else -1.0) * stat("move_speed") * delta
		position.x = clampf(position.x, 115.0, float(battle.stage.length) - 115.0)
		motion += delta * stat("move_speed") / 12.0
	if target != null and edge_distance(target) <= stat("attack_range") and attack_timer <= 0.0:
		attack(target)
	visual.queue_redraw()

func move_hero(_delta: float) -> void:
	pass

func edge_distance(other) -> float:
	return maxf(0.0, absf(other.position.x - position.x) - radius - other.radius)

func attack(victim) -> void:
	if not alive or not is_instance_valid(victim) or not victim.alive:
		return
	if edge_distance(victim) > stat("attack_range") or stat("attack_speed") <= 0:
		return
	attack_timer = 1.0 / stat("attack_speed")
	attack_pose = 1.0
	var power := stat("attack")
	match stats.attack_type:
		"melee":
			victim.take_damage(power)
		"projectile":
			if victim.is_base:
				power *= float(stats.get("base_multiplier", 1.0))
			if not battle.projectiles.launch(self, victim, power):
				attack_timer = minf(attack_timer, 0.1)
		"area":
			battle.area_attack(victim.position.x, float(stats.get("area_radius", 100)), power, team)
		"heal":
			victim.heal(power)
			battle.effect(victim.position, Color("91d7cd"), 60.0)
		"buff":
			victim.support_time = 4.0
			battle.effect(victim.position, Color("bba7cf"), 60.0)

func take_damage(power: float) -> void:
	if not alive or invincible:
		return
	hp = maxf(0.0, hp - CombatCalculator.damage(power, stat("defense")))
	flash = 0.12
	if hp <= 0:
		die()

func heal(amount: float) -> void:
	if alive:
		hp = minf(max_hp, hp + amount)
		flash = 0.06

func die() -> void:
	if not alive:
		return
	alive = false
	died.emit(self)
	queue_free()


# Support positioning is independent of whether anyone currently needs healing.
func move_support(delta: float) -> void:
	var direction := 1.0 if team == 0 else -1.0
	if search_timer >= float(Data.rules.target_interval) - 0.001:
		var anchor := position.x
		var found := false
		for ally in battle.registry.nearby(position.x, 700.0, team):
			if ally == self or ally.is_base or ally.stats.attack_type in ["heal", "buff"]: continue
			if not found or ally.position.x * direction > anchor * direction:
				anchor = ally.position.x
				found = true
		support_anchor = anchor - direction * 110.0 if found else position.x
	# Recheck the local opposing front each tick so moving enemies cannot be crossed.
	var desired := support_anchor
	for enemy in battle.registry.nearby(position.x, 700.0, 1 - team):
		var boundary: float = enemy.position.x - direction * (radius + enemy.radius + 90.0)
		desired = minf(desired, boundary) if team == 0 else maxf(desired, boundary)
	var previous := position.x
	position.x = move_toward(position.x, clampf(desired, 115.0, float(battle.stage.length)-115.0), stat("move_speed") * delta)
	motion += absf(position.x - previous) / 12.0
