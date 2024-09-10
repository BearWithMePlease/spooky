extends CharacterBody2D

@export var speed = 200 # How fast the player will move (pixels/sec).

func _process(delta: float) -> void:
	var velocity = Vector2.ZERO # The player's movement vector.
	if Input.is_action_pressed("right"):
		velocity.x += 1
	if Input.is_action_pressed("left"):
		velocity.x -= 1
	if Input.is_action_pressed("back"):
		velocity.y += 1
	if Input.is_action_pressed("forward"):
		velocity.y -= 1

	if velocity.length() > 0:
		velocity = velocity.normalized() * speed

	self.move_and_collide(velocity * delta)
