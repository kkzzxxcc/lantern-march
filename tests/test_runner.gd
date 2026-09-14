extends SceneTree

var checks: Array = []
var failures := 0
var current_case := ""
var test_cases: Array = []
var data
var save

func _initialize() -> void:
	root.size=Vector2i(1280,720)
	_run.call_deferred()

func check(condition: bool, name: String, detail: String = "") -> void:
	checks.append({"case":current_case,"test":name,"result":"PASS" if condition else "FAIL","detail":detail})
	print(("PASS " if condition else "FAIL ")+name+" "+detail)
	if not condition: failures+=1

func begin_case(name: String, category: String, real_scene: bool = true, real_save: bool = false) -> void:
	current_case=name
	test_cases.append({"name":name,"category":category,"real_scene":real_scene,"automatic_physics":false,"real_save":real_save})

func make_battle(stage_id: int = 1):
	var battle=load("res://scenes/battle/battle.tscn").instantiate()
	battle.presentation_enabled=false
	battle.stage=data.stages[stage_id-1].duplicate(true)
	root.add_child(battle)
	battle.set_physics_process(false)
	return battle

func step(battle,seconds: float) -> void:
	for i in int(seconds*60):
		if battle.status=="choosing": battle.choose_upgrade(0)
		battle.simulate(1.0/60.0)

func _run() -> void:
	data=root.get_node("Data")
	save=root.get_node("Save")
	save.save_path="user://automated-test.json"
	save.state=save.defaults()
	begin_case("catalog_and_input","Unit / Configuration",false)
	check(data.errors.is_empty(),"Data schema and enemy references",str(data.errors))
	check(data.units.size()==6 and data.enemies.size()==10 and data.stages.size()==10 and data.equipment.size()==10 and data.skills.size()==3,"MVP data counts","6 allies, 8 enemies + 2 bosses, 10 stages, 10 equipment, 3 skills")
	for action in ["move_left","move_right","summon_unit_1","summon_unit_2","summon_unit_3","summon_unit_4","summon_unit_5","summon_unit_6","skill_1","skill_2","skill_3","pause","debug_toggle"]:
		check(InputMap.has_action(action),"InputMap "+action)
	begin_case("battle_core","Scene / Integration")
	var b=make_battle()
	check(b.hero!=null and b.enemy_base!=null,"Battle scene construction")
	var x: float=b.hero.position.x
	Input.action_press("move_right")
	step(b,1)
	Input.action_release("move_right")
	check(b.hero.position.x>x+180,"Hero movement via InputMap")
	Input.action_press("move_left")
	step(b,1)
	Input.action_release("move_left")
	check(absf(b.hero.position.x-x)<1,"Hero reverse movement")
	check(b.resources.supply>45 and b.resources.mana>50,"Supply and mana recovery")
	var supply: float=b.resources.supply
	check(b.summon(0),"Unit summon")
	check(is_equal_approx(b.resources.supply,supply-20),"Supply debit")
	check(not b.summon(0),"Spawn cooldown rejects duplicate")
	var ally=b.registry.entities[-1]
	ally.position.x=b.hero.position.x+40
	b.registry.rebuild()
	b.aura.tick(0.2)
	check(ally.aura_active and is_equal_approx(ally.stat("attack"),28.8),"Aura apply attack modifier")
	check(is_equal_approx(ally.stat("attack_speed"),1.15) and is_equal_approx(ally.stat("defense"),3.45),"Aura speed and defense modifiers")
	ally.position.x=b.hero.position.x+600
	b.registry.rebuild()
	b.aura.tick(0.2)
	check(not ally.aura_active and is_equal_approx(ally.stat("attack"),24),"Aura removes without stat drift")
	var enemy=b.spawn_enemy("husk",b.hero.position.x+100)
	b.registry.rebuild()
	var hp: float=enemy.hp
	enemy.take_damage(20)
	check(is_equal_approx(enemy.hp,hp-18),"CombatCalculator subtraction")
	enemy.take_damage(-10)
	check(is_equal_approx(enemy.hp,hp-19),"Minimum damage is one")
	b.resources.mana=100
	check(b.cast_skill(0),"Hero projectile skill")
	for i in 30: b.projectiles.tick(1.0/60.0)
	check(not enemy.alive,"Projectile damages and kills target")
	check(not b.registry.entities.has(enemy),"Dead entity immediately removed from registry")
	var enemy_a=b.spawn_enemy("bulwark",b.hero.position.x+180)
	var enemy_b=b.spawn_enemy("bulwark",b.hero.position.x+210)
	b.registry.rebuild()
	b.resources.mana=100
	check(b.cast_skill(1) and enemy_a.hp<enemy_a.max_hp and enemy_b.hp<enemy_b.max_hp,"Area skill hits multiple enemies")
	b.hero.hp-=140
	b.resources.mana=100
	var health: float=b.hero.hp
	check(b.cast_skill(2) and b.hero.hp>health,"Heal skill restores hero")
	b.status="running"
	b.spawner.tick(5)
	check(b.team_count(1)>=3,"Timed enemy spawning")
	var paused_x: float=b.hero.position.x
	var paused_supply: float=b.resources.supply
	b.status="paused"
	Input.action_press("move_right")
	step(b,1)
	Input.action_release("move_right")
	check(b.hero.position.x==paused_x and b.resources.supply==paused_supply,"Pause freezes combat and resources")
	b.status="running"
	b.enemy_base.take_damage(999999)
	check(b.status=="victory","Enemy gate death triggers victory")
	b.queue_free()
	await process_frame
	begin_case("restart_and_hero_defeat","Scene / Integration")
	var restart=make_battle()
	check(restart.status=="running" and restart.resources.supply==45 and restart.registry.entities.size()==3,"Battle restart resets transient state")
	restart.hero.take_damage(99999)
	check(restartart_status(restart)=="defeat","Hero death triggers defeat")
	restart.queue_free()
	await process_frame
	begin_case("friendly_base_defeat","Scene / Integration")
	var base_loss=make_battle()
	base_loss.player_base.take_damage(99999)
	check(base_loss.status=="defeat","Friendly gate defeat rule")
	base_loss.queue_free()
	await process_frame
	begin_case("boss_phase_and_victory","Scene / Integration")
	var boss_battle=make_battle(5)
	boss_battle.spawner.tick(30)
	var boss=null
	for entity in boss_battle.registry.entities:
		if entity.stats.role=="boss": boss=entity
	check(boss!=null,"Boss scheduled spawn")
	boss.hp=boss.max_hp*0.4
	boss.tick(0.1)
	check(boss.phase==2,"Boss phase transition")
	boss.take_damage(999999)
	check(boss_battle.status=="victory","Boss death victory condition")
	boss_battle.queue_free()
	await process_frame
	# Persistent progress and transaction rules use an isolated save file.
	begin_case("save_progress_and_recovery","Save Persistence",false,true)
	save.state=save.defaults()
	var reward: Dictionary=save.reward_stage(data.stages[0])
	check(reward.gold==130 and save.state.unlocked_stage==2 and save.state.owned_equipment.has("sunspike"),"Victory reward, equipment drop and stage unlock")
	check(save.upgrade_unit("cinder") and save.state.unit_levels.cinder==2,"Permanent unit upgrade purchase")
	check(save.equip("weapon","sunspike") and save.equipment_modifiers().attack==12,"Equipment stats and ownership")
	check(not save.equip("ring_a","sunspike"),"Equipment slot type rejection")
	check(not save.equip("weapon","daybreak"),"Unowned equipment rejected")
	check(save.save_game(),"Save write",save.last_error)
	var expected_gold: int=save.state.gold
	save.state=save.defaults()
	check(save.load_game() and save.state.gold==expected_gold and save.state.unlocked_stage==2 and save.state.unit_levels.cinder==2,"Save reload restores progress")
	var file:=FileAccess.open(save.save_path,FileAccess.WRITE)
	file.store_string("broken{")
	file.close()
	check(save.load_game() and save.state.unlocked_stage==2,"Corrupt save backup recovery")
	var migrated: Dictionary=save.migrate({"stage_progress":3,"save_version":0})
	check(migrated.unlocked_stage==3 and migrated.save_version==1,"Save version 0 migration")
	file=FileAccess.open(save.save_path,FileAccess.WRITE)
	file.store_string('{"save_version":99}')
	file.close()
	check(not save.load_game() and not save.save_game() and save.future_version,"Future save is not overwritten")
	save.future_version=false
	save.state=save.defaults()
	await natural_stage_one()
	await stress_test()
	await extended_combat_test()
	await ui_and_touch_test()
	await campaign_test()
	var output:=FileAccess.open("res://artifacts/test-results.json",FileAccess.WRITE)
	output.store_string(JSON.stringify({"engine":Engine.get_version_info().string,"test_cases":test_cases,"case_count":test_cases.size(),"assertion_count":checks.size(),"checks":checks,"failures":failures},"\t"))
	output.close()
	print("TESTS COMPLETE: %d checks, %d failures" % [checks.size(),failures])
	root.get_node("Audio").shutdown()
	await create_timer(0.15).timeout
	OS.delay_msec(250)
	await process_frame
	quit(0 if failures==0 else 1)

func restartart_status(battle) -> String:
	return battle.status

func natural_stage_one() -> void:
	begin_case("stage_one_policy","Integration")
	save.state=save.defaults()
	var b=make_battle()
	b.spawner.rng.seed=12345
	var deaths := 0
	var blessings := 0
	var skills := 0
	var begin := Time.get_ticks_msec()
	for frame in 60*300:
		if b.status in ["victory","defeat"]: break
		if b.status=="choosing":
			b.choose_upgrade(0)
			blessings+=1
		if frame%30==0:
			if b.team_count(0)<2: b.summon(0)
			elif b.resources.supply>=40 and b.team_count(0)%4==0: b.summon(1)
			elif b.resources.supply>=30: b.summon(2)
			else: b.summon(0)
		var front:=320.0
		var closest_enemy:=float(b.stage.length)
		for unit in b.registry.entities:
			if unit.team==0 and not unit.is_hero and not unit.is_base: front=maxf(front,unit.position.x)
			if unit.team==1: closest_enemy=minf(closest_enemy,unit.position.x)
		var desired:=minf(front-70,closest_enemy-160)
		Input.action_release("move_left")
		Input.action_release("move_right")
		if b.hero.position.x<desired-8: Input.action_press("move_right")
		if b.hero.position.x>desired+8: Input.action_press("move_left")
		if frame%60==0:
			if b.hero.hp<b.hero.max_hp*0.75:
				if b.cast_skill(2): skills+=1
			elif closest_enemy-b.hero.position.x<450:
				if b.cast_skill(0): skills+=1
		b.simulate(1.0/60.0)
		if frame%120==0: await process_frame
	Input.action_release("move_left")
	Input.action_release("move_right")
	check(b.status=="victory","Natural Stage 1 full combat loop","result=%s time=%.1fs skills=%d blessings=%d wall=%dms (normal costs, no damage cheats)" % [b.status,b.elapsed,skills,blessings,Time.get_ticks_msec()-begin])
	b.queue_free()
	await process_frame

func stress_test() -> void:
	begin_case("entity_99","Performance")
	var b=make_battle()
	b.hero.invincible=true
	b.enemy_base.invincible=true
	b.player_base.invincible=true
	b.spawner.timer=9999
	for i in 48:
		b._spawn(data.units.cinder,0,500+i*12)
		b.spawn_enemy("bulwark",1400+i*10)
	var count: int=b.registry.entities.size()
	var start:=Time.get_ticks_usec()
	for i in 600:
		if b.status=="choosing": b.choose_upgrade(0)
		b.simulate(1.0/60.0)
	var duration:=Time.get_ticks_usec()-start
	check(count==99,"Entity stress construction","99 entities including 48 friendly + 48 enemy")
	check(b.registry.entities.size()<=100,"Entity stress bounded simulation","600 ticks %.2fms, %.3fms per tick (headless CPU; not mobile FPS)" % [duration/1000.0,duration/600000.0])
	b.queue_free()
	await process_frame



func ui_and_touch_test() -> void:
	begin_case("ui_and_multitouch","Scene / Touch")
	save.state=save.defaults()
	var boot=load("res://scenes/boot/boot.tscn").instantiate()
	root.add_child(boot)
	await process_frame
	check(boot.screen.screen_id=="main_menu","Boot opens MainMenu")
	var begin_button=find_button(boot.screen,"Begin the march")
	await tap(begin_button)
	check(boot.screen.screen_id=="stage_select","Menu button accepts touch")
	for screen_id in ["stage_select","upgrade","equipment","settings"]:
		boot.show_screen(screen_id)
		await process_frame
		check(boot.screen.screen_id==screen_id,"Scene route "+screen_id)
	boot.start_battle(1)
	await process_frame
	await process_frame
	var b=boot.screen
	b.set_physics_process(false)
	b.resources.supply=45
	check(b.hud!=null and b.hud.unit_buttons.size()==6 and b.hud.skill_buttons.size()==3,"Battle HUD six summons and three skills")
	# Inject a genuine InputEventScreenTouch through the scene input pipeline.
	var button=b.hud.unit_buttons[0]
	var touch:=InputEventScreenTouch.new()
	touch.index=0
	touch.position=root.get_final_transform()*button.get_global_rect().get_center()
	touch.pressed=true
	Input.parse_input_event(touch)
	await process_frame
	touch=InputEventScreenTouch.new()
	touch.index=0
	touch.position=root.get_final_transform()*button.get_global_rect().get_center()
	touch.pressed=false
	Input.parse_input_event(touch)
	await process_frame
	check(b.team_count(0)==1 and is_equal_approx(b.resources.supply,25),"Touch summon dispatches InputMap exactly once", "count=%d supply=%.1f rect=%s viewport=%s" % [b.team_count(0),b.resources.supply,button.get_global_rect(),root.size])
	var move_button=null
	for child in button.get_parent().get_children():
		if child is ActionButton and child.action=="move_right": move_button=child
	var start: float=b.hero.position.x
	touch=InputEventScreenTouch.new()
	touch.index=1
	touch.position=root.get_final_transform()*move_button.get_global_rect().get_center()
	touch.pressed=true
	Input.parse_input_event(touch)
	await process_frame
	step(b,0.5)
	b.resources.mana=100
	var heal_button=b.hud.skill_buttons[2]
	var another:=InputEventScreenTouch.new()
	another.index=2
	another.position=root.get_final_transform()*heal_button.get_global_rect().get_center()
	another.pressed=true
	Input.parse_input_event(another)
	await process_frame
	step(b,0.5)
	check(b.hero.position.x>start+180 and b.skill_cooldowns[2]>0,"Multitouch movement plus skill", "move=%.1f cooldown=%.1f pressed=%s" % [b.hero.position.x-start,b.skill_cooldowns[2],Input.is_action_pressed("move_right")])
	touch=InputEventScreenTouch.new()
	touch.index=1
	touch.position=Vector2(20,20)
	touch.pressed=false
	Input.parse_input_event(touch)
	another=InputEventScreenTouch.new()
	another.index=2
	another.position=Vector2(20,20)
	another.pressed=false
	Input.parse_input_event(another)
	await process_frame
	check(not Input.is_action_pressed("move_right"),"Touch release outside button clears movement")
	# Natural damage path to the end screen invokes real persistence.
	b.enemy_base.take_damage(999999)
	await process_frame
	check(b.status=="victory" and save.state.unlocked_stage==2 and b.hud.overlay.visible,"UI victory reward unlock save integration")
	boot.start_battle(2)
	await process_frame
	check(boot.screen.stage.id==2,"Stage 2 can start after victory")
	boot.queue_free()
	await process_frame

func campaign_test() -> void:
	begin_case("campaign_10_stages","Integration / Save")
	save.state=save.defaults()
	for stage_id in range(1,11):
		var b=make_battle(stage_id)
		b.spawner.rng.seed=800+stage_id
		for frame in 60*240:
			if b.status in ["victory","defeat"]: break
			if b.status=="choosing":
				var choice:=0
				for i in b.pending_choices.size():
					if b.pending_choices[i].id=="attack": choice=i
				b.choose_upgrade(choice)
			if frame%30==0:
				if b.team_count(0)<2: b.summon(0)
				elif b.resources.supply>=40 and b.team_count(0)%4==0: b.summon(1)
				elif b.resources.supply>=30: b.summon(2)
			var front:=320.0
			var nearest:=float(b.stage.length)
			for unit in b.registry.entities:
				if unit.team==0 and not unit.is_hero and not unit.is_base: front=maxf(front,unit.position.x)
				if unit.team==1: nearest=minf(nearest,unit.position.x)
			var desired:=minf(front-70,nearest-175)
			Input.action_release("move_left")
			Input.action_release("move_right")
			if b.hero.position.x<desired-8: Input.action_press("move_right")
			if b.hero.position.x>desired+8: Input.action_press("move_left")
			if frame%60==0:
				if b.hero.hp<b.hero.max_hp*0.8: b.cast_skill(2)
				elif nearest-b.hero.position.x<460: b.cast_skill(0)
			b.simulate(1.0/60.0)
			if frame%120==0: await process_frame
		Input.action_release("move_left")
		Input.action_release("move_right")
		check(b.status=="victory","Campaign stage %02d" % stage_id,"result=%s duration=%.1fs level=%d entities=%d" % [b.status,b.elapsed,b.battle_level,b.registry.entities.size()])
		if b.status=="victory":
			for id in save.state.owned_equipment:
				if data.equipment[id].slot=="weapon": save.equip("weapon",id)
			for id in ["cinder","needle","bastion"]:
				save.upgrade_unit(id)
		b.queue_free()
		await process_frame

func find_button(node: Node, text: String):
	if node is Button and node.text.begins_with(text): return node
	for child in node.get_children():
		var found=find_button(child,text)
		if found!=null: return found
	return null

func tap(button) -> void:
	var event:=InputEventScreenTouch.new()
	event.index=0
	event.pressed=true
	event.position=root.get_final_transform()*button.get_global_rect().get_center()
	Input.parse_input_event(event)
	await process_frame
	var release:=InputEventScreenTouch.new()
	release.index=0
	release.pressed=false
	release.position=event.position
	Input.parse_input_event(release)
	await process_frame
	await process_frame


func extended_combat_test() -> void:
	begin_case("healer_support_siege_exp","Scene / Integration")
	var b=make_battle()
	b.spawner.timer=99999
	var tank=b._spawn(data.units.bastion,0,450)
	var healer=b._spawn(data.units.mender,0,400)
	tank.hp-=100
	b.registry.rebuild()
	check(b.registry.find_target(healer)==tank,"Healer selects wounded friendly target")
	var hp: float=tank.hp
	healer.attack(tank)
	check(tank.hp>hp,"Healer unit restores health")
	var support=b.spawn_enemy("cantor",900)
	var enemy=b.spawn_enemy("bulwark",950)
	b.registry.rebuild()
	check(b.registry.find_target(support)==enemy,"Support targets allied enemy faction")
	support.attack(enemy)
	check(enemy.support_time>0 and enemy.stat("attack")>enemy.stats.attack,"Support unit applies timed buff")
	enemy.tick(5.0)
	check(enemy.support_time==0 and enemy.stat("attack")==enemy.stats.attack,"Support buff expires without drift")
	var siege=b._spawn(data.units.ram,0,b.enemy_base.position.x-300)
	var base_hp: float=b.enemy_base.hp
	siege.attack(b.enemy_base)
	for i in 60: b.projectiles.tick(1.0/60.0)
	check(is_equal_approx(base_hp-b.enemy_base.hp,127),"Siege double base damage through projectile")
	b.battle_exp=float(data.rules.battle_exp_base)-1
	var one=b.spawn_enemy("husk",1000)
	var two=b.spawn_enemy("husk",1050)
	one.die()
	two.die()
	check(b.status=="choosing" and b.pending_choices.size()==3 and b.battle_exp==23,"Battle EXP preserves simultaneous kills while choosing")
	var option: Dictionary=b.pending_choices[0].duplicate()
	check(b.choose_upgrade(0) and is_equal_approx(b.battle_modifiers[option.stat],option.value),"Selected battle blessing applies")
	b.queue_free()
	await process_frame
