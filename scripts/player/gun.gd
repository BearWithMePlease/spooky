extends Sprite2D


var spawner
var world


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	randomize()
	var shots_per_second = rpm / 60.0
	interval = 1 / shots_per_second
	pass # Replace with function body.

var bulletEmpty = preload("res://scenes/bullet.tscn")
var casingEmpty = preload("res://scenes/casing.tscn")



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	var direction = get_global_mouse_position() - self.global_position
	var direction_angle = direction.angle()
	
	if visible:		
		if !Input.is_action_pressed("click") || ammunition == 0:
			self.rotation = direction_angle
		
		
		if Input.is_action_pressed("reload"):
			$AnimationPlayer.play("reload_new")
			ammunition = 30
		
		
		
		if ammunition > 0:
			manageShot(direction_angle, delta)
	else:
		self.rotation = direction_angle

	if rotation > PI:
		rotation -= 2*PI
	
	if rotation < -PI:
		rotation += 2*PI	
		#print(rotation)
	if rotation > 0.5*PI || rotation < -0.5*PI :
		#flip_v = true
		
		if(scale.y > 0):
			scale.y *= -1
		spawner.flip_h = true
	else:
		
		if(scale.y < 0):
			scale.y *= -1
		
		#flip_v = false
		spawner.flip_h = false

	
	
var rpm = 600
var interval
var last_shot_time = 0.0
var rapidShotCounter = 0

var ammunition = 30

	
func manageShot(direction_angle, delta):
	var time_between_shot = (Time.get_ticks_msec() - last_shot_time) / 1000.0
	if Input.is_action_pressed("click") && time_between_shot >= interval:
		
		
		if time_between_shot < interval+0.1:
			rapidShotCounter += 0.5
		else:
			rapidShotCounter = 0
			
		shoot()
		
		var bump = randf_range(-0.02, 0.02)* min(9,rapidShotCounter)
		if bump > 0:
			bump = min(0.1, bump)
		if bump < 0:
			bump = max(-0.1, bump)
			
		self.rotation = self.rotation + bump
		last_shot_time = Time.get_ticks_msec()
		
		#SPRAY CONTROL
		var target_angle = direction_angle		
		var angle_difference = target_angle - rotation

		if angle_difference > PI:
			angle_difference -= 2 * PI
		
		elif angle_difference < -PI:
			angle_difference += 2 * PI
			
		var recoil_mitigation = 10.0  
		
		if abs(angle_difference) > 0.1:  #adjust to not overcorrect
			if angle_difference > 0:
				rotate(recoil_mitigation * delta)
			else:
				rotate(-recoil_mitigation * delta)


func shoot():
	var bullet = bulletEmpty.instantiate()
	bullet.rotation = self.rotation
	bullet.global_position = self.global_position + Vector2(55, 0).rotated(self.rotation) # redundant
	
	
	
	if rapidShotCounter == 0:
		$AnimationPlayer.play("fire_new_2")
	else:
		$AnimationPlayer.play("fire_new")

	world.add_child(bullet)
	ammunition -= 1
	
	var casing = casingEmpty.instantiate()
	casing.angular_velocity = -40 - randi_range(0, 10)

	if !spawner.flip_h: 
		casing.global_position = self.global_position + Vector2(23, -2.2).rotated(self.rotation) 
		casing.initial_velocity = Vector2(-150+randi_range(-20, 20), -300+randi_range(-20, 20)).rotated(self.rotation)
	else:
		casing.global_position = self.global_position + Vector2(23, 2.2).rotated(self.rotation) 
		casing.initial_velocity = Vector2(-150+randi_range(-20, 20), 300+randi_range(-20, 20)).rotated(self.rotation)

	
	world.add_child(casing)
