extends Sprite2D
class_name Gun

@export var monster: Monster = null;

var spawner
var world
var isClimbing = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	randomize()
	var shots_per_second = rpm / 60.0
	interval = 1 / shots_per_second
	ray_cast.enabled = true
	


var bulletEmpty = preload("res://scenes/bullet.tscn")
var casingEmpty = preload("res://scenes/casing.tscn")
var isReloading = false

var isFailing = false
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if !isClimbing:
		var direction = get_global_mouse_position() - self.global_position
		var direction_angle = direction.angle()
		
		if visible && !isReloading:		
			if !Input.is_action_pressed("click") || ammunition == 0:
				self.rotation = direction_angle
			
			
			if Input.is_action_pressed("reload") && isReloading == false && ammunition_pool_total > 0:
				isReloading = true
				
				if rotation > 0.5*PI || rotation < -0.5*PI : # can do easein
					rotation = PI
				else	:
					rotation = 0

				
				$AnimationPlayer.play("reload_new")
				
				if ammunition_pool_total >= 30 : 
					if ammunition == 0:
						ammunition_pool_total -= 30
						ammunition = 30
					else:
						ammunition_pool_total += ammunition
						ammunition_pool_total -= 30
						ammunition = 30

				else:
					ammunition = ammunition_pool_total
					ammunition_pool_total = 0
				
				await get_tree().create_timer(2.5).timeout
				isReloading = false
				return


			
			
			
			if ammunition > 0:
				manageShot(direction_angle, delta)
			elif !isReloading && Input.is_action_pressed("click") && !isFailing:
				isFailing = true
				$AudioStreamPlayer.play()
				await get_tree().create_timer(0.5).timeout
				isFailing = false



		else:
			if !isReloading:
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

@export var ammunition_pool_total = 200
@export var ammunition = 30


@onready var ray_cast = $RayCast2D

func manageShot(direction_angle, delta):
	var time_between_shot = (Time.get_ticks_msec() - last_shot_time) / 1000.0
	ray_cast.force_raycast_update()
	var ray_cast_collison = !ray_cast.is_colliding()
	
	if Input.is_action_pressed("click") && time_between_shot >= interval:
		if ray_cast_collison:
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
		var angle_diff = target_angle - rotation

		if angle_diff > PI:
			angle_diff -= 2 * PI
		
		elif angle_diff < -PI:
			angle_diff += 2 * PI
			
		var recoil_mitigation = 10.0  
		
		if abs(angle_diff) > 0.1:  #adjust to not overcorrect
			if angle_diff > 0:
				rotate(recoil_mitigation * delta)
			else:
				rotate(-recoil_mitigation * delta)
	




func shoot():
	var bullet := bulletEmpty.instantiate() as Bullet
	bullet.initialize(self, self.rotation, self.global_position + Vector2(20, 0).rotated(self.rotation));
	
	if rapidShotCounter == 0:
		$AnimationPlayer.play("fire_new_2")
	else:
		$AnimationPlayer.play("fire_new")

	world.add_child(bullet)
	
	ammunition -= 1
	
	var casing = casingEmpty.instantiate()
	casing.angular_velocity = -40 - randi_range(0, 10)

	if !spawner.flip_h: 
		casing.global_position = self.global_position + Vector2(7.5, -2.2).rotated(self.rotation) 
		casing.initial_velocity = Vector2(-75+randi_range(-20, 20), -150+randi_range(-20, 20)).rotated(self.rotation)
	else:
		casing.global_position = self.global_position + Vector2(7.5, 2.2).rotated(self.rotation) 
		casing.initial_velocity = Vector2(-75+randi_range(-20, 20), 150+randi_range(-20, 20)).rotated(self.rotation)

	
	world.add_child(casing)
	
func damageMonster() -> void:
	monster.takeDamage();
