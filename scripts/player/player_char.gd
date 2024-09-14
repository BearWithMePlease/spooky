extends CharacterBody2D
class_name Player

@export var MAX_SPEED = 300
@export var ACCELERATION = 1500
@export var FRICITON = 1200
#@export var GUN: Gun = null
@onready var axis = Vector2.ZERO

const JUMP_VELOCITY = -200.0

var accel
var speedcap
@onready var anims = $body3
@onready var animation_tree : AnimationTree = $AnimationTree2
@onready var world = $".."
var direction := 0
var attemptInventory = false
var inInventory = false
var gunsAreGo = false

var isClimbing = false

func climb():
	
	# detect zone
	animation_tree["parameters/conditions/isClimbA"] = true
	animation_tree["parameters/conditions/isNotClimbA"] = false
	
	animation_tree["parameters/conditions/isGun"] = false
	animation_tree["parameters/conditions/isNotGun"] = true
	animation_tree["parameters/conditions/isNotSprintA"] = true
	animation_tree["parameters/conditions/isNotWalkA"] = true
	animation_tree["parameters/conditions/isNotWalkBA"] = true
	
	animation_tree["parameters/conditions/isSprintA"] = false
	animation_tree["parameters/conditions/isWalkA"] = false
	animation_tree["parameters/conditions/isWalkBA"] = false
	
	
	#move y disable gravity
	
	#next key input loop this shit might need to set a climb down animation
	
	
	pass


var weaponswitchCooldown = false
@export var weaponswitchCooltime = 1 # in seconds






func checkGun():
	if Input.is_action_just_pressed("equip gun") && !weaponswitchCooldown && !gun.isReloading && !gunsAreGo: # worthless, no jump
		gunsAreGo = true
		gun.visible = gunsAreGo
		weaponswitchCooldown = true
		await get_tree().create_timer(weaponswitchCooltime).timeout
		weaponswitchCooldown = false

	if Input.is_action_just_pressed("equip hands") && !weaponswitchCooldown && !gun.isReloading && gunsAreGo:
		gunsAreGo = false
		gun.visible = gunsAreGo
		weaponswitchCooldown = true
		await get_tree().create_timer(weaponswitchCooltime).timeout
		weaponswitchCooldown = false

func update_animation_tree_param():
	
	if gunsAreGo:
		animation_tree["parameters/conditions/isGun"] = true
		animation_tree["parameters/conditions/isNotGun"] = false
		animation_tree["parameters/conditions/isNotSprintA"] = true
		animation_tree["parameters/conditions/isNotWalkA"] = true
		animation_tree["parameters/conditions/isNotWalkBA"] = true
		
		animation_tree["parameters/conditions/isSprintA"] = false
		animation_tree["parameters/conditions/isWalkA"] = false
		animation_tree["parameters/conditions/isWalkBA"] = false

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
		
	else:
		
		animation_tree["parameters/conditions/isGun"] = false
		animation_tree["parameters/conditions/isNotGun"] = true
		animation_tree["parameters/conditions/isNotSprint"] = true
		animation_tree["parameters/conditions/isNotWalk"] = true
		animation_tree["parameters/conditions/isNotWalkB"] = true
		
		animation_tree["parameters/conditions/isSprint"] = false
		animation_tree["parameters/conditions/isWalk"] = false
		animation_tree["parameters/conditions/isWalkB"] = false
		
		if velocity == Vector2.ZERO: # standing still
			animation_tree["parameters/conditions/isNotSprintA"] = true
			animation_tree["parameters/conditions/isNotWalkA"] = true
			animation_tree["parameters/conditions/isNotWalkBA"] = true
			
			animation_tree["parameters/conditions/isSprintA"] = false
			animation_tree["parameters/conditions/isWalkA"] = false
			animation_tree["parameters/conditions/isWalkBA"] = false
		
		elif (direction == -1 && $body3.flip_h) || (direction == 1 && !$body3.flip_h): # movement towards mouse (forward and sprint)
			animation_tree["parameters/conditions/isNotSprintA"] = true
			animation_tree["parameters/conditions/isNotWalkA"] = false # walking state
			animation_tree["parameters/conditions/isNotWalkBA"] = true
			
			animation_tree["parameters/conditions/isSprintA"] = false
			animation_tree["parameters/conditions/isWalkA"] = true # walking state
			animation_tree["parameters/conditions/isWalkBA"] = false
			
			if accel == ACCELERATION*2:
				# other states do not get edited since we do not return to facing state
				animation_tree["parameters/conditions/isNotSprintA"] = false # sprinting state		
				animation_tree["parameters/conditions/isSprintA"] = true # sprinting state
		
			
			
		elif (direction == -1 && !$body3.flip_h) || (direction == 1 && $body3.flip_h):
			animation_tree["parameters/conditions/isNotSprintA"] = true
			animation_tree["parameters/conditions/isNotWalkA"] = true 
			animation_tree["parameters/conditions/isNotWalkBA"] = false # back walking state
			
			animation_tree["parameters/conditions/isSprintA"] = false
			animation_tree["parameters/conditions/isWalkA"] = false 
			animation_tree["parameters/conditions/isWalkBA"] = true # back walking state
			
			
			
			
		#if accel == ACCELERATION*2:
				#animation_tree["parameters/conditions/isSprint"] = true # start sprint
				#animation_tree["parameters/conditions/stopSprint"] = false # stay sprinting
				##state switcehs to frontstep
			#else:
				#animation_tree["parameters/conditions/isSprint"] = false # stop sprint
				#animation_tree["parameters/conditions/stopSprint"] = true # allows state switch to frontstep
		
	#v2
	
	
	#states
	#if !inInventory:
		#
		#if velocity == Vector2.ZERO: # standing still
			#animation_tree["parameters/conditions/isIdleB"] = true # no movement => allows return to idle state
			#animation_tree["parameters/conditions/isIdleF"] = true # no movement => allows return to idle state
#
			#animation_tree["parameters/conditions/isFrontstep"] = false # blocks return to stepping
			#animation_tree["parameters/conditions/isBackstep"] = false # blocks return to frontstep
			#
			#animation_tree["parameters/conditions/isSprint"] = false # blocks return to sprinting
			#animation_tree["parameters/conditions/stopSprint"] = true # allows state switch to frontstep
			#
			#if attemptInventory == true:
				#animation_tree["parameters/conditions/enterInventory"] = true # allows state switch to frontstep
				#animation_tree["parameters/conditions/quitInventory"] = false
				#inInventory = true
				#gun.hide()
			#else:
				#animation_tree["parameters/conditions/enterInventory"] = false # allows state switch to frontstep
				#animation_tree["parameters/conditions/quitInventory"] = true
				#gun.show()
#
			#
		#elif (direction == -1 && $body2.flip_h) || (direction == 1 && !$body2.flip_h): # movement towards mouse (forward and sprint)
			#
			#animation_tree["parameters/conditions/isIdleB"] = true # backstep => to frontstep
#
			#animation_tree["parameters/conditions/isIdleF"] = false # forbids entry in idle state if in forward
#
			#animation_tree["parameters/conditions/isFrontstep"] = true # forward movement  
#
			## state switches to frontstep
			#animation_tree["parameters/conditions/isBackstep"] = false # blocks backstep
			#
			#if accel == ACCELERATION*2:
				#animation_tree["parameters/conditions/isSprint"] = true # start sprint
				#animation_tree["parameters/conditions/stopSprint"] = false # stay sprinting
				##state switcehs to frontstep
			#else:
				#animation_tree["parameters/conditions/isSprint"] = false # stop sprint
				#animation_tree["parameters/conditions/stopSprint"] = true # allows state switch to frontstep
		#elif (direction == -1 && !$body2.flip_h) || (direction == 1 && $body2.flip_h):
			#animation_tree["parameters/conditions/isSprint"] = false # stop sprint
			#animation_tree["parameters/conditions/stopSprint"] = true # allows state switch to frontstep
			#
			#animation_tree["parameters/conditions/isFrontstep"] = false # blocks return to forward motion
			#animation_tree["parameters/conditions/isIdleF"] = true # front to idle 
#
			#animation_tree["parameters/conditions/isBackstep"] = true # blocks return to frontstep
			#animation_tree["parameters/conditions/isIdleB"] = false # remains in backstep



	
	
	#v1
	#if velocity == Vector2.ZERO: # standing still
		#animation_tree["parameters/conditions/isIdle"] = true
		#animation_tree["parameters/conditions/isFrontstep"] = false
		#animation_tree["parameters/conditions/isSprint"] = false
		#animation_tree["parameters/conditions/stopSprint"] = true
		#animation_tree["parameters/conditions/isBackstep"] = false
#
#
	#elif (direction == -1 && $body2.flip_h) || (direction == 1 && !$body2.flip_h): # movement in direction of gun
		#animation_tree["parameters/conditions/isIdle"] = false
		#
		#if animation_tree["parameters/conditions/isFrontstep"] && accel == ACCELERATION*2:
			#animation_tree["parameters/conditions/isSprint"] = true
			#animation_tree["parameters/conditions/stopSprint"] = false
#
		#else:
			#animation_tree["parameters/conditions/isSprint"] = false
			#animation_tree["parameters/conditions/stopSprint"] = true
#
		#animation_tree["parameters/conditions/isFrontstep"] = true
	#else:
		#animation_tree["parameters/conditions/isFrontstep"] = false
		#animation_tree["parameters/conditions/isIdle"] = false
		#animation_tree["parameters/conditions/isBackstep"] = true



		
	#elif accel == ACCELERATION*2: # sprint
		
var gunEmpty = preload("res://scenes/gun.tscn")
var gun = gunEmpty.instantiate()

func _ready():
	position.x = 200
	position.y = 200
	
	gun.position = Vector2(0,0)
	gun.world = world
	gun.spawner = $body3
	gun.visible = gunsAreGo
	
	$body3.flip_h = true
	self.add_child(gun)
	
	# flip_v of gun true == left, false == right
	
	animation_tree.active = true

func _process(delta):
	update_animation_tree_param()
	interact()



func _physics_process(delta: float) -> void:
	if !inInventory: # no movement in inventory
		checkGun()
		
		accel = ACCELERATION
		speedcap = MAX_SPEED
		# Add the gravity.
		if not is_on_floor():
			velocity += get_gravity() * delta
			velocity.x = move_toward(velocity.x, 0, 20*delta)


		# Handle jump.
		if Input.is_action_just_pressed("ui_accept") and is_on_floor(): # worthless, no jump
			velocity.y = JUMP_VELOCITY

		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		
		if is_on_floor():
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




var isInWeapons = false
func _on_area_2d_area_entered(area: Area2D) -> void:
	print(area)
	if area.name == "Weapons":
		isInWeapons = true
		$Label.show()
	else:
		isInWeapons = false
		$Label.hide()


	print(isInWeapons)
	
func _on_area_2d_area_exited(area: Area2D) -> void:
	if area.name == "Weapons":
		isInWeapons = false
		$Label.hide()
	
	
	
	
	
func interact():
	if isInWeapons && Input.is_action_just_pressed("interact"):
		gun.ammunition_pool_total = 200
	
		
