extends Sprite2D

class_name Bullet


@onready var ray_cast = $RayCast2D

var _gun: Gun = null;
func initialize(gun: Gun, rot: float, pos: Vector2) -> void:
	_gun = gun;
	self.rotation = rot;
	self.global_position = pos;


var sound = preload("res://scenes/shotsfx.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var sound2 = sound.instantiate()
	_gun.add_child(sound2)
	ray_cast.enabled = true
	$Area2D.monitoring = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	move_local_x(880 * delta)
	
	#ray_cast.target_position += Vector2(20*delta, 0)
	ray_cast.force_raycast_update()


	if ray_cast.is_colliding():
		var body = ray_cast.get_collider()
		#print("Bullet hit: ", body)
		if body.get_class() != "Bullet" && body.get_class() != "CharacterBody2D":
			hide()
			
			if body.get_class() == "StaticBody2D": #wall
				var hit = hitEmpty.instantiate()
				hit.position = ray_cast.get_collision_point()
				hit.rotation = rotation
				get_parent().add_child(hit)
			elif body is MonsterFace:
				body.get_parent().get_parent().takeDamage()
				var hit = hitBloodEmpty.instantiate()
				hit.position = ray_cast.get_collision_point()
				hit.rotation = rotation
				get_parent().add_child(hit)
				
		
			queue_free()
		else:
			print("fuckoff")

	#move_local_x(1000*delta)
	pass




var hitEmpty = preload("res://scenes/hit.tscn") #wall
var hitBloodEmpty = preload("res://scenes/hitblood.tscn") #wall

#
#func _on_area_2d_body_entered(body: Node2D) -> void:
	#print(body.get_class())
	#if body.get_class() != "Bullet" && body.get_class() != "CharacterBody2D":
		#hide()
		#
		#if body.get_class() == "StaticBody2D": #wall
			#var hit = hitEmpty.instantiate()
			#hit.position = position
			#hit.rotation = rotation
			#get_parent().add_child(hit)
		#else:
			#var hit = hitBloodEmpty.instantiate()
			#hit.position = position
			#hit.rotation = rotation
			#get_parent().add_child(hit)
		#
		#queue_free()
	#else:
		#print("fuckoff")
	#pass # Replace with function body.
