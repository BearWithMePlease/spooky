extends Sprite2D


var spawner
var world


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var shots_per_second = rpm / 60.0
	interval = 1 / shots_per_second
	pass # Replace with function body.

var bulletEmpty = preload("res://bullet.tscn")



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	var mouse_position = get_viewport().get_mouse_position()
	var direction = mouse_position - self.global_position
	
	
	
	if !Input.is_action_pressed("shoot") || ammunition == 0:
		self.rotation = direction.angle()
	
	
	if Input.is_action_pressed("reload"):
		$AnimationPlayer.play("reload_new")
		ammunition = 30
	
	if rotation > PI:
		rotation -= 2*PI
	
	if rotation < -PI:
		rotation += 2*PI	
	
	if ammunition > 0:
		manageShot(direction.angle(), delta)
		

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
	if Input.is_action_pressed("shoot") && time_between_shot >= interval:
		
		
		if time_between_shot < interval+0.1:
			rapidShotCounter += 0.5
		else:
			rapidShotCounter = 0
			
		shoot()
		
		var bump = randf_range(-0.03, 0.03)* min(9,rapidShotCounter)
		if bump > 0:
			bump = min(1, bump)
		if bump < 0:
			bump = max(-1, bump)
			
		self.rotation = self.rotation + bump
		last_shot_time = Time.get_ticks_msec()
		
		
		#SPRAY CONTROL
		var target_angle = direction_angle		
		var angle_difference = target_angle - rotation

		if angle_difference > PI:
			angle_difference -= 2 * PI
		
		elif angle_difference < -PI:
			angle_difference += 2 * PI
			
		var recoil_mitigation = 3.0  
		
		if abs(angle_difference) > 0.1:  #adjust to not overcorrect
			if angle_difference > 0:
				rotate(recoil_mitigation * delta)
			else:
				rotate(-recoil_mitigation * delta)


func shoot():
	var bullet = bulletEmpty.instantiate()
	bullet.rotation = self.rotation
	if !flip_v: 
		bullet.global_position = self.global_position + Vector2(100, 0).rotated(self.rotation)
	else:
		bullet.global_position = self.global_position + Vector2(100, 0).rotated(self.rotation)
	
	
	if rapidShotCounter == 0:
		$AnimationPlayer.play("fire_new_2")
	else:
		$AnimationPlayer.play("fire_new")

	world.add_child(bullet)
	ammunition -= 1
