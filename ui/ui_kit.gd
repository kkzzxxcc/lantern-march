class_name UIKit
extends RefCounted

const INK := Color("0d252e")
const PANEL := Color("18363e")
const GOLD := Color("e7bc7b")
const TEXT := Color("f1e8d4")
const MUTED := Color("9db4b2")

static func style(color: Color, border: Color = Color.TRANSPARENT, radius: int = 10) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 12
	box.content_margin_bottom = 12
	return box

static func theme() -> Theme:
	var result := Theme.new()
	result.default_font_size = 18
	result.default_font = preload("res://assets/fonts/NotoSansKR.ttf")
	result.set_color("font_color", "Label", TEXT)
	result.set_color("font_color", "Button", TEXT)
	result.set_color("font_hover_color", "Button", Color.WHITE)
	result.set_color("font_disabled_color", "Button", Color("6c868a"))
	result.set_stylebox("normal", "Button", style(PANEL, Color("3d5a5d")))
	result.set_stylebox("hover", "Button", style(Color("2d5055"), GOLD))
	result.set_stylebox("pressed", "Button", style(Color("395e5d"), GOLD))
	result.set_stylebox("focus", "Button", style(Color(0,0,0,0), GOLD))
	result.set_stylebox("disabled", "Button", style(Color("142e36"), Color("28424a")))
	result.set_constant("separation", "HBoxContainer", 12)
	result.set_constant("separation", "VBoxContainer", 12)
	result.set_constant("h_separation", "GridContainer", 14)
	result.set_constant("v_separation", "GridContainer", 14)
	return result

static func label(text: String, size: int = 18, color: Color = TEXT) -> Label:
	var node := Label.new()
	node.text = TranslationServer.translate(text)
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	return node

static func button(text: String, callback: Callable, minimum: Vector2 = Vector2(160, 54)) -> Button:
	var node := Button.new()
	node.text = TranslationServer.translate(text)
	node.custom_minimum_size = minimum
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var guarded := func():
		if is_instance_valid(node) and node.is_inside_tree(): callback.call()
	node.pressed.connect(func(): Audio.start_music(); Audio.play("click"); guarded.call_deferred())
	return node

static func panel() -> PanelContainer:
	var node := PanelContainer.new()
	node.add_theme_stylebox_override("panel", style(PANEL, Color("37535a")))
	return node

static func fill(control: Control) -> void:
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

static func spacer() -> Control:
	var node := Control.new()
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return node

