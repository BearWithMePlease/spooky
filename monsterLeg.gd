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
@export var changeTargetSmoothness: float = 5.0 # more => faster
@export var verletSmoothness: float = 0.75 # more => more janky
var _targetGlobalPoint := Vector2(0, 0)
var _sourceGlobalPoint := Vector2(0, 0)
var _points: Array[Point] = [] # simulated points
var _sticks: Array[Stick] = []
var _isInited: bool = false
var _hasTarget: bool = false

"""from and to must be points in GLOBAL SPACE"""
func setFixedPoint(from: Vector2, to: Vector2, lockLast: bool) -> void:
	_sourceGlobalPoint = from
	_targetGlobalPoint = to
	if not _isInited:
		init(from, to)
		_isInited = true
	_hasTarget = lockLast
	
func getLastPointPos() -> Vector2:
	return _points[_points.size() - 1].position

func getLegLength() -> float:
	return lineLength

func _lerp(A: Vector2, B: Vector2, procent: float) -> Vector2:
	return A + (B - A) * procent

func init(from: Vector2, to: Vector2) -> void:
	_points.resize(pointCount)
	_sticks.resize(pointCount - 1)
	
	# WHY THE HELL I CAN'T JUST points.resize(pointCount)
	var newArr: Array[Vector2] = []
	newArr.resize(pointCount)
	newArr.fill(Vector2(0,0))
	self.points = newArr
	
	for i in _points.size():
		_points[i] = Point.new()
		var pos := _lerp(from, to, float(i) / float(pointCount))
		_points[i].position = pos
		_points[i].prevPosition = pos
		_points[i].locked = false
		
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
		
	_points[0].position = _sourceGlobalPoint
	var dst := (_targetGlobalPoint - _sourceGlobalPoint).length()
	var notNeededSegments: int = max(0, dst / (lineLength / _points.size()))
	for i in range(1, pointCount):
		_points[i].locked = _hasTarget and (i >= pointCount - notNeededSegments - 1)
		if _points[i].locked:
			_points[i].position = _lerp(_points[i].position, _targetGlobalPoint, changeTargetSmoothness * delta)
	
	_simulate(delta * 2.0)
	for pointIndex in _points.size():
		self.points[pointIndex] = to_local(_points[pointIndex].position)

# Verlet Intergation https://youtu.be/PGk0rnyTa1U
func _simulate(delta: float):
	#var allArea2D: Array[Rect2] = []
	#for child in get_tree().root.get_children(true):
		#if child is Area2D:
			#var shape = child.get_child(0) as CollisionShape2D
			#var rectShape = shape.shape as RectangleShape2D
			#var rect = rectShape.get_rect() as Rect2
			#allArea2D.append(rect)
	
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

func _physics_process(delta):
	for stick in _sticks:
		var raySource = stick.pointA.position
		var rayTarget = stick.pointB.position
		var rayDirection = (raySource - rayTarget).normalized()
		var space_state = get_world_2d().direct_space_state
		var query = PhysicsRayQueryParameters2D.create(raySource, rayTarget)
		query.collide_with_areas = true
		var result = space_state.intersect_ray(query) 
		if result:
			stick.pointB.position = result.position + rayDirection * 2.0
			stick.pointA.locked = true
			stick.pointA.position = result.position + rayDirection * 2.0
			stick.pointB.locked = true
		elif not stick.pointA.locked:
			stick.pointA.position += Vector2.DOWN * gravity * 10.0 * delta * delta
			
