extends Control

@export var screen_id := "main_menu"
var body: VBoxContainer
var wallet: Label
var equipment_slot := "weapon"

func _ready() -> void:
	UIKit.fill(self)
	theme=UIKit.theme()
	var ground:=BattleGround.new()
	ground.modulate=Color(0.65,0.75,0.8,1)
	add_child(ground)
	var tint:=ColorRect.new()
	tint.color=Color(0.025,0.07,0.085,0.47)
	tint.mouse_filter=Control.MOUSE_FILTER_IGNORE
	UIKit.fill(tint)
	add_child(tint)
	var margin:=SafeMargin.new()
	UIKit.fill(margin)
	add_child(margin)
	body=VBoxContainer.new()
	body.add_theme_constant_override("separation",20)
	margin.add_child(body)
	_build()

func _build() -> void:
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	if screen_id=="main_menu":
		_main_menu()
		return
	var top:=HBoxContainer.new()
	body.add_child(top)
	top.add_child(UIKit.button("‹  Camp",func(): _router().show_screen("main_menu"),Vector2(110,45)))
	top.add_child(UIKit.spacer())
	wallet=UIKit.label("KEEPER LV.%d     /     %d GOLD" % [Save.state.hero_level,Save.state.gold],18,UIKit.GOLD)
	top.add_child(wallet)
	var titles:={"stage_select":"THE ROAD AHEAD","upgrade":"A STRONGER COMPANY","equipment":"THE KEEPER'S KIT","settings":"MAKE YOURSELF AT HOME"}
	body.add_child(UIKit.label(titles.get(screen_id,"Camp"),36))
	if Save.last_error != "": body.add_child(UIKit.label(Save.last_error, 16, Color("e5a2a2")))
	match screen_id:
		"stage_select": _stages()
		"upgrade": _upgrades()
		"equipment": _equipment()
		"settings": _settings()

func _main_menu() -> void:
	var eyebrow:=HBoxContainer.new()
	body.add_child(eyebrow)
	eyebrow.add_child(UIKit.label("AN ORIGINAL LANE ADVENTURE",14,UIKit.GOLD))
	eyebrow.add_child(UIKit.spacer())
	eyebrow.add_child(UIKit.label("SINGLE PLAYER  /  CHAPTER I",14,UIKit.MUTED))
	body.add_child(UIKit.spacer())
	var row:=HBoxContainer.new()
	body.add_child(row)
	var title:=VBoxContainer.new()
	title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	row.add_child(title)
	title.add_child(UIKit.label("LANTERN\nMARCH",78,UIKit.TEXT))
	title.add_child(UIKit.label("Carry the light. Hold the line.",24,UIKit.GOLD))
	title.add_child(UIKit.label("Beyond the last warm window, the road is fading.\nGather your companions. Bring the dawn with you.",18,UIKit.MUTED))
	var actions:=VBoxContainer.new()
	actions.custom_minimum_size.x=310
	row.add_child(actions)
	actions.add_child(UIKit.label("YOUR JOURNEY",14,UIKit.GOLD))
	actions.add_child(UIKit.button("Begin the march    >",func(): _router().show_screen("stage_select"),Vector2(310,68)))
	actions.add_child(UIKit.button("Train companions",func(): _router().show_screen("upgrade")))
	actions.add_child(UIKit.button("Keeper equipment",func(): _router().show_screen("equipment")))
	actions.add_child(UIKit.button("Settings",func(): _router().show_screen("settings")))
	actions.add_child(UIKit.label("Stage %d of 10  /  Keeper Lv.%d\n%d gold in the camp chest" % [Save.state.unlocked_stage,Save.state.hero_level,Save.state.gold],16,UIKit.MUTED))
	body.add_child(UIKit.spacer())
	body.add_child(UIKit.label("Move with A / D or the touch arrows. Summon with 1–6. Cast with J / K / L.",15,UIKit.MUTED))
	if Save.last_error!="": body.add_child(UIKit.label(Save.last_error,16,Color("e5a2a2")))
	if OS.has_feature("web") and not OS.is_userfs_persistent():
		body.add_child(UIKit.label("Browser storage is unavailable. Progress may not survive closing this page.",16,UIKit.GOLD))

func _scroll_grid(columns: int) -> GridContainer:
	var scroll:=ScrollContainer.new()
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	var grid:=GridContainer.new()
	grid.columns=columns
	grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)
	return grid

func _stages() -> void:
	body.add_child(UIKit.label("Ten roads toward the dawn. First victories unlock equipment and the next crossing.",18,UIKit.MUTED))
	var grid:=_scroll_grid(5)
	for stage in Data.stages:
		var unlocked: bool=stage.id<=Save.state.unlocked_stage
		var cleared: bool=Save.state.cleared.has(int(stage.id))
		var state_text: String="CLEARED" if cleared else ("GUARDIAN" if stage.mode=="boss" else "ASSAULT")
		var button:=UIKit.button("%02d   %s\n\n%s\n\n%d GOLD   /   %d EXP" % [stage.id,state_text if unlocked else "LOCKED",stage.name,stage.reward.gold,stage.reward.exp],func(): _router().start_battle(stage.id),Vector2(220,177))
		button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size",16)
		button.disabled=not unlocked
		grid.add_child(button)

func _upgrades() -> void:
	body.add_child(UIKit.label("Each level adds 20 health and 5 attack. Training stays with you between journeys.",18,UIKit.MUTED))
	var grid:=_scroll_grid(3)
	for id in Data.roster():
		var unit: Dictionary=Data.units[id]
		var level:=int(Save.state.unit_levels.get(id,1))
		var panel:=UIKit.panel()
		panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		grid.add_child(panel)
		var box:=VBoxContainer.new()
		panel.add_child(box)
		box.add_child(UIKit.label("%s   /   Lv.%d" % [unit.name,level],23,Color(unit.color)))
		box.add_child(UIKit.label(unit.description,16,UIKit.MUTED))
		box.add_child(UIKit.label("HP %d   /   ATK %d   /   DEF %d" % [unit.hp+(level-1)*20,unit.attack+(level-1)*5,unit.defense],17))
		var button:=UIKit.button("Train  •  %d gold" % (level*100),func(): Save.upgrade_unit(id); _build())
		button.disabled=Save.state.gold<level*100 or level>=100
		box.add_child(button)

func _equipment() -> void:
	var slots:=HBoxContainer.new()
	body.add_child(slots)
	for slot in ["weapon","ring_a","ring_b"]:
		var id: String=Save.state.equipped.get(slot,"")
		var button:=UIKit.button(slot.replace("_"," ").to_upper()+"\n"+(Data.equipment[id].name if id!="" else "Empty"),func(): equipment_slot=slot; _build(),Vector2(250,68))
		button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		if slot==equipment_slot: button.add_theme_stylebox_override("normal",UIKit.style(Color("385353"),UIKit.GOLD))
		slots.add_child(button)
	body.add_child(UIKit.label("Select a slot, then equip an owned item. Find the remaining pieces through first victories.",17,UIKit.MUTED))
	var grid:=_scroll_grid(3)
	for id in Data.equipment:
		var item: Dictionary=Data.equipment[id]
		if item.slot!=("weapon" if equipment_slot=="weapon" else "ring"): continue
		var owned: bool=Save.state.owned_equipment.has(id)
		var options: Array[String]=[]
		for stat in item.stats: options.append(stat.replace("_"," ")+" +"+str(item.stats[stat]))
		var button:=UIKit.button(item.name+"\n"+", ".join(options)+"\n"+("Equip" if owned else "Not yet discovered"),func(): Save.equip(equipment_slot,id); _build(),Vector2(340,108))
		button.add_theme_font_size_override("font_size",17)
		button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		button.disabled=not owned
		grid.add_child(button)

func _settings() -> void:
	var panel:=UIKit.panel()
	body.add_child(panel)
	var box:=VBoxContainer.new()
	panel.add_child(box)
	for key in ["master","music","sfx"]:
		var row:=HBoxContainer.new()
		box.add_child(row)
		var label:=UIKit.label(key.to_upper(),18)
		label.custom_minimum_size.x=180
		row.add_child(label)
		var slider:=HSlider.new()
		slider.min_value=0
		slider.max_value=1
		slider.step=0.01
		slider.value=Save.state.settings[key]
		slider.custom_minimum_size=Vector2(450,54)
		slider.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		slider.value_changed.connect(func(value): Save.set_setting(key,value); Audio.apply_settings())
		slider.drag_ended.connect(func(_changed): Save.save_game())
		slider.focus_exited.connect(func(): Save.save_game())
		row.add_child(slider)
	var mute:=CheckButton.new()
	mute.text="Mute all audio"
	mute.button_pressed=Save.state.settings.mute
	mute.toggled.connect(func(value): Save.set_setting("mute",value); Audio.apply_settings())
	box.add_child(mute)
	box.add_child(UIKit.label("Controls\nA / Left arrow  •  D / Right arrow  —  Move\n1–6  —  Summon a companion\nJ  —  Sunbolt    K  —  Lantern Flare    L  —  First Light\nEscape  —  Pause",18,UIKit.MUTED))
	body.add_child(UIKit.label("Progress is saved on this device. Browser storage must be allowed.\nYour keeper gains permanent levels from stage EXP. Battle blessings last for one stage.",17,UIKit.MUTED))

func _router():
	return get_tree().root.get_node("Boot")

func _exit_tree() -> void:
	if screen_id=="settings": Save.save_game()

