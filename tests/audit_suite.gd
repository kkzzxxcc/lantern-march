extends SceneTree

var assertions: Array = []
var cases: Array = []
var case_name := ""
var data
var save
var failures := 0
var performance_samples: Array = []

func _initialize() -> void:
	run.call_deferred()

func begin(name: String, category: String) -> void:
	case_name=name
	cases.append({"name":name,"category":category,"real_scene":true,"automatic_physics":false,"save_file":name.begins_with("save")})

func verify(condition: bool, description: String, evidence: Variant = "") -> void:
	assertions.append({"case":case_name,"assertion":description,"result":"PASS" if condition else "FAIL","evidence":str(evidence)})
	print("PASS " if condition else "FAIL ",case_name," / ",description," ",evidence)
	if not condition: failures+=1

func fixture():
	var b=load("res://scenes/battle/battle.tscn").instantiate()
	b.presentation_enabled=false
	b.stage=data.stages[0].duplicate(true)
	root.add_child(b)
	b.set_physics_process(false)
	b.spawner.timer=999999
	return b

func dispose(b) -> void:
	b.queue_free()
	await process_frame

func run() -> void:
	data=root.get_node("Data")
	save=root.get_node("Save")
	save.save_path="user://audit-fixture.json"
	save.state=save.defaults()
	await aura_cycles()
	await target_edges()
	await combat_edges()
	await projectile_lifecycle()
	await resources_and_cooldowns()
	await save_bad_values()
	await content_and_equipment()
	await performance_profile()
	await save_transaction_failures()
	await support_positioning()
	var output={"engine":Engine.get_version_info().string,"test_cases":cases,"case_count":cases.size(),"assertion_count":assertions.size(),"failures":failures,"assertions":assertions,"performance":performance_samples}
	var file:=FileAccess.open("res://artifacts/audit-tests.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(output,"\t"))
	file.close()
	print("AUDIT SUITE: ",cases.size()," cases / ",assertions.size()," assertions / ",failures," failures")
	root.get_node("Audio").shutdown()
	await create_timer(0.15).timeout
	OS.delay_msec(250)
	await process_frame
	quit(0 if failures==0 else 1)

func aura_cycles() -> void:
	begin("aura_reentry_and_cleanup","Integration / Scene")
	var b=fixture()
	var allies: Array=[]
	for i in 8:
		var stats: Dictionary=data.units.cinder.duplicate(true)
		stats.attack=100
		stats.defense=100
		stats.attack_speed=100
		allies.append(b._spawn(stats,0,400+i*4))
	var values: Array=[]
	for iteration in 20:
		b.hero.position.x=420 if iteration%2==0 else 1000
		b.registry.rebuild()
		b.aura.tick(0.13)
		var inside: bool=iteration%2==0
		var correct:=true
		for ally in allies:
			correct=correct and is_equal_approx(ally.stat("attack"),120 if inside else 100) and is_equal_approx(ally.stat("defense"),115 if inside else 100) and is_equal_approx(ally.stat("attack_speed"),115 if inside else 100)
		values.append(allies[0].stat("attack"))
		verify(correct,"8 allies boundary cycle %02d" % iteration)
	verify(values==[120.0,100.0,120.0,100.0,120.0,100.0,120.0,100.0,120.0,100.0,120.0,100.0,120.0,100.0,120.0,100.0,120.0,100.0,120.0,100.0],"No aura compounding",values)
	b.hero.position.x=420
	b.aura.tick(0.13)
	var dying=allies.pop_back()
	dying.die()
	verify(not b.aura.affected.has(dying) and not b.registry.entities.has(dying),"Aura death unregisters immediately")
	var target=b.spawn_enemy("husk",460)
	allies[0].target=target
	target.die()
	verify(allies[0].target==null and allies[0].aura_active,"Target death clears reference without removing friendly aura")
	b.aura.clear()
	verify(not allies[0].aura_active and allies[0].stat("attack")==100,"Stage aura cleanup returns base stats")
	await dispose(b)

func target_edges() -> void:
	begin("target_range_death_and_faction","Integration / Scene")
	var b=fixture()
	var ally=b._spawn(data.units.cinder,0,700)
	var far=b.spawn_enemy("husk",810)
	var near=b.spawn_enemy("husk",770)
	b.registry.rebuild()
	verify(b.registry.find_target(ally)==near,"Nearest opposite faction selected")
	ally.target=near
	near.die()
	verify(ally.target==null,"Death invalidates cached target immediately")
	ally.search_timer=0
	ally.tick(0.01)
	verify(ally.target==far,"Retargets after death")
	far.position.x=1300
	var health: float=far.hp
	ally.attack(far)
	verify(far.hp==health,"Public attack rejects out-of-range target")
	far.die()
	var before: float=ally.position.x
	ally.tick(0.1)
	verify(ally.position.x>before,"No target resumes forward movement")
	var base=b.enemy_base
	ally.position.x=base.position.x-90
	b.registry.rebuild()
	ally.search_timer=0
	ally.attack_timer=0
	health=base.hp
	ally.tick(0.05)
	verify(base.hp<health,"Normal AI attacks enemy gate")
	await dispose(b)

func combat_edges() -> void:
	begin("shared_damage_and_attack_boundaries","Unit / Scene")
	var b=fixture()
	var a=b._spawn(data.units.cinder,0,700)
	var e=b.spawn_enemy("bulwark",750)
	var health: float=e.hp
	e.take_damage(0)
	verify(e.hp==health-1,"Attack zero still deals minimum one per formula")
	health=e.hp
	e.take_damage(5)
	verify(e.hp==health-1,"Defense above attack clamps to one")
	a.stats.attack_speed=0
	health=e.hp
	a.attack(e)
	verify(e.hp==health,"Zero attack speed cannot attack")
	a.stats.attack_speed=1000000
	a.stats.attack=1
	a.target=e
	a.search_timer=999
	health=e.hp
	a.tick(1.0/60.0)
	verify(e.hp==health-1,"Extreme attack speed bounded to one attack per physics tick")
	e.die()
	a.attack(e)
	verify(a.target==null,"Attack on newly dead target safely ignored")
	await process_frame
	var cooldown_before: float=a.attack_timer
	a.attack(e)
	verify(not is_instance_valid(e) and a.attack_timer==cooldown_before,"Freed target safely ignored; log scanner also required")
	# Hero moves outside range before attacking during this same update.
	var enemy=b.spawn_enemy("husk",500)
	b.hero.position.x=360
	b.hero.target=enemy
	b.hero.search_timer=999
	b.hero.attack_timer=0
	health=enemy.hp
	Input.action_press("move_left")
	b.hero.tick(0.1)
	Input.action_release("move_left")
	verify(enemy.hp==health,"Hero range checked after movement")
	await dispose(b)

func projectile_lifecycle() -> void:
	begin("projectile_pool_acquire_release_and_saturation","Integration / Scene")
	var b=fixture()
	var target=b.spawn_enemy("bulwark",700)
	var initial_nodes:=root.get_child_count()
	var count: int=b.projectiles.slots.size()
	verify(b.projectiles.launch(b.hero,target,20),"Acquires an inactive slot")
	for i in 60: b.projectiles.tick(1.0/60.0)
	verify(target.hp<target.max_hp and b.projectiles.has_capacity(),"Impact damages through common path and frees slot")
	b.projectiles.launch(b.hero,target,20)
	target.die()
	verify(b.projectiles.slots.all(func(slot): return slot.target==null),"Target death returns all associated slots")
	target=b.spawn_enemy("kiln",900)
	var health: float=target.hp
	for i in count: b.projectiles.launch(b.hero,target,20)
	verify(not b.projectiles.has_capacity() and not b.projectiles.launch(b.hero,target,20) and target.hp==health,"Pool saturation never converts projectile into instant damage")
	verify(b.projectiles.slots.size()==count and root.get_child_count()==initial_nodes,"Pool does not instantiate projectile nodes")
	b.resources.mana=100
	b.registry.rebuild()
	verify(not b.cast_skill(0) and b.resources.mana==100,"Full pool rejects skill without spending mana")
	b.finish("defeat")
	verify(b.projectiles.slots.all(func(slot): return not slot.active and slot.target==null),"Stage end clears all slots")
	await dispose(b)

func resources_and_cooldowns() -> void:
	begin("resources_delta_caps_costs_cooldowns","Unit / Integration")
	var b=fixture()
	var resources=b.resources
	resources.supply=0
	resources.mana=0
	for i in 60: resources.tick(1.0/60.0)
	var supply: float=resources.supply
	var mana: float=resources.mana
	resources.supply=0
	resources.mana=0
	for i in 30: resources.tick(1.0/30.0)
	verify(is_equal_approx(resources.supply,supply) and is_equal_approx(resources.mana,mana),"30 and 60 Hz recovery match")
	resources.tick(100)
	verify(resources.supply==100 and resources.mana==100,"Both resources clamp to maxima")
	resources.supply=0
	verify(not b.summon(0) and b.team_count(0)==0,"Insufficient supply prevents spawn")
	resources.supply=100
	verify(b.summon(0) and resources.supply==80,"Summon debit is exact")
	verify(not b.summon(0) and resources.supply==80,"Cooldown failure never debits supply")
	resources.mana=0
	verify(not b.cast_skill(2),"Insufficient mana prevents heal skill")
	resources.mana=100
	verify(b.cast_skill(2) and resources.mana==65,"Skill mana debit is exact")
	verify(not b.cast_skill(2) and resources.mana==65,"Skill cooldown does not spend mana twice")
	await dispose(b)

func save_bad_values() -> void:
	begin("save_invalid_missing_migration_and_ownership","Save Persistence")
	var original_path: String=save.save_path
	save.save_path="user://missing-audit-"+str(Time.get_ticks_usec())+".json"
	verify(save.load_game() and save.state.gold==180,"Missing save uses defaults")
	save.save_path=original_path
	var file:=FileAccess.open(save.save_path,FileAccess.WRITE)
	file.store_string('{"save_version":1,"gold":-50,"hero_level":-5,"hero_exp":-1,"unlocked_stage":999,"unit_levels":{"cinder":-10,"unknown":5},"owned_equipment":["wickblade","trail_ring","bad"],"equipped":{"weapon":"bad","ring_a":"trail_ring","ring_b":"trail_ring"},"settings":{"master":2,"music":"bad","sfx":-9},"cleared":[1,"bad",99]}')
	file.close()
	verify(save.load_game(),"Invalid values load without crash")
	verify(save.state.gold==0 and save.state.hero_level==1 and save.state.unlocked_stage==10 and save.state.unit_levels.cinder==1,"Progress values sanitized")
	verify(not save.state.owned_equipment.has("bad") and save.state.equipped.weapon=="" and save.state.equipped.ring_b=="","Ownership and duplicate slots sanitized")
	verify(save.state.settings.master==1 and save.state.settings.sfx==0 and save.state.settings.music==0.45,"Settings sanitized")
	file=FileAccess.open(save.save_path,FileAccess.WRITE)
	file.store_string('{"save_version":{"bad":1}}')
	file.close()
	var loaded: bool=save.load_game()
	verify(not loaded or save.state.save_version==1,"Malformed version handled without crash")
	save.future_version=false
	save.state=save.defaults()
	save.save_path="user://missing-parent-"+str(Time.get_ticks_usec())+"/save.json"
	verify(not save.save_game() and save.last_error!="","Write failure is surfaced")
	save.save_path=original_path
	save.state=save.defaults()
	save.last_error=""

func content_and_equipment() -> void:
	begin("all_content_reachable_and_equipment_stats","Scene / Integration")
	save.state=save.defaults()
	var b=fixture()
	for i in 6:
		b.resources.supply=100
		verify(b.summon(i),"Friendly roster summon "+str(data.roster()[i]))
	for id in data.enemies:
		verify(b.spawn_enemy(id)!=null,"Enemy/Boss spawn "+id)
	await dispose(b)
	for id in data.equipment:
		save.state.owned_equipment.append(id)
		var slot: String="weapon" if data.equipment[id].slot=="weapon" else "ring_b"
		verify(save.equip(slot,id),"Equipment equip "+id)
		var mods: Dictionary=save.equipment_modifiers()
		var correct:=true
		for stat in data.equipment[id].stats:
			correct=correct and float(mods.get(stat,0))>=float(data.equipment[id].stats[stat])
		verify(correct,"Equipment modifier "+id)
	var equipped=fixture()
	verify(equipped.hero.stats.attack==data.rules.hero.attack+save.equipment_modifiers().get("attack",0),"Equipped weapon applies to runtime hero")
	verify(equipped.aura.radius==data.rules.aura.range+save.equipment_modifiers().get("aura_range",0),"Equipped aura range applies at battle creation")
	await dispose(equipped)
	save.state=save.defaults()

func performance_profile() -> void:
	begin("50_and_100_entities_cpu_and_cleanup","Performance / Scene")
	for population in [50,100]:
		var b=fixture()
		for i in population-3:
			b._spawn(data.units.cinder if i%2==0 else data.enemies.bulwark,i%2,650+(i%2)*350+(i/2)*2)
		b.registry.rebuild()
		var ticks: Array=[]
		var start_memory: int=Performance.get_monitor(Performance.MEMORY_STATIC)
		var query_start:=Time.get_ticks_usec()
		for repeat in 20:
			for entity in b.registry.entities: b.registry.find_target(entity)
		var query_us:=Time.get_ticks_usec()-query_start
		for frame in 300:
			var start:=Time.get_ticks_usec()
			b.simulate(1.0/60.0)
			ticks.append(Time.get_ticks_usec()-start)
		ticks.sort()
		var stats={"entities_initial":population,"entities_end":b.registry.entities.size(),"ticks":300,"tick_median_us":ticks[150],"tick_p95_us":ticks[285],"target_queries":population*20,"target_query_total_us":query_us,"projectile_slots":b.projectiles.slots.size(),"active_projectiles":b.projectiles.slots.filter(func(slot):return slot.active).size(),"memory_before":start_memory,"memory_after":int(Performance.get_monitor(Performance.MEMORY_STATIC)),"fps":"NOT MEASURED: headless synchronous CPU sample"}
		performance_samples.append(stats)
		verify(b.registry.entities.size()<=population and b.projectiles.slots.size()==64,"Entity and projectile bounds at "+str(population),stats)
		verify(b.registry.entities.all(func(entity):return is_instance_valid(entity) and entity.alive),"No dead registry entries at "+str(population))
		await dispose(b)


func save_transaction_failures() -> void:
	begin("save_transaction_rollback", "Save Persistence / Regression")
	save.state=save.defaults()
	save.state.owned_equipment.append("sunspike")
	var before: Dictionary=save.state.duplicate(true)
	save.save_path="user://missing-directory/progress.json"
	verify(not save.upgrade_unit("cinder") and save.state==before,"Failed upgrade rolls back gold and level")
	verify(not save.equip("weapon","sunspike") and save.state==before,"Failed equip rolls back slots")
	var reward: Dictionary=save.reward_stage(data.stages[0])
	verify(not reward.saved and reward.gold==0 and save.state==before,"Failed reward rolls back progress and reports unsaved")
	verify(not save.set_setting("music",0.1) and save.state==before,"Failed setting rolls back")
	save.save_path="user://audit-fixture.json"
	verify(save.reward_stage(data.stages[0]).saved and save.state.unlocked_stage==2,"Reward retry commits exactly once")
	verify(save.load_game() and save.state.gold==310,"Retry persisted without duplicate reward")

func support_positioning() -> void:
	begin("support_rear_positioning", "Scene / Regression")
	for side in [0,1]:
		save.state=save.defaults()
		var b=fixture()
		var x:=650.0 if side==0 else 1450.0
		var direction:=1.0 if side==0 else -1.0
		var support=b._spawn(data.units.mender if side==0 else data.enemies.cantor,side,x)
		var front=b._spawn(data.units.bastion,side,x+direction*180)
		var foe=b._spawn(data.enemies.bulwark,1-side,x+direction*300)
		front.support_time=100.0
		b.registry.rebuild()
		for i in 300: support.tick(1.0/60.0)
		verify((front.position.x-support.position.x)*direction>=90,"Support stays behind healthy/buffed frontline side "+str(side))
		verify((foe.position.x-support.position.x)*direction>100,"Support does not cross enemy side "+str(side))
		front.hp=front.max_hp-60
		front.support_time=0
		support.search_timer=0
		for i in 90: support.tick(1.0/60.0)
		verify(front.hp>front.max_hp-60 if side==0 else front.support_time>0,"Support performs heal or buff side "+str(side))
		front.die()
		await process_frame
		b.registry.rebuild()
		var before: float=support.position.x
		for i in 180: support.tick(1.0/60.0)
		verify(support.target==null and (support.position.x-before)*direction<=5,"Dead support target released; no runaway advance side "+str(side))
		await dispose(b)

