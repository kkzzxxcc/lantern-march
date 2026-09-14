class_name BattleGround
extends Node2D

var length := 3000.0
var ground_y := 490.0

func _draw() -> void:
	draw_rect(Rect2(-2000,-1600,length+4000,2300),Color("142d38"))
	draw_circle(Vector2(1080,112),78,Color("e0b378"))
	draw_circle(Vector2(1080,112),100,Color(0.8,0.65,0.4,0.045))
	var rng := RandomNumberGenerator.new()
	rng.seed = 6842
	for layer in 3:
		var points := PackedVector2Array([Vector2(-1000,ground_y)])
		for x in range(-1000,int(length)+1400,140):
			points.append(Vector2(x,170+layer*65+rng.randf_range(-100,45)))
		points.append(Vector2(length+1400,ground_y))
		draw_colored_polygon(points,[Color("24434c"),Color("2c5157"),Color("386164")][layer])
	for i in 32:
		var x := rng.randf_range(-400,length+400)
		var y := ground_y-35
		var height := rng.randf_range(60,145)
		draw_line(Vector2(x,y),Vector2(x+8,y-height),Color("1f454b"),8,true)
		draw_line(Vector2(x+7,y-height*0.65),Vector2(x+38,y-height*0.94),Color("1f454b"),5,true)
	draw_rect(Rect2(-2000,ground_y-12,length+4000,700),Color("17373c"))
	draw_rect(Rect2(-2000,ground_y-8,length+4000,6),Color("65817a"))
	for i in 140:
		var x := rng.randf_range(-600,length+600)
		var y := rng.randf_range(ground_y+23,ground_y+210)
		draw_line(Vector2(x,y),Vector2(x+rng.randf_range(4,35),y),Color("28494b"),2)
	for x in range(380,int(length)-200,490):
		draw_line(Vector2(x,ground_y),Vector2(x,ground_y-96),Color("283c3c"),6)
		draw_circle(Vector2(x,ground_y-92),7,Color("e4b677"))
		draw_circle(Vector2(x,ground_y-92),18,Color(0.9,0.65,0.3,0.08))

