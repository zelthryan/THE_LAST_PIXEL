extends CharacterBody2D
## THE LAST PIXEL — the player: a tiny glowing white pixel in the void.
## WASD / arrow movement at ~240 px/s with snappy accel/decel,
## a subtle breathing glow, and soft looping movement noise
## that fades in and out with velocity.

const SPEED := 240.0
const ACCEL := 1500.0
const DECEL := 1800.0
const MOVE_DB := -22.0

var active := true
var _moving := false
var _time := 0.0

@onready var move_sound: AudioStreamPlayer = $MoveSound
@onready var glow1: Polygon2D = $Glow1
@onready var glow2: Polygon2D = $Glow2

func _ready() -> void:
	add_to_group("player")
	move_sound.finished.connect(_on_move_finished)

func _physics_process(delta: float) -> void:
	if not active:
		velocity = Vector2.ZERO
		_moving = false
		_fade_move_sound(delta)
		return

	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	_moving = dir.length_squared() > 0.0
	if _moving:
		velocity = velocity.move_toward(dir * SPEED, ACCEL * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, DECEL * delta)
	move_and_slide()

	_time += delta
	glow1.color.a = 0.16 + 0.05 * sin(_time * 2.2)
	glow2.color.a = 0.07 + 0.03 * sin(_time * 1.7 + 1.0)

	if _moving:
		if not move_sound.playing:
			move_sound.volume_db = MOVE_DB - 10.0
			move_sound.play()
		move_sound.volume_db = move_toward(move_sound.volume_db, MOVE_DB, delta * 24.0)
	else:
		_fade_move_sound(delta)

func _fade_move_sound(delta: float) -> void:
	if move_sound.playing:
		move_sound.volume_db = move_toward(move_sound.volume_db, -60.0, delta * 40.0)
		if move_sound.volume_db <= -55.0:
			move_sound.stop()

func _on_move_finished() -> void:
	if active and _moving:
		move_sound.play()
