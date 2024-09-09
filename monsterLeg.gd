extends Line2D

class_name MonsterLeg

class Point:
	var position: Vector2
	var prevPosition: Vector2
	var locked: bool
	
class Stick:
	var pointA: Point
	var pointB: Point
	var length: float
	
@export var pointCount: int = 15
@export var lineLength: float = 200.0
@export var gravity: float = 300.0
@export var numIterations: int = 100
@export var changeTime: float = 3.0 # more => faster
@export var verletSmoothness: float = 0.75 # more => more janky

var _targetGlobalPoint := Vector2(0, 0)
var _oldTargetGlobalPoint := Vector2(0, 0)
var _sourceGlobalPoint := Vector2(0, 0)
var _points: Array[Point] = [] # simulated points
var _sticks: Array[Stick] = []
var _isInited: bool = false
var _isOnGround: bool = false
var _changeTargetTimer: float = 0.0

"""from and to must be points in GLOBAL SPACE"""
func updateLeg(from: Vector2, to: Vector2, isOnGround: bool) -> void:
	_sourceGlobalPoint = from
	if not _isInited:
		_initialize(from, to)
	if (_targetGlobalPoint - to).length() > 0.1:
		_oldTargetGlobalPoint = _points[_points.size() - 1].position
		_targetGlobalPoint = to
		_changeTargetTimer = 0.0
	_isOnGround = isOnGround

func getLegLength() -> float:
	return lineLength
	
func getAllPoints() -> Array[Vector2]:
	var arr: Array[Vector2] = []
	for point in _points:
		if not point.locked:
			arr.append(to_local(point.position))
	return arr

func _initialize(from: Vector2, to: Vector2) -> void:
	_isInited = true
	_points.resize(pointCount)
	_sticks.resize(pointCount - 1)
	
	# WHY THE HELL I CAN'T JUST points.resize(pointCount)
	var newArr: Array[Vector2] = []
	newArr.resize(pointCount)
	newArr.fill(Vector2(0,0))
	self.points = newArr
	
	# Sread points between from and to
	for i in _points.size():
		_points[i] = Point.new()
		var pos: Vector2 = lerp(from, to, float(i) / float(pointCount))
		_points[i].position = pos
		_points[i].prevPosition = pos
		_points[i].locked = false
	
	# Lock first and last point
	_points[0].locked = true
	_points[pointCount - 1].locked = true
	
	for i in _sticks.size():
		_sticks[i] = Stick.new()
		_sticks[i].pointA = _points[i]
		_sticks[i].pointB = _points[i + 1]
		_sticks[i].length = lineLength / float(pointCount - 1)
	
func _ready() -> void:
	width = randf_range(8.0, 13.0)

func _process(delta: float) -> void:
	if not _isInited:
		return
	
	# Update first point
	_points[0].position = _sourceGlobalPoint
	
	# It locks some if the points in the end of the line to make it more stretched,
	# but looks kinda bad...
	var dst := (_targetGlobalPoint - _sourceGlobalPoint).length()
	var notNeededSegments: int = max(0, dst / (lineLength / _points.size()))
	notNeededSegments /= 5
	for i in range(1, pointCount):
		_points[i].locked = _isOnGround and (i >= pointCount - notNeededSegments - 1)
		if _points[i].locked:
			# Transition between old position and new using easing function
			_changeTargetTimer = min(changeTime, _changeTargetTimer + delta)
			_points[i].position = lerp(_oldTargetGlobalPoint, _targetGlobalPoint, _ease_in_out_back(_changeTargetTimer / changeTime))
	
	# Simulate rope behaviour
	_simulate(delta * 2.0)
	
	# Set Line2D points
	for pointIndex in _points.size():
		self.points[pointIndex] = to_local(_points[pointIndex].position)
		
# Easing function from https://easings.net/
func _ease_in_out_back(x: float) -> float:
	var c1 = 1.70158
	var c2 = c1 * 1.525
	if x < 0.5:
		return (pow(2 * x, 2) * ((c2 + 1) * 2 * x - c2)) / 2
	else:
		return (pow(2 * x - 2, 2) * ((c2 + 1) * (2 * x - 2) + c2) + 2) / 2
		
# Verlet Intergation https://youtu.be/PGk0rnyTa1U
func _simulate(delta: float):	
	for p in _points:
		if not p.locked:
			var positionBeforeUpdate := Vector2(p.position.x, p.position.y)
			p.position += (p.position - p.prevPosition) * verletSmoothness
			p.position += Vector2.DOWN * gravity * delta * delta
			p.prevPosition = positionBeforeUpdate
	for i in numIterations:
		for stick in _sticks:
			var stickCentre := (stick.pointA.position + stick.pointB.position) / 2.0
			var stickDir := (stick.pointA.position - stick.pointB.position).normalized()
			if not stick.pointA.locked:
				stick.pointA.position = stickCentre + stickDir * stick.length / 2.0
			if not stick.pointB.locked:
				stick.pointB.position = stickCentre - stickDir * stick.length / 2.0

# Wobly collision of lines with ground using raycast
func _physics_process(delta):
	for stick in _sticks:
		var raySource = stick.pointA.position
		var rayTarget = stick.pointB.position
		var rayDirection = (raySource - rayTarget).normalized()
		var space_state = get_world_2d().direct_space_state
		var query = PhysicsRayQueryParameters2D.create(raySource, rayTarget)
		#query.collide_with_areas = true
		query.collide_with_bodies = true
		query.collision_mask = 0b10
		var result = space_state.intersect_ray(query) 
		if result:
			stick.pointB.position = result.position + rayDirection * 2.0
			stick.pointA.locked = true
			stick.pointA.position = result.position + rayDirection * 2.0
			stick.pointB.locked = true
		elif not stick.pointA.locked:
			stick.pointA.position += Vector2.DOWN * gravity * 10.0 * delta * delta
			
