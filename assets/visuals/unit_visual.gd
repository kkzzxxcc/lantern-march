class_name UnitVisual
extends Node2D

var boxes: Dictionary = {}
var unit

func _draw() -> void:
	if unit == null or unit.stats.is_empty():
		return
	var color := Color(unit.stats.color)
	var dark := color.darkened(0.55)
	var light := Color("f5e7bf")
	var facing := 1.0 if unit.team == 0 else -1.0
	var bob := sin(unit.motion) * 2.0
	if unit.flash > 0:
		color = Color("fff3d1")
	draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.28))
	draw_circle(Vector2.ZERO, unit.radius * 1.3, Color(0.015, 0.035, 0.04, 0.4))
	draw_set_transform(Vector2.ZERO)
	if unit.is_base:
		_draw_gate(color, dark, light)
		return
	var role: String = unit.stats.role
	var scale_factor := 1.5 if role == "boss" else (1.18 if role == "tank" else 1.0)
	if unit.stats.get("visual_float", false):
		bob -= 28.0
	draw_set_transform(Vector2(0, bob), 0, Vector2(facing * scale_factor, scale_factor))
	if role == "siege":
		draw_style_box(_box(dark), Rect2(-30, -39, 61, 27))
		draw_line(Vector2(-8, -32), Vector2(38, -61), color, 16, true)
		for x in [-20, 20]:
			draw_circle(Vector2(x, -12), 13, color)
			draw_circle(Vector2(x, -12), 6, dark)
	else:
		var stride := sin(unit.motion) * 5
		draw_line(Vector2(-9, -22), Vector2(-11 - stride, -3), dark, 9, true)
		draw_line(Vector2(8, -22), Vector2(10 + stride, -3), dark, 9, true)
		draw_colored_polygon(PackedVector2Array([Vector2(-18,-53),Vector2(9,-51),Vector2(20,-15),Vector2(-23,-15)]), dark)
		draw_style_box(_box(color), Rect2(-13, -53, 28, 30))
		draw_circle(Vector2(0, -66), 14, color)
		draw_style_box(_box(dark), Rect2(-7, -69, 22, 7))
		draw_line(Vector2(7, -66), Vector2(12, -66), light, 2)
		match role:
			"hero":
				draw_colored_polygon(PackedVector2Array([Vector2(-12,-52),Vector2(-23,-16),Vector2(-41,-9),Vector2(-28,-58)]), Color("4f9b96"))
				draw_line(Vector2(18,-38), Vector2(32,-87), dark, 5, true)
				draw_circle(Vector2(32,-69), 17, Color(1, 0.79, 0.4, 0.11))
				draw_style_box(_box(light), Rect2(26,-77,13,19))
				draw_line(Vector2(-1,-79),Vector2(-17,-85),Color("8acabb"),5)
			"tank":
				draw_colored_polygon(PackedVector2Array([Vector2(5,-54),Vector2(33,-54),Vector2(35,-25),Vector2(19,-13),Vector2(3,-25)]), color.lightened(0.15))
				draw_line(Vector2(19,-48),Vector2(19,-24),dark,4)
			"ranged":
				draw_arc(Vector2(20,-46),23,-1.35,1.35,20,color,3,true)
				draw_line(Vector2(25,-69),Vector2(25,-23),light,1)
				draw_line(Vector2(11,-45),Vector2(44 + unit.attack_pose*18,-45),light,2)
			"aoe", "healer", "support", "special":
				draw_line(Vector2(22,-5),Vector2(22,-78),dark,5)
				draw_circle(Vector2(22,-80),10,color.lightened(0.25))
				draw_arc(Vector2(22,-80),16,0,TAU,20,Color(color,0.5),2,true)
				if role == "healer":
					draw_line(Vector2(17,-80),Vector2(27,-80),light,3)
					draw_line(Vector2(22,-85),Vector2(22,-75),light,3)
			"boss":
				draw_colored_polygon(PackedVector2Array([Vector2(-17,-76),Vector2(-22,-97),Vector2(-4,-84),Vector2(7,-102),Vector2(15,-76)]),color)
				draw_line(Vector2(15,-40),Vector2(40+unit.attack_pose*20,-61),dark,12,true)
			_:
				draw_line(Vector2(14,-35),Vector2(33+unit.attack_pose*20,-58),light,5,true)
				draw_line(Vector2(17,-47),Vector2(31,-34),dark,5)
	draw_set_transform(Vector2.ZERO)
	if unit.aura_active:
		draw_circle(Vector2(0, -91*scale_factor), 4, Color("91d7b8"))
	if unit.hp < unit.max_hp or unit.is_hero or role == "boss":
		var width := 74.0 if role == "boss" else 44.0
		var y := -108.0 * scale_factor
		draw_rect(Rect2(-width/2,y,width,5),Color("152a30"))
		draw_rect(Rect2(-width/2,y,width*unit.hp/unit.max_hp,5),Color("91c8a9") if unit.team==0 else Color("d69398"))

func _draw_gate(color: Color, dark: Color, light: Color) -> void:
	draw_style_box(_box(dark), Rect2(-48,-150,96,150))
	draw_style_box(_box(color.darkened(0.28)), Rect2(-39,-162,78,27))
	for x in [-49,28]:
		draw_style_box(_box(color),Rect2(x,-182,22,185))
		draw_colored_polygon(PackedVector2Array([Vector2(x-5,-182),Vector2(x+11,-211),Vector2(x+27,-182)]),color)
	draw_style_box(_box(Color("0e202a")),Rect2(-23,-89,46,89))
	draw_circle(Vector2(0,-121),14,light if unit.team==0 else Color("df9aa0"))
	draw_rect(Rect2(-52,-230,104,7),Color("182e34"))
	draw_rect(Rect2(-52,-230,104*unit.hp/unit.max_hp,7),color)

func _box(color: Color) -> StyleBoxFlat:
	if boxes.has(color):
		return boxes[color]
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.corner_radius_top_left=3
	box.corner_radius_top_right=3
	boxes[color] = box
	return box
