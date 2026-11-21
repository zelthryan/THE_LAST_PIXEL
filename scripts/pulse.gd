extends Node2D
## THE LAST PIXEL — expanding ring effect.
## One lightweight draw call per frame, no shaders. Used for the player's
## pulse and for the smaller ripples spawned by objects and trail
## reconnections. Spawn it, set the parameters, add it to the tree.

var max_radius := 220.0
var duration := 0.7
var line_width := 3.0
var start_alpha := 0.9
var fill := false

var _t := 0.0

func _process(delta: float) -> void:
	_t += delta
	if _t >= duration:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var k := clampf(_t / duration, 0.0, 1.0)
	var eased := 1.0 - pow(1.0 - k, 2.4)
	var r := max_radius * eased
	var a := start_alpha * (1.0 - k)
	if fill:
		draw_circle(Vector2.ZERO, r, Color(1, 1, 1, 0.04 + 0.06 * a))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(1, 1, 1, a), line_width, true)
