class_name BossUnit
extends UnitBase

var phase := 1
var skill_timer := 5.0

func tick(delta: float) -> void:
	super.tick(delta)
	if not alive:
		return
	var config: Dictionary = stats.boss
	if phase == 1 and hp / max_hp <= float(config.threshold):
		phase = 2
		stats.attack_speed *= 1.35
		stats.move_speed *= 1.25
		battle.announce(stats.name + " awakens — phase II")
		battle.effect(position, Color(stats.color), 280)
	skill_timer -= delta
	if skill_timer <= 0:
		skill_timer = float(config.cooldown) / (1.25 if phase == 2 else 1.0)
		if config.skill == "summon":
			for offset in [-50, 50]:
				battle.spawn_enemy(config.summon, position.x + offset)
		else:
			battle.area_attack(position.x - 100.0, float(config.radius), float(config.power) * phase, team)

