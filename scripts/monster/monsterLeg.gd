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
	
class CollisionResult:
	var depth: float
	var normal: Vector2
	
@export var pointCount: int = 15
@export var lineLength: float = 100.0
@export var gravity: float = 300.0
@export var numIterations: int = 100
@export var changeTime: float = 3.0 # more => faster
@export var verletSmoothness: float = 0.75 # more => more janky
@export var verletSimulationSpeed: float = 2.0
@export var minWidth: float = 4.0
@export var maxWidth: float = 8.0

var _targetGlobalPoint := Vector2(0, 0)
var _oldTargetGlobalPoint := Vector2(0, 0)
var _sourceGlobalPoint := Vector2(0, 0)
var _points: Array[Point] = [] # simulated points
var _sticks: Array[Stick] = []
var _isInited: bool = false
var _isOnGround: bool = false
var _changeTargetTimer: float = 0.0

func _ready() -> void:
	width = randf_range(minWidth, maxWidth)

func detachLeg() -> void:
	_points[0].locked = false;

"""from and to must be points in GLOBAL SPACE"""
func updateLeg(from: Vector2, to: Vector2, isOnGround: bool, forceNewPoint: bool = false) -> void:
	_sourceGlobalPoint = from
	if not _isInited:
		_initialize(from, to)
	const DST_NEW_POINT := 0.1
	if (_targetGlobalPoint - to).length() > DST_NEW_POINT or forceNewPoint:
		_oldTargetGlobalPoint = getPosOfLastPoint()
		_targetGlobalPoint = to
		_changeTargetTimer = 1.0 if forceNewPoint else 0.0
	_isOnGround = isOnGround
	
func getPosOfLastPoint() -> Vector2:
	if(len(_points) > 0):
		return _points[len(_points) - 1].position;
	return Vector2.ZERO;

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

# I don't know why but _physics_process is faster if it's able to keep up with fix update
# Might create problems on weak CPU or Web-build. Then replace with _process
func _physics_process(delta: float) -> void:
	if not _isInited:
		return
	
	# Update first point
	if _points[0].locked:
		_points[0].position = _sourceGlobalPoint
	
	_points[pointCount - 1].locked = _isOnGround
	if _points[pointCount - 1].locked:
		# Transition between old position and new using easing function
		_changeTargetTimer = min(changeTime, _changeTargetTimer + delta)
		_points[pointCount - 1].position = lerp(_oldTargetGlobalPoint, _targetGlobalPoint, _ease_in_out_back(_changeTargetTimer / changeTime))
	
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

# Verlet Intergation https://youtu.be/PGk0rnyTa1U
func _simulate(delta: float) -> void:
	for p in _points:
		if not p.locked:
			var positionBeforeUpdate := Vector2(p.position.x, p.position.y)
			p.position += (p.position - p.prevPosition) * verletSmoothness
			p.position += Vector2.DOWN * gravity * delta * delta
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
