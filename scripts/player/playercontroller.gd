extends Node


#hp and other stats manipulation
#hook in for inventory

var playerEmpty = preload("res://scenes/player.tscn")
var player = playerEmpty.instantiate()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player.position = Vector2(490, 0)
	player.world = $".."
	self.add_child(player)
	print("child added")
	
	
	#player.anims.play()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	if Input.is_key_pressed(KEY_E):
		player.attemptInventory = true
	else:
		player.attemptInventory = false
	
	# on keypress => stop movement open inventory
	
	
	if player.inInventory == true:
		# do inventory shit

		if Input.is_key_pressed(KEY_E):
			await get_tree().create_timer(1).timeout
			player.inInventory = false
	
	
	# on second keypress => regain controll
	
	
	pass
