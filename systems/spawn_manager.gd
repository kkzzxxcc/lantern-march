class_name SpawnManager
extends RefCounted

var battle
var elapsed := 0.0
var timer := 4.0
var boss_spawned := false
var rng := RandomNumberGenerator.new()

func setup(manager) -> void:
	battle = manager
	timer = float(battle.stage.spawn_start)
	rng.randomize()

func tick(delta: float) -> void:
	elapsed += delta
	timer -= delta
	if battle.stage.boss != "" and not boss_spawned and elapsed >= float(battle.stage.boss_time):
		var boss = battle.spawn_enemy(battle.stage.boss)
		if boss != null:
			boss_spawned = true
			battle.announce(battle.stage.name + " — the guardian arrives")
	if timer > 0:
		return
	timer = float(battle.stage.spawn_interval)
	var eligible: Array = []
	var weight := 0.0
	for entry in battle.stage.spawns:
		if elapsed >= float(entry.start):
			eligible.append(entry)
			weight += float(entry.weight)
	var roll := rng.randf_range(0, weight)
	for entry in eligible:
		roll -= float(entry.weight)
		if roll <= 0:
			battle.spawn_enemy(entry.id)
			break

