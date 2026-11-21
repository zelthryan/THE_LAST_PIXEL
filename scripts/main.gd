extends Node2D
## THE LAST PIXEL — main controller.
## Spawns the fixed object layout, owns world stability, the pulse ability,
## the trail-reconnection reward, the minimal UI, audio and the game-over
## sequence. The game starts immediately — there is no menu.

const Ring = preload("res://scripts/pulse.gd")
const MemoryNodeScene = preload("res://scenes/memory_node.tscn")
const FragmentScene = preload("res://scenes/fragment.tscn")
const AnchorScene = preload("res://scenes/anchor.tscn")

const KIND_MEMORY_NODE := 0
const KIND_FRAGMENT := 1
const KIND_ANCHOR := 2

const STABILITY_MAX := 100.0
const DRAIN_PER_SEC := 3.0
const NODE_STABILITY := 18.0
const NODE_TRAIL_BONUS := 2.0
const CONNECT_STABILITY := 8.0
const CONNECT_TRAIL_BONUS := 0.75
const ANCHOR_DURATION := 10.0
const ANCHOR_STABILITY := 5.0
const PULSE_COOLDOWN := 2.5
const PULSE_RADIUS := 220.0
const CONNECT_RADIUS := 26.0

var stability := STABILITY_MAX
var discovery := 0
var pulse_cd := 0.0
var reconnect_cd := 0.0
var anchor_timer := 0.0
var connect_check := 0.0
var go_time := 0.0
var game_over := false

@onready var player: CharacterBody2D = $Player
@onready var trail: Line2D = $Trail
@onready var world: Node2D = $WorldObjects
@onready var effects: Node2D = $Effects
@onready var ambient: AudioStreamPlayer = $Audio/Ambient
@onready var sfx_pulse: AudioStreamPlayer = $Audio/SfxPulse
@onready var sfx_discover: AudioStreamPlayer = $Audio/SfxDiscover
@onready var sfx_connect: AudioStreamPlayer = $Audio/SfxConnect
@onready var sfx_gameover: AudioStreamPlayer = $Audio/SfxGameOver
@onready var discovery_label: Label = $UI/DiscoveryLabel
@onready var stability_fill: ColorRect = $UI/StabilityTrack/StabilityFill
@onready var pulse_fill: ColorRect = $UI/PulseTrack/PulseFill
@onready var hint_label: Label = $UI/HintLabel
@onready var game_over_ui: Control = $UI/GameOver
@onready var go_dim: ColorRect = $UI/GameOver/Dim
@onready var go_flash: ColorRect = $UI/GameOver/Flash
@onready var go_score: Label = $UI/GameOver/Center/VBox/GoScore
@onready var go_hint: Label = $UI/GameOver/Center/VBox/GoHint

func _ready() -> void:
	_spawn_world()
	ambient.finished.connect(ambient.play)
	ambient.play()
	var tw := create_tween()
	tw.tween_interval(6.0)
	tw.tween_property(hint_label, "modulate:a", 0.0, 1.5)

func _physics_process(_delta: float) -> void:
	if not game_over:
		trail.add_sample(player.global_position)

func _process(delta: float) -> void:
	if game_over:
		go_time += delta
		if go_time > 1.6:
			var blink := clampf((go_time - 1.6) * 2.0, 0.0, 1.0)
			go_hint.modulate.a = blink * (0.6 + 0.4 * sin((go_time - 1.6) * 5.0))
		if Input.is_action_just_pressed("restart") or Input.is_action_just_pressed("confirm"):
			get_tree().reload_current_scene()
		return

	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()
		return
	if Input.is_action_just_pressed("pulse"):
		_try_pulse()

	pulse_cd = maxf(pulse_cd - delta, 0.0)
	reconnect_cd = maxf(reconnect_cd - delta, 0.0)
	if anchor_timer > 0.0:
		anchor_timer -= delta
		if anchor_timer <= 0.0:
			trail.lifetime_scale = 1.0

	var drain := DRAIN_PER_SEC
	if anchor_timer > 0.0:
		drain *= 0.5
	stability -= drain * delta

	if not ambient.playing:
		ambient.play()

	_update_bars()

	connect_check += delta
	if connect_check >= 0.1:
		connect_check = 0.0
		_check_connection()

	if stability <= 0.0:
		_do_game_over()

# --- world -------------------------------------------------------------------

func _spawn_world() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261121
	var placed: Array[Vector2] = []
	_scatter(rng, 9, 320.0, 900.0, MemoryNodeScene, placed)
	_scatter(rng, 14, 160.0, 1150.0, FragmentScene, placed)
	_scatter(rng, 3, 520.0, 860.0, AnchorScene, placed)

func _scatter(rng: RandomNumberGenerator, count: int, min_r: float, max_r: float, packed_scene: PackedScene, placed: Array[Vector2]) -> void:
	var done := 0
	var tries := 0
	while done < count and tries < 400:
		tries += 1
		var pos := Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(min_r, max_r)
		var ok := true
		for p in placed:
			if p.distance_to(pos) < 130.0:
				ok = false
				break
		if not ok:
			continue
		placed.append(pos)
		var obj = packed_scene.instantiate()
		obj.position = pos
		obj.consumed.connect(_on_object_consumed)
		world.add_child(obj)
		done += 1

# --- abilities and rewards -----------------------------------------------------

func _try_pulse() -> void:
	if pulse_cd > 0.0:
		return
	pulse_cd = PULSE_COOLDOWN
	_spawn_ring(player.global_position, PULSE_RADIUS, 0.7, 3.0, 0.9, true)
	for obj in world.get_children():
		if obj.is_consumed:
			continue
		if obj.global_position.distance_to(player.global_position) <= PULSE_RADIUS:
			obj.react_to_pulse()
	sfx_pulse.play()

func _check_connection() -> void:
	if reconnect_cd > 0.0:
		return
	for i in trail.point_count():
		if trail.point_age(i) < 0.9:
			continue
		if trail.point_pos(i).distance_to(player.global_position) <= CONNECT_RADIUS:
			reconnect_cd = 2.0
			stability = minf(stability + CONNECT_STABILITY, STABILITY_MAX)
			trail.bonus_lifetime += CONNECT_TRAIL_BONUS
			_spawn_ring(trail.point_pos(i), 70.0, 0.5, 2.5, 0.9)
			sfx_connect.play()
			break

func _on_object_consumed(kind: int, at: Vector2) -> void:
	if game_over:
		return
	match kind:
		KIND_MEMORY_NODE:
			stability = minf(stability + NODE_STABILITY, STABILITY_MAX)
			trail.bonus_lifetime += NODE_TRAIL_BONUS
			_spawn_ring(at, 90.0, 0.6, 2.5, 0.8)
			sfx_discover.pitch_scale = 1.0
			sfx_discover.play()
		KIND_FRAGMENT:
			discovery += 1
			discovery_label.text = "DISCOVERED %d" % discovery
			_spawn_ring(at, 60.0, 0.45, 2.0, 0.7)
			sfx_discover.pitch_scale = randf_range(1.05, 1.25)
			sfx_discover.play()
		KIND_ANCHOR:
			anchor_timer = ANCHOR_DURATION
			trail.lifetime_scale = 2.0
			stability = minf(stability + ANCHOR_STABILITY, STABILITY_MAX)
			_spawn_ring(at, 160.0, 0.9, 3.0, 0.85)
			sfx_connect.play()

func _spawn_ring(pos: Vector2, radius: float, duration: float, width: float, alpha: float, filled := false) -> void:
	var ring = Ring.new()
	ring.position = pos
	ring.max_radius = radius
	ring.duration = duration
	ring.line_width = width
	ring.start_alpha = alpha
	ring.fill = filled
	effects.add_child(ring)

# --- UI ------------------------------------------------------------------------

func _update_bars() -> void:
	var frac := clampf(stability / STABILITY_MAX, 0.0, 1.0)
	stability_fill.size = Vector2(300.0 * frac, 8.0)
	if frac < 0.2:
		stability_fill.modulate.a = 0.55 + 0.45 * sin(Time.get_ticks_msec() * 0.012)
	else:
		stability_fill.modulate.a = 1.0
	var pf := 1.0
	if pulse_cd > 0.0:
		pf = 1.0 - pulse_cd / PULSE_COOLDOWN
	pulse_fill.size = Vector2(140.0 * clampf(pf, 0.0, 1.0), 8.0)
	pulse_fill.modulate.a = 1.0 if pulse_cd <= 0.0 else 0.55

# --- game over ------------------------------------------------------------------

func _do_game_over() -> void:
	game_over = true
	stability = 0.0
	go_time = 0.0
	trail.active = false
	player.active = false
	go_hint.modulate.a = 0.0
	go_score.text = "DISCOVERED %d" % discovery
	game_over_ui.visible = true
	sfx_gameover.play()
	var tw := create_tween()
	tw.tween_property(go_flash, "color:a", 0.65, 0.12)
	tw.tween_property(go_flash, "color:a", 0.0, 0.3)
	tw.tween_property(go_dim, "color:a", 0.88, 1.0)
	tw.parallel().tween_property(game_over_ui, "modulate:a", 1.0, 1.1)
	var fade := create_tween()
	fade.tween_property(ambient, "volume_db", -50.0, 2.5)
