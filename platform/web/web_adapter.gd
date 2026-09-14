class_name WebAdapter
extends RefCounted

static func safe_margins(viewport_width: float) -> Array:
	var values := [0, 0, 0, 0]
	if not OS.has_feature("web"): return values
	var css_width = JavaScriptBridge.eval("window.innerWidth")
	if not (css_width is float or css_width is int) or css_width <= 0: return values
	for i in 4:
		var side: String = ["left","right","top","bottom"][i]
		var pixels = JavaScriptBridge.eval("parseFloat(getComputedStyle(document.documentElement).getPropertyValue('--safe-" + side + "')) || 0")
		if pixels is float or pixels is int: values[i] = int(float(pixels) * viewport_width / float(css_width))
	return values
