extends Node

var screen: Node
var selected_stage := 1
var orientation_notice: ColorRect
const SCREENS := {"main_menu":"res://scenes/main_menu/main_menu.tscn", "stage_select":"res://scenes/stage_select/stage_select.tscn", "upgrade":"res://scenes/upgrade/upgrade.tscn", "equipment":"res://scenes/equipment/equipment.tscn", "settings":"res://scenes/settings/settings.tscn"}

func _ready() -> void:
	show_screen("main_menu")
	_build_orientation_notice()

func _clear() -> void:
	if is_instance_valid(screen):
		remove_child(screen)
		screen.queue_free()
	Input.action_release("move_left")
	Input.action_release("move_right")

func show_screen(id: String) -> void:
	if not SCREENS.has(id): return
	_clear()
	screen=load(SCREENS[id]).instantiate()
	add_child(screen)

func start_battle(id: int) -> void:
	if id<1 or id>Data.stages.size() or id>Save.state.unlocked_stage: return
	selected_stage=id
	_clear()
	screen=load("res://scenes/battle/battle.tscn").instantiate()
	screen.stage=Data.stages[id-1].duplicate(true)
	add_child(screen)
	Audio.start_music()


func _build_orientation_notice() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	orientation_notice = ColorRect.new()
	orientation_notice.color = Color("0d252e")
	UIKit.fill(orientation_notice)
	layer.add_child(orientation_notice)
	var center := CenterContainer.new()
	UIKit.fill(center)
	orientation_notice.add_child(center)
	var label := UIKit.label("TURN TOWARD THE DAWN\n\nRotate your device to landscape.", 30, UIKit.GOLD)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(label)
	get_viewport().size_changed.connect(_orientation_changed)
	_orientation_changed()

func _orientation_changed() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	orientation_notice.visible = viewport_size.x < viewport_size.y
	if orientation_notice.visible and screen is BattleManager and screen.status == "running":
		screen.status = "paused"
		screen.hud.show_pause(true)
