extends Node2D

@onready var modules = $Modules
@onready var player = $Player

func _ready() -> void:
	# Load modules from Module Builder (safed in Globals)
	for builder_module in Globals.builder_modules:
		modules.add_child(builder_module)
	
	# Spawn player at spawn point
	var spawn_point = get_tree().get_first_node_in_group("spawn_point") as Node2D
	if spawn_point != null:
		player.global_position = spawn_point.global_position
	
