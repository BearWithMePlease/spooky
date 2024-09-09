extends Node2D

class_name Monster

# Inspired by The Rain World https://youtu.be/sVntwsrjNe4
@export var monsterSpeed: float = 300.0
@export var facesCount: int = 4
@export var legsCount: int = 16
@export var legRadius: float = 30.0
@export var monsterLegScene: PackedScene = null
@export var monsterFaceScene: PackedScene = null
@export var particles: CPUParticles2D = null
var _legPosition: Array[Vector2] = []
var _legGroundPos: Array[Vector2] = []
var _legIsOnGround: Array[bool] = []
var _legs: Array[MonsterLeg] = []
var _faces: Array[RigidBody2D] = []

func _ready() -> void:	
	# Generate faces
	for i in facesCount:
		var face := monsterFaceScene.instantiate() as RigidBody2D
		add_child(face)
		face.position = Vector2(randf_range(-1, 1), randf_range(-1, 1))
		_faces.append(face)
	
	# Generate legs
	for i in legsCount:
		var leg := monsterLegScene.instantiate() as MonsterLeg
		add_child(leg)
		_legs.append(leg)
	
	_legPosition.resize(_legs.size())
	_legGroundPos.resize(_legs.size())
	_legIsOnGround.resize(_legs.size())
	# make initial legs positions in circle (makes kinda no sence anymore)
	var angle: float = 0.0
	for legIndex in _legs.size():
		_legPosition[legIndex] = Vector2(
			cos(angle),
			sin(angle)
		) * legRadius
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
	global_position += input * monsterSpeed * delta

	var center := Vector2(0, 0)
	for faceIndex in _faces.size():
		var rigidbody := _faces[faceIndex] as RigidBody2D
		if rigidbody != null:
			# Lerp position of heads towards monster center
			rigidbody.global_position = lerp(rigidbody.global_position, global_position, delta)
			center += rigidbody.global_position
	center /= _faces.size()
	# Lerp monster center to center of heads
	global_position = lerp(global_position, center, 10.0 * delta)
	
	# Update ground positions of legs
	for legIndex in _legs.size():
		var raySource: Vector2 = global_position + _legPosition[legIndex]
		_legs[legIndex].updateLeg(raySource, _legGroundPos[legIndex], _legIsOnGround[legIndex])
	
	# Make particles spawn at legs
	var allPoints: Array[Vector2] = []
	for leg in _legs:
		allPoints.append_array(leg.getAllUnlockedPoints())
	particles.emission_points = allPoints

func _physics_process(delta):
	for legIndex in _legs.size():
		# Check if position of legs is valid
		# not longer then leg itself
		var needsToFindNewPos: bool = false
		var raySource: Vector2 = global_position + _legPosition[legIndex]
		var direction := _legGroundPos[legIndex] - raySource
		if (direction).length() > _legs[legIndex].getLegLength():
			needsToFindNewPos = true
		
		if not needsToFindNewPos and _legIsOnGround[legIndex]:
			continue
		
		# Try to find ground randomly 10 times with raycast
		for i in 10:
			var randomDirection: Vector2 = Vector2(
				cos(randf_range(0, 2 * PI)),
				sin(randf_range(0, 2 * PI))
			).normalized()
			var rayTarget: Vector2 = raySource + randomDirection * _legs[legIndex].getLegLength()
			var query = PhysicsRayQueryParameters2D.create(raySource, rayTarget)
			query.collide_with_bodies = true
			query.collision_mask = 0b10
			var space_state = get_world_2d().direct_space_state
			var result = space_state.intersect_ray(query)
			# If found, store it
			if result:
				_legGroundPos[legIndex] = result.position
				_legIsOnGround[legIndex] = true
				break
			else:
				_legIsOnGround[legIndex] = false
