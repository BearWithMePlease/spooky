extends AudioStreamPlayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	play()
	print(volume_db)
	await get_tree().create_timer(1).timeout
	queue_free()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass