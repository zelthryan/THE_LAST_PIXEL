extends Line2D
## THE LAST PIXEL — memory trail (the most important mechanic).
## Records the player's path as points with ages on a Line2D.
## Old points are removed when they exceed the effective lifetime, the
## gradient + width taper fade the line toward its oldest end, and the
## point count is capped for performance. Points are only sampled when the
## player has moved far enough, never blindly every frame.
## The trail is "the world": its lifetime reacts to pickups and anchors.

const MAX_POINTS := 400
const BASE_LIFETIME := 4.5
const SAMPLE_DIST := 12.0

var lifetime_scale := 1.0   # anchor sets this to 2.0 for a while (fading slowed)
var bonus_lifetime := 0.0   # temporary +seconds from nodes/reconnections, decays
var active := true          # sampling stops on game over

var _pts := PackedVector2Array()
var _ages := PackedFloat32Array()

func effective_lifetime() -> float:
	return (BASE_LIFETIME + bonus_lifetime) * lifetime_scale

func add_sample(pos: Vector2) -> void:
	if not active:
		return
	if _pts.size() > 0 and _pts[_pts.size() - 1].distance_to(pos) < SAMPLE_DIST:
		return
	_pts.append(pos)
	_ages.append(0.0)
	if _pts.size() > MAX_POINTS:
		var over := _pts.size() - MAX_POINTS
		_pts = _pts.slice(over)
		_ages = _ages.slice(over)
	points = _pts

func point_count() -> int:
	return _pts.size()

func point_pos(i: int) -> Vector2:
	return _pts[i]

func point_age(i: int) -> float:
	return _ages[i]

func _process(delta: float) -> void:
	if bonus_lifetime > 0.0:
		bonus_lifetime = maxf(bonus_lifetime - delta * 0.12, 0.0)
	for i in _ages.size():
		_ages[i] += delta
	var life := effective_lifetime()
	var expired := 0
	while expired < _ages.size() and _ages[expired] > life:
		expired += 1
	var changed := expired > 0
	if changed:
		_pts = _pts.slice(expired)
		_ages = _ages.slice(expired)
	if _pts.size() > MAX_POINTS:
		var over := _pts.size() - MAX_POINTS
		_pts = _pts.slice(over)
		_ages = _ages.slice(over)
		changed = true
	if changed:
		points = _pts
