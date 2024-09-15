extends CharacterBody2D
class_name Player

@export var MAX_SPEED := 300
@export var ACCELERATION := 1500
@export var FRICITON := 1200
@export var JUMP_VELOCITY := -100.0
@export var GRAVITY := 98.0
@export var GUN: Gun = null;
@onready var axis = Vector2.ZERO
@export var HP = 100
@export var falldmg_multiplier = 10

@onready var audio_control :=  $"../Audio_Control"

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
var climbInputU = false
var climbInputD = false

func climb(delta):
	
	if climbInputU:
		velocity.y = -30000*delta
		move_and_slide()
		
	if Input.is_action_pressed("Forward") && !climbInputU && !climbInputD:
		velocity = Vector2(0,0)
		climbInputU = true
		$AnimationPlayer2.play("a_climbing_2")
		await get_tree().create_timer(0.45).timeout
		$AnimationPlayer2.stop()
		climbInputU = false

		
	

	if climbInputD:
		velocity.y = 35000*delta
		move_and_slide()
		
	if Input.is_action_pressed("Back") && !climbInputU && !climbInputD && !is_on_floor():
		velocity = Vector2(0,0)
		climbInputD = true
		$AnimationPlayer2.play_backwards("a_climbing_2")	
		await get_tree().create_timer(0.45).timeout 	
		$AnimationPlayer2.stop()
		climbInputD = false

		
	

	
	#move y disable gravity
	
	#next key input loop this shit might need to set a climb down animation
	
	
	pass


var weaponswitchCooldown = false
@export var weaponswitchCooltime = 1 # in seconds


func checkClimbInput():
	if ladder_array.size() > 0 && !isClimbing && (Input.is_action_pressed("Forward") || Input.is_action_pressed("Back")):
		
		
		global_position.x = ladder_array[0].global_position.x+32
		isClimbing = true
		GUN.isClimbing = isClimbing
		$body3.flip_h = false

		gunsAreGo = false
		GUN.visible = gunsAreGo
		$AnimationTree2.active = false
		
		$AnimationPlayer2.play("a_climbing_2")
		$AnimationPlayer2.stop()
	
	if isClimbing && !(Input.is_action_pressed("Forward") || Input.is_action_pressed("Back")) && (Input.is_action_just_pressed("Left") || Input.is_action_just_pressed("Right") || Input.is_action_just_pressed("ui_accept")):
		isClimbing = false
		GUN.isClimbing = isClimbing
		$AnimationTree2.active = true
		if Input.is_action_just_pressed("Left"):
			velocity = Vector2(-100, -100)
		if Input.is_action_just_pressed("Right"):
			velocity = Vector2(100, -100)




func checkGun():
	if Input.is_action_just_pressed("equip gun") && !weaponswitchCooldown && !GUN.isReloading && !gunsAreGo && !isClimbing: # worthless, no jump
		gunsAreGo = true
		GUN.visible = gunsAreGo
		weaponswitchCooldown = true
		await get_tree().create_timer(weaponswitchCooltime).timeout
		weaponswitchCooldown = false

	if Input.is_action_just_pressed("equip hands") && !weaponswitchCooldown && !GUN.isReloading && gunsAreGo && !isClimbing:
		gunsAreGo = false
		GUN.visible = gunsAreGo
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
			audio_control.play_footsteps(false, 0.1)
			animation_tree["parameters/conditions/isNotSprint"] = true
			animation_tree["parameters/conditions/isNotWalk"] = true
			animation_tree["parameters/conditions/isNotWalkB"] = true
			
			animation_tree["parameters/conditions/isSprint"] = false
			animation_tree["parameters/conditions/isWalk"] = false
			animation_tree["parameters/conditions/isWalkB"] = false
		
		elif (direction == -1 && $body3.flip_h) || (direction == 1 && !$body3.flip_h): # movement towards mouse (forward and sprint)
			audio_control.play_footsteps(true, 0.1)
			animation_tree["parameters/conditions/isNotSprint"] = true
			animation_tree["parameters/conditions/isNotWalk"] = false # walking state
			animation_tree["parameters/conditions/isNotWalkB"] = true
			
			animation_tree["parameters/conditions/isSprint"] = false
			animation_tree["parameters/conditions/isWalk"] = true # walking state
			animation_tree["parameters/conditions/isWalkB"] = false
			
			if accel == ACCELERATION*2:
				audio_control.play_footsteps(true, 0.0)
				# other states do not get edited since we do not return to facing state
				animation_tree["parameters/conditions/isNotSprint"] = false # sprinting state		
				animation_tree["parameters/conditions/isSprint"] = true # sprinting state
		
			
			
		elif (direction == -1 && !$body3.flip_h) || (direction == 1 && $body3.flip_h):
			audio_control.play_footsteps(true, 0.1)
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
			audio_control.play_footsteps(false, 0.1)
			animation_tree["parameters/conditions/isNotSprintA"] = true
			animation_tree["parameters/conditions/isNotWalkA"] = true
			animation_tree["parameters/conditions/isNotWalkBA"] = true
			
			animation_tree["parameters/conditions/isSprintA"] = false
			animation_tree["parameters/conditions/isWalkA"] = false
			animation_tree["parameters/conditions/isWalkBA"] = false
		
		elif (direction == -1 && $body3.flip_h) || (direction == 1 && !$body3.flip_h): # movement towards mouse (forward and sprint)
			audio_control.play_footsteps(true, 0.1)
			animation_tree["parameters/conditions/isNotSprintA"] = true
			animation_tree["parameters/conditions/isNotWalkA"] = false # walking state
			animation_tree["parameters/conditions/isNotWalkBA"] = true
			
			animation_tree["parameters/conditions/isSprintA"] = false
			animation_tree["parameters/conditions/isWalkA"] = true # walking state
			animation_tree["parameters/conditions/isWalkBA"] = false
			
			if accel == ACCELERATION*2:
				audio_control.play_footsteps(true, 0.0)
				# other states do not get edited since we do not return to facing state
				animation_tree["parameters/conditions/isNotSprintA"] = false # sprinting state		
				animation_tree["parameters/conditions/isSprintA"] = true # sprinting state
		
			
			
		elif (direction == -1 && !$body3.flip_h) || (direction == 1 && $body3.flip_h):
			audio_control.play_footsteps(true, 0.1)
			animation_tree["parameters/conditions/isNotSprintA"] = true
			animation_tree["parameters/conditions/isNotWalkA"] = true 
			animation_tree["parameters/conditions/isNotWalkBA"] = false # back walking state
			
			animation_tree["parameters/conditions/isSprintA"] = false
			animation_tree["parameters/conditions/isWalkA"] = false 
			animation_tree["parameters/conditions/isWalkBA"] = true # back walking state
			
	
# Makes player ignore input for some time
var _deafenTimer: float = 0.0;
func deafen(time: float):
	isClimbing = false
	GUN.isClimbing = isClimbing
	$AnimationTree2.active = true
	airtime += 1
	_deafenTimer = time;




# var gunEmpty = preload("res://scenes/GUN.tscn")
# var gun = gunEmpty.instantiate()
var maxHP


func _ready():
	randomize()
	maxHP = HP
	position.x = 200
	position.y = 200
	
	GUN.world = world
	GUN.spawner = $body3
	GUN.visible = gunsAreGo
	
	$body3.flip_h = true
	
	# flip_v of gun true == left, false == right
	
	animation_tree.active = true

	self.add_child(GUN)

func _process(delta):
	_deafenTimer = max(0, _deafenTimer - delta);
	
	if _deafenTimer <= 0:
		checkClimbInput()
		if !isClimbing:
			update_animation_tree_param()
		else:
			climb(delta)
		interact()

@onready var camera = $Camera

var airtime = 0
@export var airtimeforDMG = 0.4
func _physics_process(delta: float) -> void:
	if !inInventory && !isClimbing: # no movement in inventory
		checkGun()
		
		accel = ACCELERATION
		speedcap = MAX_SPEED
		# Add the gravity.
		if not is_on_floor():
			velocity += Vector2.DOWN * GRAVITY * delta
			velocity.x = move_toward(velocity.x, 0, 20*delta)
			
			if velocity.y > 0:
				airtime += delta

		else:
			if airtime > airtimeforDMG:
				HP -= ceil(airtime*falldmg_multiplier)
				
				var pain = randi_range(0,3)
				if pain == 0:
					$body3/AudioStreamPlayer.play()
				if pain == 1:
					$body3/AudioStreamPlayer2.play()
				if pain == 2:
					$body3/AudioStreamPlayer3.play()
				if pain == 3:
					$body3/AudioStreamPlayer4.play()
				camera.apply_shake()
				print(HP)
			airtime = 0

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




var isInWeapons = false
var isInHospital = false
var isInWater = false

var isInGenerator = false
var isInGeneratorVent = false

var isInCom = false

var isInBed = false


var ladder_array = []

func _on_area_2d_area_entered(area: Area2D) -> void:
	#print(area)
	if area.name == "Weapons":
		isInWeapons = true
		$Label.show()
	else:
		isInWeapons = false
	
	
	if area.name == "Healing":
		isInHospital = true
		$Label.show()
	else:
		isInHospital = false

	
	if area.name == "Water":
		isInWater = true
		$Label.show()
	else:
		isInWater = false
	
	
	if area.name == "Vent":
		isInGeneratorVent = true
		$Label.show()
	else:
		isInGeneratorVent = false

	
	if area.name == "Generator":
		isInGenerator = true
		$Label.show()
	else:
		isInGenerator = false
	
	
	if area.name == "Communication":
		isInCom = true
		$Label.show()
	else:
		isInCom = false
	
	
	if area.name == "Bed":
		isInBed = true
		$Label.show()
	else:
		isInBed = false
	
	
	if area.name == "Ladder":
		ladder_array.append(area)
	else:
		isClimbing = false
		GUN.isClimbing = isClimbing
		GUN.visible = gunsAreGo



	
func _on_area_2d_area_exited(area: Area2D) -> void:
	if area.name == "Weapons":
		isInWeapons = false
		$Label.hide()
	
	if area.name == "Healing":
		isInHospital = false
		$Label.hide()
	
	if area.name == "Water":
		isInWater = false
		$Label.hide()
	
	
	
	if area.name == "Vent":
		isInGeneratorVent = false
		$Label.hide()
		
	if area.name == "Generator":
		isInGenerator = false
		$Label.hide()
		
	
	if area.name == "Communication":
		isInCom = false
		$Label.hide()
		
	
	if area.name == "Bed":
		isInBed = false
		$Label.hide()
	
	
	if area.name == "Ladder":
		ladder_array.pop_front()
		if ladder_array.size() == 0:
			isClimbing = false
			GUN.isClimbing = isClimbing
			$AnimationTree2.active = true
	
	
	
func interact():
	if isInWeapons && Input.is_action_just_pressed("interact"):
		GUN.ammunition_pool_total = 200
	
	if isInHospital && Input.is_action_just_pressed("interact"):
		if HP < maxHP:
			self.HP = maxHP
	
	if isInWater && Input.is_action_just_pressed("interact"):
		print("water gtfo")
	
	
	if isInGeneratorVent && Input.is_action_just_pressed("interact"):
		print("Vent gtfo")
		
	if isInGenerator && Input.is_action_just_pressed("interact"):
		print("Generator gtfo")
	
	if isInCom && Input.is_action_just_pressed("interact"):
		print("Communication gtfo")
	
	if isInBed && Input.is_action_just_pressed("interact"):
		print("Bed gtfo")
