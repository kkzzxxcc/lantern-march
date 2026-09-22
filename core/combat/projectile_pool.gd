class_name ProjectilePool
extends Node2D

var battle
var slots: Array = []
var effects: Array = []

func setup(manager) -> void:
	battle = manager
	for i in int(Data.rules.projectile_cap):
		slots.append({"active": false, "position": Vector2.ZERO, "target": null, "power": 0.0, "ttl": 0.0, "color": Color.WHITE})

func launch(source, target, power: float) -> bool:
	if not is_instance_valid(target) or not target.alive: return false
	for slot in slots:
		if not slot.active:
			slot.active = true
			slot.position = source.position + Vector2(0, -45)
			slot.target = target
			slot.power = power
			slot.ttl = 3.0
			slot.color = Color("f1cc86") if source.team == 0 else Color("de9baf")
			Audio.play("ranged")
			return true
	return false

func has_capacity() -> bool:
	for slot in slots:
		if not slot.active: return true
	return false

func cancel_target(unit) -> void:
	for slot in slots:
		if slot.target == unit:
			slot.active = false
			slot.target = null

func clear() -> void:
	for slot in slots:
		slot.active = false
		slot.target = null
	effects.clear()
	queue_redraw()

func effect(at: Vector2, color: Color, radius: float) -> void:
	if effects.size() < 40:
		effects.append({"position": at + Vector2(0, -25), "color": color, "radius": radius, "life": 0.0})

func tick(delta: float) -> void:
	for slot in slots:
		if not slot.active:
			continue
		slot.ttl -= delta
		var target = slot.target
		if not is_instance_valid(target) or not target.alive or slot.ttl <= 0:
			slot.active = false
			slot.target = null
			continue
		var destination: Vector2 = target.position + Vector2(0, -40)
		slot.position = slot.position.move_toward(destination, 640.0 * delta)
		if slot.position.distance_to(destination) < 12.0:
			target.take_damage(float(slot.power))
			slot.active = false
			slot.target = null
	for index in range(effects.size() - 1, -1, -1):
		effects[index].life += delta
		if effects[index].life >= 0.5:
			effects.remove_at(index)
	queue_redraw()

func _draw() -> void:
	for slot in slots:
		if slot.active:
			draw_circle(slot.position, 6, slot.color)
			draw_circle(slot.position, 11, Color(slot.color, 0.16))
	for item in effects:
		var alpha: float = 1.0 - item.life * 2.0
		draw_arc(item.position, item.radius * (0.35 + item.life), 0, TAU, 40, Color(item.color, alpha * 0.7), 4, true)

