class_name BattleHUD
extends Control

var battle
var hp_label: Label
var supply_label: Label
var mana_label: Label
var progress: Label
var message: Label
var unit_buttons: Array = []
var skill_buttons: Array = []
var overlay: Control
var overlay_box: VBoxContainer
var debug_box: PanelContainer
var debug_label: Label
var refresh := 0.0
var message_time := 0.0

func _ready() -> void:
	UIKit.fill(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UIKit.theme()
	var margin := SafeMargin.new()
	UIKit.fill(margin)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)
	var layout := VBoxContainer.new()
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(layout)
	var top := HBoxContainer.new()
	layout.add_child(top)
	var identity := VBoxContainer.new()
	top.add_child(identity)
	identity.add_child(UIKit.label(tr("LANTERN MARCH"),16,UIKit.GOLD))
	identity.add_child(UIKit.label("%02d  /  %s" % [battle.stage.id,tr(battle.stage.name)],22))
	top.add_child(UIKit.spacer())
	for kind in ["KEEPER", "SUPPLY", "MANA"]:
		var panel := UIKit.panel()
		panel.custom_minimum_size.x = 138
		top.add_child(panel)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation",1)
		panel.add_child(box)
		box.add_child(UIKit.label(tr(kind),12,UIKit.MUTED))
		var number := UIKit.label("",22)
		box.add_child(number)
		match kind:
			"KEEPER": hp_label = number
			"SUPPLY": supply_label = number
			"MANA": mana_label = number
	var pause_button := _action("II", "pause", Vector2(54,54))
	top.add_child(pause_button)
	progress = UIKit.label(StageManager.objective(battle.stage),15,UIKit.MUTED)
	progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(progress)
	message = UIKit.label(tr("Keep your companions inside the lantern aura."),18,UIKit.GOLD)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(message)
	message_time = 8.0
	layout.add_child(UIKit.spacer())
	var hint := UIKit.label(tr("A / D  MOVE     •     1–6  SUMMON     •     J / K / L  SKILLS     •     ESC  PAUSE"),13,UIKit.MUTED)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(hint)
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation",8)
	layout.add_child(bottom)
	bottom.add_child(_action("‹", "move_left", Vector2(64,90)))
	bottom.add_child(_action("›", "move_right", Vector2(64,90)))
	for i in battle.roster.size():
		var data: Dictionary = Data.units[battle.roster[i]]
		var button := _action("", "summon_unit_%d" % (i+1),Vector2(86,90))
		button.add_theme_font_size_override("font_size",14)
		button.tooltip_text = tr(data.name)+"\n"+tr(data.description)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bottom.add_child(button)
		unit_buttons.append(button)
	for i in 3:
		var button := _action("", "skill_%d" % (i+1),Vector2(106,90))
		button.add_theme_font_size_override("font_size",14)
		button.tooltip_text = tr(Data.skills[i].description)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bottom.add_child(button)
		skill_buttons.append(button)
	_build_overlay()
	battle.ended.connect(_on_ended)
	battle.announcement.connect(func(text): message.text=text; message_time=5.0)
	battle.upgrade_offered.connect(_offer_upgrade)
	_update()

func _action(text: String, action: String, minimum: Vector2) -> ActionButton:
	var button := ActionButton.new()
	button.text = text
	button.action = action
	button.custom_minimum_size = minimum
	return button

func _process(delta: float) -> void:
	refresh -= delta
	message_time -= delta
	if refresh <= 0:
		refresh = 0.1
		_update()
	if message_time <= 0 and message.text != "": message.text=""

func _update() -> void:
	if is_instance_valid(battle.hero): hp_label.text="%d / %d" % [battle.hero.hp,battle.hero.max_hp]
	supply_label.text="%d / 100" % battle.resources.supply
	mana_label.text="%d / 100" % battle.resources.mana
	var gate_hp: float = battle.enemy_base.hp if is_instance_valid(battle.enemy_base) else 0
	progress.text=tr("%s    •    Gate %d    •    Battle Lv.%d    •    %02d:%02d") % [StageManager.objective(battle.stage),gate_hp,battle.battle_level,int(battle.elapsed)/60,int(battle.elapsed)%60]
	for i in unit_buttons.size():
		var data: Dictionary = Data.units[battle.roster[i]]
		var cd: float = battle.cooldowns.get(data.id,0)
		unit_buttons[i].text=tr("%d  %s\n%s\n%d supply") % [i+1,tr(data.name),tr("%.1fs") % cd if cd>0 else tr(data.role.to_upper()),data.supply_cost]
		unit_buttons[i].disabled=battle.status!="running" or cd>0 or (battle.resources.supply<data.supply_cost and not battle.resources.infinite_supply) or battle.team_count(0)>=int(Data.rules.friendly_cap)
	for i in 3:
		var data: Dictionary=Data.skills[i]
		var cd: float=battle.skill_cooldowns[i]
		skill_buttons[i].text=tr("%s  %s\n%s\n%d mana") % [data.key,tr(data.name),tr("%.1fs") % cd if cd>0 else tr(data.type.to_upper()),data.mana_cost]
		skill_buttons[i].disabled=battle.status!="running" or cd>0 or (battle.resources.mana<data.mana_cost and not battle.resources.infinite_mana)
	if debug_label!=null:
		debug_label.text=tr("FPS %d  /  entities %d  /  %.0fx\nSupply %s  Mana %s  Invincible %s") % [Engine.get_frames_per_second(),battle.registry.entities.size(),battle.speed,tr("On") if battle.resources.infinite_supply else tr("Off"),tr("On") if battle.resources.infinite_mana else tr("Off"),tr("On") if is_instance_valid(battle.hero) and battle.hero.invincible else tr("Off")]

func _build_overlay() -> void:
	overlay=Control.new()
	UIKit.fill(overlay)
	add_child(overlay)
	var shade:=ColorRect.new()
	shade.color=Color(0.02,0.07,0.09,0.88)
	UIKit.fill(shade)
	overlay.add_child(shade)
	var center:=CenterContainer.new()
	UIKit.fill(center)
	overlay.add_child(center)
	var panel:=UIKit.panel()
	panel.custom_minimum_size=Vector2(530,0)
	center.add_child(panel)
	overlay_box=VBoxContainer.new()
	overlay_box.add_theme_constant_override("separation",16)
	panel.add_child(overlay_box)
	overlay.hide()

func _clear_overlay() -> void:
	for child in overlay_box.get_children():
		overlay_box.remove_child(child)
		child.queue_free()
	overlay.show()

func show_pause(paused: bool) -> void:
	if not paused:
		overlay.hide()
		return
	_clear_overlay()
	overlay_box.add_child(UIKit.label(tr("THE LIGHT CAN WAIT"),32,UIKit.GOLD))
	overlay_box.add_child(UIKit.label(tr("Journey paused"),18,UIKit.MUTED))
	overlay_box.add_child(UIKit.button(tr("Continue"),func(): battle.status="running"; overlay.hide()))
	overlay_box.add_child(UIKit.button(tr("Restart stage"),func(): _router().start_battle(battle.stage.id)))
	overlay_box.add_child(UIKit.button(tr("Return to the map"),func(): _router().show_screen("stage_select")))

func _offer_upgrade(choices: Array) -> void:
	_clear_overlay()
	overlay_box.add_child(UIKit.label(tr("A BRIGHTER FLAME"),32,UIKit.GOLD))
	overlay_box.add_child(UIKit.label(tr("Battle level %d  •  Choose one blessing") % battle.battle_level,18,UIKit.MUTED))
	for i in choices.size():
		var option: Dictionary=choices[i]
		overlay_box.add_child(UIKit.button(tr(option.name)+"\n"+tr(option.description),func(): overlay.hide(); battle.choose_upgrade(i),Vector2(500,70)))

func _on_ended(result: String, reward: Dictionary) -> void:
	_clear_overlay()
	overlay_box.add_child(UIKit.label(tr("THE ROAD IS OPEN") if result=="victory" else tr("THE LIGHT FADES"),36,UIKit.GOLD))
	overlay_box.add_child(UIKit.label(tr(battle.stage.name),20))
	if result=="victory" and not reward.get("saved", true):
		overlay_box.add_child(UIKit.label(tr("Reward not saved. Please retry before leaving."),18,Color("e5a2a2")))
		overlay_box.add_child(UIKit.button(tr("Retry saving reward"),func(): battle.last_reward=Save.reward_stage(battle.stage); _on_ended(result,battle.last_reward)))
	elif result=="victory":
		overlay_box.add_child(UIKit.label(tr("+%d gold   /   +%d keeper EXP") % [reward.get("gold",0),reward.get("exp",0)],24))
		if reward.get("equipment","")!="": overlay_box.add_child(UIKit.label(tr("Found: ")+tr(Data.equipment[reward.equipment].name),18,UIKit.GOLD))
		overlay_box.add_child(UIKit.button(tr("Continue journey"),func(): _router().show_screen("stage_select")))
		overlay_box.add_child(UIKit.button(tr("Train companions"),func(): _router().show_screen("upgrade")))
	else:
		overlay_box.add_child(UIKit.label(tr("Guard the keeper. Build a shield line.\nLet your aura turn a close fight."),19,UIKit.MUTED))
	overlay_box.add_child(UIKit.button(tr("Restart stage"),func(): _router().start_battle(battle.stage.id)))
	overlay_box.add_child(UIKit.button(tr("Return to camp"),func(): _router().show_screen("main_menu")))
	if Save.last_error!="": overlay_box.add_child(UIKit.label(Save.last_error,16,Color("e5a2a2")))

func toggle_debug() -> void:
	if not OS.is_debug_build(): return
	if debug_box!=null:
		debug_box.visible=not debug_box.visible
		return
	debug_box=UIKit.panel()
	debug_box.position=Vector2(30,180)
	add_child(debug_box)
	var box:=VBoxContainer.new()
	debug_box.add_child(box)
	debug_label=UIKit.label("",14,UIKit.GOLD)
	box.add_child(debug_label)
	for command in ["gold","supply","mana","invincible","kill","clear","speed"]:
		box.add_child(UIKit.button(tr(command),func(): battle.debug_command(command),Vector2(170,30)))

func _router():
	return get_tree().root.get_node("Boot")

