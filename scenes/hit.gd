extends AnimatedSprite2D

var target
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rotation += deg_to_rad(-90)
