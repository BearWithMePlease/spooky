extends CharacterBody2D
class_name Player

@export var MAX_SPEED := 300
@export var ACCELERATION := 1500
@export var FRICITON := 1200
@export var JUMP_VELOCITY := -400.0
@export var GRAVITY := 98.0
@export var GUN: Gun = null
@onready var axis = Vector2.ZERO
var accel
var speedcap
@onready var anims = $body3
@onready var animation_tree : AnimationTree = $AnimationTree2
@onready var world = $".."
var direction := 0
var attemptInventory = false
var inInventory = false

func update_animation_tree_param():
	
	if velocity == Vector2.ZERO: # standing still
		animation_tree["parameters/conditions/isNotSprint"] = true
		animation_tree["parameters/conditions/isNotWalk"] = true
		animation_tree["parameters/conditions/isNotWalkB"] = true
		
		animation_tree["parameters/conditions/isSprint"] = false
		animation_tree["parameters/conditions/isWalk"] = false
		animation_tree["parameters/conditions/isWalkB"] = false
	
	elif (direction == -1 && $body3.flip_h) || (direction == 1 && !$body3.flip_h): # movement towards mouse (forward and sprint)
		animation_tree["parameters/conditions/isNotSprint"] = true
		animation_tree["parameters/conditions/isNotWalk"] = false # walking state
		animation_tree["parameters/conditions/isNotWalkB"] = true
		
		animation_tree["parameters/conditions/isSprint"] = false
		animation_tree["parameters/conditions/isWalk"] = true # walking state
		animation_tree["parameters/conditions/isWalkB"] = false
		
		if accel == ACCELERATION*2:
			# other states do not get edited since we do not return to facing state
			animation_tree["parameters/conditions/isNotSprint"] = false # sprinting state		
			animation_tree["parameters/conditions/isSprint"] = true # sprinting state
	
		
		
	elif (direction == -1 && !$body3.flip_h) || (direction == 1 && $body3.flip_h):
		animation_tree["parameters/conditions/isNotSprint"] = true
		animation_tree["parameters/conditions/isNotWalk"] = true 
		animation_tree["parameters/conditions/isNotWalkB"] = false # back walking state
		
		animation_tree["parameters/conditions/isSprint"] = false
		animation_tree["parameters/conditions/isWalk"] = false 
		animation_tree["parameters/conditions/isWalkB"] = true # back walking state
		
#var gunEmpty = preload("res://scenes/gun.tscn")
#var gun = gunEmpty.instantiate()

# Makes player ignore input for some time
var _deafenTimer: float = 0.0;
func deafen(time: float):
	_deafenTimer = time;

func _ready():
	position.x = 200
	position.y = 200
	
	GUN.position = Vector2(0,0)
	GUN.world = world
	GUN.spawner = $body3
	
	$body3.flip_h = true
	#self.add_child(gun)
	
	# flip_v of gun true == left, false == right
	
	animation_tree.active = true

func _process(delta):
	_deafenTimer = max(0, _deafenTimer - delta);
	update_animation_tree_param()



func _physics_process(delta: float) -> void:
	if !inInventory: # no movement in inventory
		accel = ACCELERATION
		speedcap = MAX_SPEED
		# Add the gravity.
		if not is_on_floor():
			velocity += Vector2.DOWN * GRAVITY * delta
			velocity.x = move_toward(velocity.x, 0, 20*delta)

		# Handle jump.
		if Input.is_action_just_pressed("ui_accept") and is_on_floor(): # worthless, no jump
			velocity.y = JUMP_VELOCITY

		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		
		if is_on_floor() and _deafenTimer <= 0:
			direction = 0

			if Input.is_action_pressed("Left"):
				direction -= 1
			if Input.is_action_pressed("Right"):
				direction += 1	

			if Input.is_action_pressed("sprint") && ((direction == -1 && $body3.flip_h) || (direction == 1 && !$body3.flip_h)):
				accel = ACCELERATION*2
				speedcap = MAX_SPEED*1.3
			
			if direction != 0:
				velocity.x += direction * accel * delta
				
				if velocity.x > 0:
					velocity.x = min(velocity.x, speedcap)
				if velocity.x < 0:
					velocity.x = max(velocity.x, -speedcap)

			else:
				velocity.x = move_toward(velocity.x, 0, delta*1000)
		
		move_and_slide()
