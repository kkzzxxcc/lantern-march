class_name CombatCalculator
extends RefCounted

static func damage(attack: float, defense: float) -> float:
	return maxf(1.0, attack - defense)

