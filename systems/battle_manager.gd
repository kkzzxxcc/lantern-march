class_name BattleManager
extends Node2D

signal ended(result: String, reward: Dictionary)
signal announcement(message: String)
signal upgrade_offered(choices: Array)
var stage: Dictionary = {}
var registry := CombatRegistry.new()
var resources := BattleResources.new()
var spawner := SpawnManager.new()
var projectiles: ProjectilePool
var aura: HeroAura
var hero: HeroController
var player_base: UnitBase
var enemy_base: UnitBase
var camera: Camera2D
var actors: Node2D
var status := "running"
var elapsed := 0.0
var cooldowns: Dictionary = {}
var skill_cooldowns: Array[float] = [0.0, 0.0, 0.0]
var equipment_mods: Dictionary = {}
var battle_modifiers: Dictionary = {}
var battle_exp := 0.0
var battle_level := 1
var pending_choices: Array = []
var hud
var presentation_enabled := true
var ground_y := 490.0
var speed := 1.0
var last_reward: Dictionary = {}
var roster: Array = []
var hits_audio_timer := 0.0

func _ready() -> void:
	if stage.is_empty():
		stage = Data.stages[0].duplicate(true)
	roster = Data.roster()
	equipment_mods = Save.equipment_modifiers()
	resources.setup(equipment_mods, battle_modifiers)
	registry.bucket_size = float(Data.rules.spatial_bucket)
	var ground := BattleGround.new()
	ground.length = float(stage.length)
	add_child(ground)
	aura = HeroAura.new()
	aura.battle = self
	add_child(aura)
	actors = Node2D.new()
	actors.name = "Actors"
	add_child(actors)
	projectiles = ProjectilePool.new()
	projectiles.name = "ProjectilePool"
	projectiles.setup(self)
	add_child(projectiles)
	player_base = _spawn(_base_data(float(stage.player_base_hp)), 0, 100)
	enemy_base = _spawn(_base_data(float(stage.enemy_base_hp)), 1, float(stage.length)-100)
	if stage.mode == "boss":
		enemy_base.invincible = true
	var hero_data: Dictionary = Data.rules.hero.duplicate(true)
	hero_data.hp += (int(Save.state.hero_level)-1)*25
	hero_data.attack += (int(Save.state.hero_level)-1)*3
	for key in ["hp", "attack", "defense", "attack_speed"]:
		hero_data[key] += float(equipment_mods.get(key, 0))
	hero = _spawn(hero_data, 0, 320)
	camera = Camera2D.new()
	camera.name = "Camera2D"
	camera.position = Vector2(640, 360)
	add_child(camera)
	camera.make_current()
	spawner.setup(self)
	registry.rebuild()
	aura.tick(0.2)
	if presentation_enabled:
		var layer := CanvasLayer.new()
		layer.name = "Interface"
		add_child(layer)
		hud = BattleHUD.new()
		hud.battle = self
		layer.add_child(hud)

func _base_data(health: float) -> Dictionary:
	return {"id":"gate", "name":"Lantern Gate", "role":"base", "hp":health, "attack":0, "defense":3, "attack_speed":0, "move_speed":0, "attack_range":0, "attack_type":"melee", "color":"#acb995"}

func _spawn(data: Dictionary, team: int, x: float):
	var unit
	if data.role == "hero":
		unit = HeroController.new()
	elif data.role == "boss":
		unit = BossUnit.new()
	else:
		unit = UnitBase.new()
	unit.configure(data, team, self, Vector2(x, ground_y))
	if team == 1 and data.role == "base":
		unit.stats.color = "#b38f91"
	actors.add_child(unit)
	registry.register(unit)
	unit.died.connect(_on_death)
	return unit

func team_count(team: int) -> int:
	var count := 0
	for unit in registry.entities:
		if unit.team == team and not unit.is_base and not unit.is_hero:
			count += 1
	return count

func summon(index: int) -> bool:
	if status != "running" or index < 0 or index >= roster.size():
		return false
	var id: String = roster[index]
	var data: Dictionary = Data.units[id].duplicate(true)
	if float(cooldowns.get(id, 0.0)) > 0 or team_count(0) >= int(Data.rules.friendly_cap) or registry.entities.size() >= int(Data.rules.entity_cap):
		return false
	if not resources.spend_supply(float(data.supply_cost)):
		return false
	var level := int(Save.state.unit_levels.get(id, 1))
	data.hp += (level - 1) * 20
	data.attack += (level - 1) * 5
	_spawn(data, 0, 175)
	cooldowns[id] = float(data.spawn_cooldown)
	Audio.play("summon")
	return true

func spawn_enemy(id: String, x: float = -1.0):
	if status != "running" or not Data.enemies.has(id) or registry.entities.size() >= int(Data.rules.entity_cap):
		return null
	if team_count(1) >= int(Data.rules.enemy_cap):
		return null
	return _spawn(Data.enemies[id], 1, float(stage.length)-175.0 if x < 0 else x)

func _physics_process(delta: float) -> void:
	simulate(delta * speed)

func simulate(delta: float) -> void:
	if status != "running":
		return
	elapsed += delta
	hits_audio_timer -= delta
	resources.tick(delta)
	for id in cooldowns:
		cooldowns[id] = maxf(0, cooldowns[id] - delta)
	for i in skill_cooldowns.size():
		skill_cooldowns[i] = maxf(0, skill_cooldowns[i] - delta)
	spawner.tick(delta)
	registry.tick(delta, float(Data.rules.spatial_interval))
	aura.tick(delta)
	for unit in registry.entities.duplicate():
		if status != "running":
			break
		if is_instance_valid(unit) and unit.alive:
			unit.tick(delta)
	if status == "running":
		projectiles.tick(delta)
	if is_instance_valid(hero):
		var visible_size := get_viewport_rect().size
		var half := visible_size.x / 2
		camera.position.x = clampf(hero.position.x + 240.0, half, maxf(half,float(stage.length)-half))
		camera.position.y = 360.0

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if status in ["running", "paused"]:
			status = "paused" if status == "running" else "running"
			if hud != null:
				hud.show_pause(status == "paused")
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("debug_toggle") and OS.is_debug_build() and hud != null:
		hud.toggle_debug()
	if status != "running":
		return
	for i in mini(6, roster.size()):
		if event.is_action_pressed("summon_unit_%d" % (i+1)):
			summon(i)
	for i in 3:
		if event.is_action_pressed("skill_%d" % (i+1)):
			cast_skill(i)

func cast_skill(index: int) -> bool:
	if status != "running" or index < 0 or index >= Data.skills.size() or skill_cooldowns[index] > 0 or not is_instance_valid(hero):
		return false
	var skill: Dictionary = Data.skills[index]
	var target = null
	if skill.type == "projectile":
		var nearest := INF
		for unit in registry.nearby(hero.position.x, float(skill.range), 1):
			var distance: float = unit.position.x - hero.position.x
			if distance >= -40 and distance < nearest:
				nearest = distance
				target = unit
		if target == null:
			announce("No enemy in Sunbolt range")
			return false
	if skill.type == "projectile" and not projectiles.has_capacity():
		return false
	if not resources.spend_mana(float(skill.mana_cost)):
		return false
	skill_cooldowns[index] = float(skill.cooldown)
	match skill.type:
		"projectile":
			projectiles.launch(hero, target, float(skill.power) + hero.stat("attack"))
		"area":
			area_attack(hero.position.x + float(skill.range)*0.6, float(skill.radius), float(skill.power), 0)
		"heal":
			for unit in registry.nearby(hero.position.x, float(skill.radius), 0):
				if not unit.is_base:
					unit.heal(float(skill.power))
			effect(hero.position, Color("91d7cd"), float(skill.radius))
	Audio.play("skill")
	return true

func area_attack(x: float, radius: float, power: float, team: int) -> void:
	for unit in registry.nearby(x, radius, 1-team):
		unit.take_damage(power)
	effect(Vector2(x, ground_y), Color("e7b77b") if team == 0 else Color("d499b2"), radius)

func effect(at: Vector2, color: Color, radius: float) -> void:
	projectiles.effect(at, color, radius)

func announce(message: String) -> void:
	announcement.emit(message)

func _on_death(unit) -> void:
	registry.unregister(unit)
	aura.remove(unit)
	projectiles.cancel_target(unit)
	if hits_audio_timer <= 0:
		Audio.play("hit")
		hits_audio_timer = 0.12
	var result := StageManager.result_for_death(stage, unit)
	if result != "":
		finish(result)
	elif unit.team == 1 and status in ["running", "choosing"]:
		battle_exp += float(unit.stats.get("exp", 10))
		_check_battle_level()

func _check_battle_level() -> void:
	var threshold: float = Data.rules.battle_exp_base * battle_level
	if battle_exp < threshold or status != "running":
		return
	battle_exp -= threshold
	battle_level += 1
	pending_choices = Data.rules.battle_upgrades.duplicate(true)
	pending_choices.shuffle()
	pending_choices = pending_choices.slice(0, 3)
	status = "choosing"
	upgrade_offered.emit(pending_choices)

func choose_upgrade(index: int) -> bool:
	if status != "choosing" or index < 0 or index >= pending_choices.size():
		return false
	var option: Dictionary = pending_choices[index]
	battle_modifiers[option.stat] = float(battle_modifiers.get(option.stat, 0)) + float(option.value)
	pending_choices.clear()
	status = "running"
	_check_battle_level()
	return true

func finish(result: String) -> void:
	if status in ["victory", "defeat"]:
		return
	status = result
	aura.clear()
	projectiles.clear()
	Input.action_release("move_left")
	Input.action_release("move_right")
	if result == "victory":
		last_reward = Save.reward_stage(stage)
	Audio.play(result)
	ended.emit(result, last_reward)

func debug_command(command: String) -> void:
	if not OS.is_debug_build():
		return
	match command:
		"gold":
			Save.state.gold += 1000
			Save.save_game()
		"supply": resources.infinite_supply = not resources.infinite_supply
		"mana": resources.infinite_mana = not resources.infinite_mana
		"invincible":
			if is_instance_valid(hero): hero.invincible = not hero.invincible
		"clear": finish("victory")
		"kill":
			for unit in registry.entities.duplicate():
				if unit.team == 1 and not unit.is_base: unit.die()
		"speed": speed = 2.0 if speed == 1.0 else (4.0 if speed == 2.0 else 1.0)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and status == "running":
		status = "paused"
		Input.action_release("move_left")
		Input.action_release("move_right")
		if hud != null: hud.show_pause(true)

func _exit_tree() -> void:
	if is_instance_valid(aura): aura.clear()
	if is_instance_valid(projectiles): projectiles.clear()
	Input.action_release("move_left")
	Input.action_release("move_right")

