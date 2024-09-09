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
@export var verletSimulationSpeed: float = 2.0

var _targetGlobalPoint := Vector2(0, 0)
var _oldTargetGlobalPoint := Vector2(0, 0)
var _sourceGlobalPoint := Vector2(0, 0)
var _points: Array[Point] = [] # simulated points
var _sticks: Array[Stick] = []
var _isInited: bool = false
var _isOnGround: bool = false
var _targetObject: Node2D = null
var _changeTargetTimer: float = 0.0

"""from and to must be points in GLOBAL SPACE"""
func updateLeg(from: Vector2, to: Vector2, isOnGround: bool) -> void:
	_sourceGlobalPoint = from
	if not _isInited:
		_initialize(from, to)
	const DST_NEW_POINT := 0.1
	if (_targetGlobalPoint - to).length() > DST_NEW_POINT:
		_oldTargetGlobalPoint = _points[_points.size() - 1].position
		_targetGlobalPoint = to
		_changeTargetTimer = 0.0
	_isOnGround = isOnGround
	
func targetObject(node: Node2D):
	if _targetObject == node:
		return
	_oldTargetGlobalPoint = _points[_points.size() - 1].position
	_changeTargetTimer = 0.0
	_targetObject = node
	_isOnGround = false

func getLegLength() -> float:
	return lineLength
	
"""returns array of unlocked points in LOCAL SPACE"""
func getAllUnlockedPoints() -> Array[Vector2]:
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
			if _targetObject != null:
				_points[i].position = lerp(_oldTargetGlobalPoint, _targetObject.global_position, _ease_in_out_back(_changeTargetTimer / changeTime))
			else:
				_points[i].position = lerp(_oldTargetGlobalPoint, _targetGlobalPoint, _ease_in_out_back(_changeTargetTimer / changeTime))
	# Simulate rope behaviour
	_simulate(delta * verletSimulationSpeed)
	
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

# https://forum.godotengine.org/t/how-to-get-all-children-from-a-node/18587/3
func get_all_children(in_node,arr:=[]):
	arr.push_back(in_node)
	for child in in_node.get_children():
		arr = get_all_children(child,arr)
	return arr

func isPointInRect(point: Vector2, rect: Rect2) -> bool:
	return point.x > rect.position.x && point.x < rect.position.x + rect.size.x && point.y > rect.position.y && point.y < rect.position.y + rect.size.y

# Hello darkness, my old friend (part of my C++ physics engine)
func findCollisionSolution(point: Rect2, rect: Rect2) -> Dictionary:
	var minDepth: float = 1e10
	var normal: Vector2 = Vector2.ZERO

	if point.position.x < rect.position.x:
		var depth = point.position.x + point.size.x - rect.position.x
		if(depth < minDepth):
			minDepth = depth
			normal = Vector2(-1, 0)

	if point.position.x + point.size.x > rect.position.x + rect.size.x:
		var depth = rect.position.x + rect.size.x - point.position.x
		if(depth < minDepth):
			minDepth = depth
			normal = Vector2(1, 0)

	if point.position.y < rect.position.y:
		var depth = point.position.y + point.size.y - rect.position.y
		if depth < minDepth:
			minDepth = depth
			normal = Vector2(0, 1)

	if point.position.y + point.size.y > rect.position.y + rect.size.y: 
		var depth = rect.position.y + rect.size.y - point.position.y
		if depth < minDepth:
			minDepth = depth
			normal = Vector2(0, -1)
	 
	return {
		"depth": minDepth,
		"normal": normal
	}

var allRects: Array[Rect2] = []

# Verlet Intergation https://youtu.be/PGk0rnyTa1U
func _simulate(delta: float) -> void:
	if len(allRects) == 0:
		for child in get_all_children(get_tree().root):
			if child is CollisionShape2D:
				var rect := (child as CollisionShape2D).shape.get_rect()
				if rect != null:
					allRects.append(Rect2(child.global_position - rect.size * child.global_scale * 0.5, rect.size * child.global_scale))
		
	for p in _points:
		if not p.locked:
			var positionBeforeUpdate := Vector2(p.position.x, p.position.y)
			p.position += (p.position - p.prevPosition) * verletSmoothness
			p.position += Vector2.DOWN * gravity * delta * delta
			for rect in allRects:
				if isPointInRect(p.position, rect):
					var solution := findCollisionSolution(Rect2(p.position, Vector2(15, 15)), rect)
					if(solution["depth"] <= 1e9):
						p.position += solution["normal"] * abs(solution["depth"] * 2.0)
			p.prevPosition = positionBeforeUpdate
	
	# this loop is really performance heavy, and not because of sqrt in normalize.
	# but because python sucks with loops
	var stickCentre: Vector2 = Vector2.ZERO
	var stickChange: Vector2 = Vector2.ZERO
	for i in numIterations:
		for stick in _sticks:
			stickCentre = (stick.pointA.position + stick.pointB.position)
			stickChange = (stick.pointA.position - stick.pointB.position).normalized() * stick.length
			stick.pointA.position = (stickCentre + stickChange) * 0.5
			stick.pointB.position = (stickCentre - stickChange) * 0.5
