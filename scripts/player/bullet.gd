extends Sprite2D

class_name Bullet

var _gun: Gun = null;
func initialize(gun: Gun, rot: float, pos: Vector2) -> void:
	_gun = gun;
	self.rotation = rot;
	self.global_position = pos;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Area2D.monitoring = true
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	move_local_x(1000*delta)
	pass




static var hitEmpty = preload("res://scenes/hit.tscn") #wall
static var hitBloodEmpty = preload("res://scenes/hitblood.tscn") #wall


func _on_area_2d_body_entered(body: Node2D) -> void:
	if not body is Bullet and not body is CharacterBody2D:
		hide()
		
		if body is StaticBody2D: #wall
			var hit = hitEmpty.instantiate()
			hit.position = position
			hit.rotation = rotation
			get_parent().add_child(hit)
		elif body is MonsterFace:
			var hit = hitBloodEmpty.instantiate()
			hit.position = position
			hit.rotation = rotation
			get_parent().add_child(hit)
			if _gun != null:
				_gun.damageMonster();
		
		queue_free()
