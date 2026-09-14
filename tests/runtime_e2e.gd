extends SceneTree

var assertions: Array = []
var failures := 0
var boot
var active_battle
var frame := 0
var observed := {"hero_left":false,"hero_right":false,"recovery":false,"friendly_spawn":false,"enemy_spawn":false,"unit_movement":false,"target":false,"damage":false,"death":false,"aura_on":false,"aura_off":false,"skill":false,"mana_spent":false,"base_damage":false,"projectile":false}
var unit_positions: Dictionary = {}
var seen_units: Dictionary = {}
var previous_hero_x := 320.0
var previous_mana := 50.0
var initial_hero_health := 580.0
var auto_play := false
var ui_ready := false
var touch_sequence_done := false
var summary: Array = []
var save

func _initialize() -> void:
	run.call_deferred()

func record(condition: bool, name: String, detail: Variant = "") -> void:
	assertions.append({"assertion":name,"result":"PASS" if condition else "FAIL","detail":str(detail)})
	print("PASS " if condition else "FAIL ",name," ",detail)
	if not condition: failures+=1

func run() -> void:
	save=root.get_node("Save")
	save.save_path="user://runtime-e2e.json"
	var args:=OS.get_cmdline_user_args()
	if args.has("boss"):
		await run_boss_stages()
		return
	if args.has("read"):
		record(save.load_game(),"Fresh process reads E2E save")
		record(save.state.unlocked_stage>=3 and save.state.cleared.has(1) and save.state.cleared.has(2),"Fresh process restores actual stage victories")
		record(save.state.hero_level>=2 and save.state.unit_levels.get("cinder",0)==2,"Fresh process restores earned hero and purchased unit levels")
		var file:=FileAccess.open("user://runtime-e2e-expected.json",FileAccess.READ)
		var expected=JSON.parse_string(file.get_as_text())
		record(JSON.parse_string(JSON.stringify(save.state))==expected,"All saved fields equal previous runtime process",save.state)
		await finish("runtime-e2e-reload")
		return
	save.state=save.defaults()
	change_scene_to_file(ProjectSettings.get_setting("application/run/main_scene"))
	await scene_changed
	boot=current_scene
	await process_frame
	await process_frame
	record(boot.name=="Boot" and boot.screen.screen_id=="main_menu","Actual configured Main Scene opens MainMenu")
	await click_text("Begin the march")
	record(boot.screen.screen_id=="stage_select","Touch menu enters StageSelect")
	await click_text("01")
	await enter_battle()
	record(active_battle.stage.id==1 and active_battle.is_physics_processing() and active_battle.hud!=null,"Normal Battle Scene runs automatic physics with HUD")
	for stage_id in [1,2]:
		auto_play=true
		while is_instance_valid(active_battle) and active_battle.status not in ["victory","defeat"] and frame<60*210:
			await physics_frame
		auto_play=false
		Input.action_release("move_left")
		Input.action_release("move_right")
		record(active_battle.status=="victory","Natural runtime stage %d victory" % stage_id,"elapsed=%.2f; automatic _physics_process; no simulate() calls, damage cheats or free resources" % active_battle.elapsed)
		summary.append({"stage":stage_id,"result":active_battle.status,"elapsed":active_battle.elapsed,"physics_frames":frame,"gold":save.state.gold,"hero_level":save.state.hero_level,"unlocked":save.state.unlocked_stage})
		if active_battle.status!="victory": break
		await process_frame
		record(active_battle.hud.overlay.visible,"Victory screen shown for stage %d" % stage_id)
		if stage_id==1:
			record(save.state.unlocked_stage==2 and save.state.gold==310,"Natural reward saved and Stage 2 unlocked")
			await click_text("Train companions")
			record(boot.screen.screen_id=="upgrade","Victory routes to Upgrade screen")
			await click_text("Train  ")
			record(save.state.unit_levels.get("cinder",0)==2 and save.state.gold==210,"UI training debits gold and upgrades Cinder Guard")
			await click_text("‹  Camp")
			await click_text("Begin the march")
			await click_text("02")
			await enter_battle()
	for key in observed:
		record(observed[key],"Observed runtime path: "+key)
	if save.state.unlocked_stage>=3:
		await click_text("Return to camp")
		await click_text("Keeper equipment")
		await click_text("Sunspike")
		record(save.state.equipped.weapon=="sunspike","Equipment UI equips earned drop")
		await click_text("‹  Camp")
		await click_text("Settings")
		var sliders: Array=[]
		find_sliders(boot.screen,sliders)
		sliders[1].value=0.32
		await click_text("‹  Camp")
		record(is_equal_approx(save.state.settings.music,0.32),"Settings UI writes changed music volume")
	var expected_file:=FileAccess.open("user://runtime-e2e-expected.json",FileAccess.WRITE)
	expected_file.store_string(JSON.stringify(save.state))
	expected_file.close()
	record(save.save_game(),"Final gameplay state saved before process exit")
	await finish("runtime-e2e")

func enter_battle() -> void:
	await process_frame
	await process_frame
	active_battle=boot.screen
	frame=0
	previous_hero_x=active_battle.hero.position.x
	previous_mana=active_battle.resources.mana
	unit_positions.clear()
	seen_units.clear()
	touch_sequence_done=false

func _physics_process(_delta: float) -> bool:
	if not auto_play or not is_instance_valid(active_battle): return false
	var b=active_battle
	frame+=1
	if b.status=="choosing":
		var button=find_button(b.hud.overlay,"",true)
		if button!=null: button.pressed.emit()
		return false
	if b.status!="running": return false
	observe(b)
	var front:=320.0
	var nearest:=float(b.stage.length)
	for unit in b.registry.entities:
		if unit.team==0 and not unit.is_hero and not unit.is_base: front=maxf(front,unit.position.x)
		if unit.team==1: nearest=minf(nearest,unit.position.x)
	Input.action_release("move_left")
	Input.action_release("move_right")
	if frame<20:
		Input.action_press("move_left")
	elif frame<40:
		Input.action_press("move_right")
	elif frame>180 and frame<270:
		Input.action_press("move_left")
	else:
		var desired:=minf(front-70,nearest-160)
		if b.hero.position.x<desired-8: Input.action_press("move_right")
		if b.hero.position.x>desired+8: Input.action_press("move_left")
	if frame==60:
		send_touch(b.hud.unit_buttons[0],0,true)
	if frame==62:
		send_touch(b.hud.unit_buttons[0],0,false)
	if frame>90 and frame%30==0:
		if b.team_count(0)<2: action("summon_unit_1")
		elif b.resources.supply>=40 and b.team_count(0)%4==0: action("summon_unit_2")
		elif b.resources.supply>=30: action("summon_unit_3")
	if frame%60==0:
		if b.hero.hp<b.hero.max_hp*0.8: action("skill_3")
		elif nearest-b.hero.position.x<450: action("skill_1")
	return false

func action(name: String) -> void:
	var event:=InputEventAction.new()
	event.action=name
	event.pressed=true
	Input.parse_input_event(event)
	var release:=InputEventAction.new()
	release.action=name
	release.pressed=false
	Input.parse_input_event(release)

func observe(b) -> void:
	var x: float=b.hero.position.x
	observed.hero_left=observed.hero_left or x<previous_hero_x
	observed.hero_right=observed.hero_right or x>previous_hero_x
	previous_hero_x=x
	observed.recovery=observed.recovery or (frame<60 and b.resources.supply>48)
	observed.mana_spent=observed.mana_spent or b.resources.mana<previous_mana-10
	previous_mana=b.resources.mana
	observed.skill=observed.skill or b.skill_cooldowns.any(func(cd):return cd>0)
	observed.projectile=observed.projectile or b.projectiles.slots.any(func(slot):return slot.active)
	observed.base_damage=observed.base_damage or (is_instance_valid(b.enemy_base) and b.enemy_base.hp<b.enemy_base.max_hp)
	for unit in b.registry.entities:
		var id: int=unit.get_instance_id()
		if not seen_units.has(id):
			seen_units[id]=true
			unit.died.connect(func(dead):
				if not dead.is_base and not dead.is_hero: observed.death=true)
		if not unit.is_base and not unit.is_hero:
			observed.friendly_spawn=observed.friendly_spawn or unit.team==0
			observed.enemy_spawn=observed.enemy_spawn or unit.team==1
			if unit_positions.has(id) and unit_positions[id]!=unit.position.x: observed.unit_movement=true
			unit_positions[id]=unit.position.x
			observed.damage=observed.damage or unit.hp<unit.max_hp
			if unit.target!=null and is_instance_valid(unit.target) and unit.target.team!=unit.team: observed.target=true
			if unit.team==0:
				observed.aura_on=observed.aura_on or (unit.aura_active and unit.stat("attack")>unit.stats.attack)
				observed.aura_off=observed.aura_off or (not unit.aura_active and is_equal_approx(unit.stat("attack"),unit.stats.attack))

func send_touch(button, index: int, pressed: bool) -> void:
	var event:=InputEventScreenTouch.new()
	event.index=index
	event.pressed=pressed
	event.position=root.get_final_transform()*button.get_global_rect().get_center()
	Input.parse_input_event(event)

func click_text(text: String, required: bool = true) -> void:
	var button=find_button(boot.screen,text)
	if button==null:
		if required: record(false,"UI button found: "+text)
		return
	send_touch(button,0,true)
	await process_frame
	send_touch(button,0,false)
	await process_frame
	await process_frame
	await process_frame

func find_button(node, text: String, any: bool = false):
	if node is Button and (any or node.text.begins_with(text)) and not node.disabled and node.is_visible_in_tree(): return node
	for child in node.get_children():
		var found=find_button(child,text,any)
		if found!=null: return found
	return null

func find_sliders(node, result: Array) -> void:
	if node is HSlider: result.append(node)
	for child in node.get_children(): find_sliders(child,result)

func finish(id: String) -> void:
	var file:=FileAccess.open("res://artifacts/"+id+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"case":id,"real_main_scene":true,"automatic_physics":true,"real_save_file":true,"assertions":assertions,"assertion_count":assertions.size(),"failures":failures,"stages":summary},"\t"))
	file.close()
	print("RUNTIME E2E ",id,": 1 case / ",assertions.size()," assertions / ",failures," failures")
	if is_instance_valid(boot): boot.queue_free()
	root.get_node("Audio").shutdown()
	await create_timer(0.15).timeout
	OS.delay_msec(250)
	await process_frame
	quit(0 if failures==0 else 1)


func run_boss_stages() -> void:
	# Entry fixture only: progression equivalent to prior campaign rewards/training.
	# Combat uses unmodified resources, damage and automatic physics through Main Scene.
	save.save_path="user://boss-runtime.json"
	save.state=save.defaults()
	save.state.unlocked_stage=10
	save.state.hero_level=5
	save.state.unit_levels={"cinder":4,"needle":4,"bastion":4}
	save.state.owned_equipment.append("daybreak")
	save.state.equipped.weapon="daybreak"
	change_scene_to_file(ProjectSettings.get_setting("application/run/main_scene"))
	await scene_changed
	boot=current_scene
	await process_frame
	for stage_id in [5,10]:
		await click_text("Begin the march")
		await click_text("%02d" % stage_id)
		await enter_battle()
		active_battle.spawner.rng.seed=800+stage_id
		record(active_battle.stage.id==stage_id and active_battle.is_physics_processing(),"Boss stage UI entry "+str(stage_id))
		auto_play=true
		while active_battle.status not in ["victory","defeat"] and frame<60*240: await physics_frame
		auto_play=false
		Input.action_release("move_left")
		Input.action_release("move_right")
		record(active_battle.status=="victory","Boss runtime victory "+str(stage_id),active_battle.elapsed)
		summary.append({"stage":stage_id,"result":active_battle.status,"elapsed":active_battle.elapsed})
		await process_frame
		await click_text("Return to camp")
	await finish("boss-runtime")
