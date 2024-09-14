extends Node2D

class_name MonsterBody

# Inspired by The Rain World https://youtu.be/sVntwsrjNe4
@export var facesCount: int = 4
@export var legsCount: int = 16
@export var legRadius: float = 30.0
@export var monsterLegScene: PackedScene = null
@export var monsterFaceScene: PackedScene = null
@export var particles: CPUParticles2D = null
@export var player: Player = null
var _isPlayerSeen := false
var _legPosition: Array[Vector2] = []
var _legGroundPos: Array[Vector2] = []
var _legIsOnGround: Array[bool] = []
var _legs: Array[MonsterLeg] = []
var _faces: Array[RigidBody2D] = []
# Used in physics_process:
var _center := Vector2(0, 0)
const WALL_COLLISION_MASK = 0b01
var _moveDirection: Vector2 = Vector2.ZERO
var _grabPlayer := false;
var _health: int = 100;

func move(direction: Vector2) -> void:
	_moveDirection = direction;

func canSeePlayer() -> bool:
	return _isPlayerSeen;

func getHealth() -> int:
	return _health;
	
func setHealth(value: int) -> void:
	if _health > 0 and value <= 0:
		for leg in _legs:
			leg.detachLeg();
	_health = value;

""" returns distance of leg to player"""
func grabPlayer(state: bool) -> float:
	_grabPlayer = state;
	var pos = _legs[0].getPosOfLastPoint();
	if pos.x != 0 || pos.y != 0:
		return pos.distance_to(player.global_position);
	return -1;

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
		
func _process(_delta: float) -> void:
	if _health <= 0:
		return;
	
	# Update ground positions of legs
	for legIndex in _legs.size():
		var raySource: Vector2 = global_position + _legPosition[legIndex]
		if legIndex == 0 and _grabPlayer:
			_legs[0].updateLeg(raySource, player.global_position, true, true)
		else:
			_legs[legIndex].updateLeg(raySource, _legGroundPos[legIndex], _legIsOnGround[legIndex])		
	
	# Make particles spawn at legs
	var allPoints: Array[Vector2] = []
	for leg in _legs:
		allPoints.append_array(leg.getAllUnlockedPoints())
	particles.emission_points = allPoints

func _physics_process(delta):
	
		
	# Raycasting player
	if player != null:
		var playerTarget := player.global_position + Vector2.DOWN * 10.0
		var query = PhysicsRayQueryParameters2D.create(global_position, playerTarget)
		query.collide_with_bodies = true
		query.collision_mask = player.collision_layer | WALL_COLLISION_MASK
		var space_state = get_world_2d().direct_space_state
		var result = space_state.intersect_ray(query)
		_isPlayerSeen = result and result.collider is Player
			
	# Monster rigidbody movement
	var newCenter := Vector2.ZERO
	for faceIndex in _faces.size():
		var rigidbody := _faces[faceIndex] as RigidBody2D
		if rigidbody != null:
			if _health <= 0:
				rigidbody.gravity_scale = 0.25;
			else:
				# Lerp position of heads towards monster center
				rigidbody.global_position = lerp(rigidbody.global_position, _center, delta)
				newCenter += rigidbody.global_position
				rigidbody.linear_velocity = _moveDirection # NOTE: they mean, not to use it in _process....
	newCenter /= _faces.size()
	_center = newCenter
	get_parent().global_position = newCenter
	
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
				_legGroundPos[legIndex] = result.position + randomDirection * 7.5
				_legIsOnGround[legIndex] = true
				break
