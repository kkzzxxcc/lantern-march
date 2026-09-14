extends SceneTree

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var save=root.get_node("Save")
	save.save_path="user://restart-probe.json"
	var args:=OS.get_cmdline_user_args()
	if args.has("write"):
		save.state=save.defaults()
		save.reward_stage(root.get_node("Data").stages[0])
		save.upgrade_unit("cinder")
		save.equip("weapon","sunspike")
		save.state.settings.music=0.32
		var success: bool=save.save_game()
		print("SAVE WRITE ","PASS" if success else "FAIL"," path=",ProjectSettings.globalize_path(save.save_path))
		quit(0 if success else 1)
	else:
		var success: bool=save.load_game() and save.state.gold==210 and save.state.unlocked_stage==2 and save.state.unit_levels.get("cinder",0)==2 and save.state.equipped.weapon=="sunspike" and is_equal_approx(save.state.settings.music,0.32)
		print("FRESH PROCESS LOAD ","PASS" if success else "FAIL"," state=",JSON.stringify(save.state))
		quit(0 if success else 1)

