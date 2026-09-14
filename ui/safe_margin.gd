class_name SafeMargin
extends MarginContainer

func _ready() -> void:
	get_viewport().size_changed.connect(_resize)
	_resize()

func _resize() -> void:
	var margins := [28, 28, 22, 22]
	if OS.has_feature("android") or OS.has_feature("ios"):
		var safe := DisplayServer.get_display_safe_area()
		var screen := DisplayServer.screen_get_size()
		var scale_factor := get_viewport().get_visible_rect().size / Vector2(screen)
		margins = [maxi(28,int(safe.position.x*scale_factor.x)), maxi(28,int((screen.x-safe.end.x)*scale_factor.x)), maxi(22,int(safe.position.y*scale_factor.y)), maxi(22,int((screen.y-safe.end.y)*scale_factor.y))]
	elif OS.has_feature("web"):
		var web_margins := WebAdapter.safe_margins(get_viewport().get_visible_rect().size.x)
		for i in 4: margins[i] = maxi(margins[i], web_margins[i])
	for i in 4:
		add_theme_constant_override("margin_" + ["left","right","top","bottom"][i],margins[i])

