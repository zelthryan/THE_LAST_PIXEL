extends Area2D
## THE LAST PIXEL — shared behaviour for the three geometric object types.
## MEMORY_NODE (outlined circle, wobbles), FRAGMENT (rotating diamond),
## ANCHOR (large outlined triangle + inner counter-shape).
## All visuals are cheap _draw() calls: white outlines on the void.

enum Kind { MEMORY_NODE, FRAGMENT, ANCHOR }

signal consumed(kind: int, at: Vector2)

@export var kind: Kind = Kind.MEMORY_NODE

var age := 0.0
var flash := 0.0
var is_consumed := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	age += delta
	if flash > 0.0:
		flash = maxf(flash - delta * 1.6, 0.0)
	match kind:
		Kind.FRAGMENT:
			rotation = age * 1.4
		Kind.ANCHOR:
			rotation = age * 0.35
	queue_redraw()

func react_to_pulse() -> void:
	if is_consumed:
		return
	flash = 1.0

func _on_body_entered(body: Node2D) -> void:
	if is_consumed or not body.is_in_group("player"):
		return
	is_consumed = true
	consumed.emit(kind, global_position)
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "scale", Vector2(1.8, 1.8), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 0.0, 0.35)
	tw.chain().tween_callback(queue_free)

func _draw() -> void:
	var a := 0.9
	var w := 2.0
	if flash > 0.0:
		w += flash * 2.5
		a = 1.0
	match kind:
		Kind.MEMORY_NODE:
			var r := 14.0 + sin(age * 2.0) * 1.8
			draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, Color(1, 1, 1, a), w, true)
			draw_arc(Vector2.ZERO, r * 0.45, 0.0, TAU, 24, Color(1, 1, 1, a * 0.5), 1.5, true)
		Kind.FRAGMENT:
			var diamond := PackedVector2Array([Vector2(0, -9), Vector2(6.5, 0), Vector2(0, 9), Vector2(-6.5, 0), Vector2(0, -9)])
			draw_polyline(diamond, Color(1, 1, 1, a), w, true)
		Kind.ANCHOR:
			var tri := PackedVector2Array()
			for i in 3:
				var ang := -PI / 2.0 + TAU * float(i) / 3.0
				tri.append(Vector2(cos(ang), sin(ang)) * 26.0)
			tri.append(tri[0])
			draw_polyline(tri, Color(1, 1, 1, a), w, true)
			var s := 10.0 + sin(age * 1.5) * 1.5
			var square := PackedVector2Array([Vector2(-s, -s), Vector2(s, -s), Vector2(s, s), Vector2(-s, s), Vector2(-s, -s)])
			draw_polyline(square, Color(1, 1, 1, a * 0.6), 1.5, true)
	if flash > 0.0:
		draw_arc(Vector2.ZERO, 22.0 + (1.0 - flash) * 20.0, 0.0, TAU, 36, Color(1, 1, 1, flash * 0.7), 2.0, true)
