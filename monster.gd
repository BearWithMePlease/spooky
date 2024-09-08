extends Node2D

# Inspired by The Rain World https://youtu.be/sVntwsrjNe4

@export var legsCount: int = 16
@export var radius: float = 30.0
@export var monsterLegScene: PackedScene = null
var _legPosition: Array[Vector2] = []
var _legGroundPos: Array[Vector2] = []
var _legIsOnGround: Array[bool] = []
var _legs: Array[MonsterLeg] = []

func _ready() -> void:
	for i in legsCount:
		var leg := monsterLegScene.instantiate() as MonsterLeg
		add_child(leg)
		_legs.append(leg)
		
	var angle: float = 0.0
	_legPosition.resize(_legs.size())
	_legGroundPos.resize(_legs.size())
	_legIsOnGround.resize(_legs.size())
	for legIndex in _legs.size():
		_legPosition[legIndex] = Vector2(
			cos(angle),
			sin(angle)
		) * radius
		angle += 2.0 * PI / float(_legs.size())

func _process(delta: float) -> void:
	var input: Vector2 = Vector2.ZERO
	if(Input.is_action_pressed("Forward")):
		input.y -= 1
	if(Input.is_action_pressed("Back")):
		input.y += 1
	if(Input.is_action_pressed("Right")):
		input.x += 1
	if(Input.is_action_pressed("Left")):
		input.x -= 1
	input = input.normalized()
	const SPEED: float = 300.0
	global_position += input * SPEED * delta
	
	for legIndex in _legs.size():
		var raySource: Vector2 = global_position + _legPosition[legIndex]
		_legs[legIndex].setFixedPoint(raySource, _legGroundPos[legIndex], _legIsOnGround[legIndex])

func _physics_process(delta):
	var angleStep: float = 2.0 * PI / float(_legs.size())
	for legIndex in _legs.size():
		# Check if position of legs is valid
		# not longer then leg itself
		var needsToFindNewPos: bool = false
		var raySource: Vector2 = global_position + _legPosition[legIndex]
		var direction := _legGroundPos[legIndex] - raySource
		if (direction).length() > _legs[legIndex].getLegLength():
			needsToFindNewPos = true
		
	 	#is in right range of angle
		var targetAngle: float = angleStep * legIndex
		var targetDir = Vector2(
			cos(targetAngle),
			sin(targetAngle)
		).normalized()
		direction = direction.normalized()
		
		#if direction.dot(targetDir) < 0.3:
			#needsToFindNewPos = true
		
		if not needsToFindNewPos and _legIsOnGround[legIndex]:
			continue
			
		#var rayDir: Vector2 = Vector2(
			#cos(targetAngle + randf_range(-angleStep * 0.25, angleStep * 0.25)),
			#sin(targetAngle + randf_range(-angleStep * 0.25, angleStep * 0.25))
		#)
		var rayDir: Vector2 = Vector2(
			cos(randf_range(0, 2 * PI)),
			sin(randf_range(0, 2 * PI))
		)
		var rayTarget: Vector2 = raySource + rayDir.normalized() * _legs[legIndex].getLegLength()
		var space_state = get_world_2d().direct_space_state
		var query = PhysicsRayQueryParameters2D.create(raySource, rayTarget)
		query.collide_with_areas = true
		var result = space_state.intersect_ray(query) 
		if result:
			_legGroundPos[legIndex] = result.position
			_legIsOnGround[legIndex] = true
		else:
			_legIsOnGround[legIndex] = false
