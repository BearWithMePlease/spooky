extends RigidBody2D
class_name dog

var initial_velocity = Vector2(-100, -300)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	linear_velocity = initial_velocity
	angular_velocity = -40
	await get_tree().create_timer(3).timeout
	queue_free()

	#collision_mask = 1 << 0
