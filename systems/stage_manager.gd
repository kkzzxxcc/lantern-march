class_name StageManager
extends RefCounted

static func objective(stage: Dictionary) -> String:
	return "Defeat the guardian" if stage.mode == "boss" else "Break the hollow gate"

static func result_for_death(stage: Dictionary, unit) -> String:
	if unit.is_hero or (unit.is_base and unit.team == 0 and stage.defend_base):
		return "defeat"
	if stage.mode == "boss" and unit.stats.role == "boss":
		return "victory"
	if stage.mode == "normal" and unit.is_base and unit.team == 1:
		return "victory"
	return ""

