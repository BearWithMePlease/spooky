extends CharacterBody2D
class_name Player

@export var MAX_SPEED := 300
@export var ACCELERATION := 1500
@export var FRICITON := 1200
@export var JUMP_VELOCITY := -100.0
@export var GRAVITY := 98.0
@export var GUN: Gun = null;
@onready var axis = Vector2.ZERO
@onready var aura: PointLight2D = $Aura;
@export var HP = 100
@export var falldmg_multiplier = 10
@export var globalLight: DirectionalLight2D = null;

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

var custom_cross := load("res://imgs/cross.png")
var custom_cursor := load("res://imgs/cursor.png")

func takeDMG(dmgvalue):
	if HP > dmgvalue:
		HP -= dmgvalue
	else:
		HP = 0
		$"../GUI/Menus".defeat()


func climb(delta):
	
	if climbInputU:
		velocity.y = -80
		move_and_slide()
		
	if Input.is_action_pressed("Forward") && !climbInputU && !climbInputD:
		velocity = Vector2(0,0)
		climbInputU = true
		$AnimationPlayer2.play("a_climbing_2")
		await get_tree().create_timer(0.45).timeout
		$AnimationPlayer2.stop()
		climbInputU = false

		
	

	if climbInputD:
		velocity.y = 80
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
	airtime += 2
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

	#self.add_child(GUN)


		

func _process(delta):
	if isUsingCommunicationRoom:
		if global_position.distance_to(positionWhenUsedCommunicationRoom) > 1.0 or Input.is_action_pressed("click"):
			isUsingCommunicationRoom = false;
			camera.center_on_player();
			globalLight.energy = 3.0;
			aura.enabled = true;
	
	
	#if gunsAreGo:
		#Input.set_custom_mouse_cursor(custom_cross, Input.CURSOR_ARROW) #TODO fix this shit
	#else:
		#Input.set_custom_mouse_cursor(custom_cursor, Input.CURSOR_ARROW)
	
	
	if $"../Monster/MonsterBody".getHealth() <= 0:
		$"../GUI/Menus".victory() #virctory here

	_deafenTimer = max(0, _deafenTimer - delta);
	
	if _deafenTimer <= 0:
		checkClimbInput()
		if !isClimbing:
			update_animation_tree_param()
		else:
			climb(delta)
		interact()
	
	if $"../Storm".isStorm():
		ammoCooldown = []
		hospitalCooldown = false

@onready var camera = $Camera

var airtime = 0
@export var airtimeforDMG = 0.4
func _physics_process(delta: float) -> void:
	if isClimbing:
		airtime = 0
	
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
				var dmgtaken = ceil(airtime*falldmg_multiplier)
				if HP <= dmgtaken:
					$"../GUI/Menus".defeat() #death here
				else:
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
var waterBody: Area2D = null;

var isInGenerator = false
var isInGeneratorVent = false

var isInCom = false
var isUsingCommunicationRoom: bool = false;
var positionWhenUsedCommunicationRoom: Vector2 = Vector2.ZERO;

var isInBed = false


var ladder_array = []

var lastWeaponsBuddy
var generator
func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.name == "Weapons":
		isInWeapons = true
		lastWeaponsBuddy = area
	else:
		isInWeapons = false
	
	
	if area.name == "Healing":
		isInHospital = true
		#$Label.show()
	else:
		isInHospital = false

	
	if area is WaterValve:
		waterBody = area;
		isInWater = true
		#$Label.show()
	else:
		isInWater = false
		waterBody = null;
	
	
	if area.name == "Vent":
		isInGeneratorVent = true
		#$Label.show()
	else:
		isInGeneratorVent = false

	
	if area.name == "Generator":
		isInGenerator = true
		generator = area
		#$Label.show()
	else:
		isInGenerator = false
	
	
	if area.name == "Communication":
		isInCom = true
		$communications.show()
	else:
		isInCom = false
	
	
	if area.name == "Bed":
		isInBed = true
		#$Label.show()
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
		
		$"unused  weapons".hide()
		$expired.hide()
	
	if area.name == "Healing":
		isInHospital = false
		$expired.hide()
		$"unused hospital".hide()	
		
	if area is WaterValve:
		isInWater = false
		waterBody = null;
		$water.hide()
		#$Label.hide()
	
	
	
	if area.name == "Vent":
		isInGeneratorVent = false
		#$Label.hide()
		
	if area.name == "Generator":
		isInGenerator = false
		$generator.hide()
		#$Label.hide()
		
	
	if area.name == "Communication":
		isInCom = false
		$communications.hide()

		
	
	if area.name == "Bed":
		isInBed = false
		#$Label.hide()
	
	
	if area.name == "Ladder":
		ladder_array.pop_front()
		if ladder_array.size() == 0:
			isClimbing = false
			GUN.isClimbing = isClimbing
			$AnimationTree2.active = true
	
	
var ammoCooldown = []
var hospitalCooldown = false
var barrel
func interact():
	
	if isInGenerator:
		barrel = generator.get_parent().get_parent().find_child("Barrel")
		
	if !$"../Storm".isStorm(): 
		
		if isInWeapons:
			if !ammoCooldown.has(lastWeaponsBuddy):
				$"unused  weapons".show()
				$expired.hide()
			else:
				$expired.show()
				$"unused  weapons".hide()
		
		if isInWeapons && Input.is_action_just_pressed("interact") && !ammoCooldown.has(lastWeaponsBuddy):
			GUN.ammunition_pool_total += 15
			ammoCooldown.append(lastWeaponsBuddy)
		
		
		if isInHospital:
			if !hospitalCooldown:
				$"unused hospital".show()
				$expired.hide()
			else:
				$expired.show()
				$"unused hospital".hide()
		
		
		if isInHospital && Input.is_action_just_pressed("interact") && !hospitalCooldown:
			if HP +50 > maxHP:
				self.HP = maxHP
			if HP < maxHP:
				self.HP += 25
			hospitalCooldown = true
			
		if isInGenerator && barrel.isExploded():
			$generator.show()
			
			if Input.is_action_just_pressed("interact"):
				barrel.reset()

	else:
		$generator.hide()
		$"unused hospital".hide()
		$"unused  weapons".hide()
		$expired.hide()




	
	
	if isInWater:
		if waterBody._waterIsRaisen:
			$water.hide()
		else:
			$water.show()
	
	if isInWater && Input.is_action_just_pressed("interact"):
		(waterBody as WaterValve).raiseUpWater();
	
	if isInGeneratorVent && Input.is_action_just_pressed("interact"):
		pass
		
	
	
	if isInCom && Input.is_action_just_pressed("interact"):
		$communications.hide()
		# depending on zoom implementation
		(camera as PanZoomCamera).center_on_bunker();
		isUsingCommunicationRoom = true;
		positionWhenUsedCommunicationRoom = self.global_position;
		globalLight.energy = 0.25;
		aura.enabled = false;
	
	if isInBed && Input.is_action_just_pressed("interact"):
		pass
