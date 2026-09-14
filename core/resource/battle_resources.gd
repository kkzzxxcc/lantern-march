class_name BattleResources
extends RefCounted

var supply := 45.0
var mana := 50.0
var infinite_supply := false
var infinite_mana := false
var mods: Dictionary = {}
var upgrades: Dictionary = {}

func setup(equipment: Dictionary, battle_upgrades: Dictionary) -> void:
	supply = float(Data.rules.supply_start)
	mana = float(Data.rules.mana_start)
	mods = equipment
	upgrades = battle_upgrades

func tick(delta: float) -> void:
	supply = minf(float(Data.rules.supply_max), supply + delta * (float(Data.rules.supply_recovery) + float(mods.get("supply_recovery", 0))) * (1.0 + float(upgrades.get("supply_recovery", 0))))
	mana = minf(float(Data.rules.mana_max), mana + delta * (float(Data.rules.mana_recovery) + float(mods.get("mana_recovery", 0))) * (1.0 + float(upgrades.get("mana_recovery", 0))))
	if infinite_supply:
		supply = float(Data.rules.supply_max)
	if infinite_mana:
		mana = float(Data.rules.mana_max)

func spend_supply(cost: float) -> bool:
	if not infinite_supply and supply < cost:
		return false
	if not infinite_supply:
		supply -= cost
	return true

func spend_mana(cost: float) -> bool:
	if not infinite_mana and mana < cost:
		return false
	if not infinite_mana:
		mana -= cost
	return true

