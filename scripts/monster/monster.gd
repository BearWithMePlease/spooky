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
@export var player: Node2D = null
@export var navigationAgent: NavigationAgent2D = null
var _legPosition: Array[Vector2] = []
var _legGroundPos: Array[Vector2] = []
var _legIsOnGround: Array[bool] = []
var _legs: Array[MonsterLeg] = []
var _faces: Array[RigidBody2D] = []
var _isPlayerVisible: bool = false
# Used in physics_process:
var _center := Vector2(0, 0)
var _input: Vector2 = Vector2(0, 0)
const WALL_COLLISION_MASK = 0b01
var _isNavigationMapBaked := false

func _ready() -> void:
	_center = global_position
	# Generate faces
	for i in facesCount:
		var face := monsterFaceScene.instantiate() as RigidBody2D
		add_child(face)
		# little random so that they push each other out
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
	
	# make initial legs positions in circle
	var angle: float = 0.0
	for legIndex in _legs.size():
		_legPosition[legIndex] = Vector2(
			cos(angle),
			sin(angle)
		) * legRadius
		angle += 2.0 * PI / float(_legs.size())
		
func _process(delta: float) -> void:
	_input = Vector2.ZERO
	if(Input.is_action_pressed("Forward")):
		_input.y -= 1
	if(Input.is_action_pressed("Back")):
		_input.y += 1
	if(Input.is_action_pressed("Right")):
		_input.x += 1
	if(Input.is_action_pressed("Left")):
		_input.x -= 1
	_input = _input.normalized()

	# Update ground positions of legs
	for legIndex in _legs.size():
		var raySource: Vector2 = global_position + _legPosition[legIndex]
		_legs[legIndex].updateLeg(raySource, _legGroundPos[legIndex], _legIsOnGround[legIndex])
	
	# Make particles spawn at legs
	var allPoints: Array[Vector2] = []
	for leg in _legs:
		allPoints.append_array(leg.getAllUnlockedPoints())
	particles.emission_points = allPoints
	
	if _isNavigationMapBaked:
		navigationAgent.target_position = get_global_mouse_position()

func _physics_process(delta):
	if _isNavigationMapBaked:
		var aiInput: Vector2 = (navigationAgent.get_next_path_position() - global_position).normalized()
	
		# Monster rigidbody movement
		var newCenter := Vector2.ZERO
		for faceIndex in _faces.size():
			var rigidbody := _faces[faceIndex] as RigidBody2D
			if rigidbody != null:
				# Lerp position of heads towards monster center
				rigidbody.global_position = lerp(rigidbody.global_position, _center, delta)
				newCenter += rigidbody.global_position
				rigidbody.linear_velocity = aiInput * monsterSpeed
		newCenter /= _faces.size()
		_center = newCenter
		global_position = _center
	
	# Raycasting player
	if player != null:
		var playerTarget := self.global_position + (player.global_position - global_position).normalized() * 1000.0
		var query = PhysicsRayQueryParameters2D.create(global_position, playerTarget)
		query.collide_with_bodies = true
		query.collision_mask = player.collision_layer
		var space_state = get_world_2d().direct_space_state
		var result = space_state.intersect_ray(query)
		if result and result.collider is Player:
			pass # See player
	
	
	for legIndex in _legs.size():
		# Check if position of legs is valid
		# not longer then leg itself
		var needsToFindNewPos: bool = false
		var raySource: Vector2 = global_position + _legPosition[legIndex]
		var direction: Vector2 = _legGroundPos[legIndex] - raySource
		if (direction).length() > _legs[legIndex].getLegLength():
			needsToFindNewPos = true
		
		if not needsToFindNewPos and _legIsOnGround[legIndex]:
			continue
		
		# Try to find ground randomly few times with raycast
		_legIsOnGround[legIndex] = false
		for i in 5:
			var randomDirection: Vector2 = Vector2(
				cos(randf_range(0, 2 * PI)),
				sin(randf_range(0, 2 * PI))
			).normalized()
			var rayTarget: Vector2 = raySource + randomDirection * _legs[legIndex].getLegLength()
			var query = PhysicsRayQueryParameters2D.create(raySource, rayTarget)
			query.collide_with_bodies = true
			query.collide_with_areas = false
			query.collision_mask = WALL_COLLISION_MASK
			var space_state = get_world_2d().direct_space_state
			var result = space_state.intersect_ray(query)
			# If found, store it
			if result:
				_legGroundPos[legIndex] = result.position
				_legIsOnGround[legIndex] = true
				break

func _on_modules_bake_finished() -> void:
	_isNavigationMapBaked = true
