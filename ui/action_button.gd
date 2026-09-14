class_name ActionButton
extends Button

var action := ""
var fingers: Dictionary = {}
var mouse_down := false

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button_down.connect(func():
		if fingers.is_empty():
			mouse_down = true
			_dispatch(true))
	button_up.connect(func():
		mouse_down = false
		if fingers.is_empty(): _dispatch(false))

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		var local: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
		if event.pressed and Rect2(Vector2.ZERO, size).has_point(local) and not disabled:
			fingers[event.index] = true
			_dispatch(true)
			get_viewport().set_input_as_handled()
		elif not event.pressed and fingers.has(event.index):
			fingers.erase(event.index)
			if fingers.is_empty() and not mouse_down: _dispatch(false)
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and fingers.has(event.index):
		var local: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
		if not Rect2(Vector2.ZERO,size).grow(20).has_point(local):
			fingers.erase(event.index)
			if fingers.is_empty() and not mouse_down: _dispatch(false)

func _dispatch(pressed: bool) -> void:
	if action == "":
		return
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_EXIT_TREE or (what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree()):
		fingers.clear()
		mouse_down = false
		if action != "": Input.action_release(action)


