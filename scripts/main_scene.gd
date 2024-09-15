extends Node2D
class_name MainScene

signal finished_ready

@export var monster: Monster = null
@onready var modules := $Modules as NavigationRegion2D
@onready var player = $Player

func _ready() -> void:
	# Load modules from Module Builder (safed in Globals)
	for builder_module in Globals.builder_modules:
		modules.add_child(builder_module)
		
	# Spawn player at spawn point
	var spawn_point = get_tree().get_first_node_in_group("spawn_point") as Node2D
	if spawn_point != null:
		player.global_position = spawn_point.global_position
		#monster.global_position = spawn_point.global_position
		
	# Calculate boundries of bunker to bake navigation polygons
	var bounds := getBunkerBounds();
	modules.navigation_polygon.add_outline(PackedVector2Array([
		bounds.position, 
		Vector2(bounds.position.x + bounds.size.x, bounds.position.y), 
		bounds.position + bounds.size, 
		Vector2(bounds.position.x, bounds.position.y + bounds.size.y)
	]))
	modules.bake_navigation_polygon()
	
	finished_ready.emit()

func getBunkerBounds() -> Rect2:
	var boundries := _getAllModuleBoundingBoxes()
	var from := Vector2(1e9, 1e9)
	var to := Vector2(-1e9, -1e9)
	for boundry in boundries:
		if from.x > boundry.position.x:
			from.x = boundry.position.x
		if to.x < boundry.position.x + boundry.size.x:
			to.x = boundry.position.x + boundry.size.x
		if from.y > boundry.position.y:
			from.y = boundry.position.y
		if to.y < boundry.position.y + boundry.size.y:
			to.y = boundry.position.y + boundry.size.y
	return Rect2(from, to - from);

# Founds boundry of each module
func _getAllModuleBoundingBoxes() -> Array[Rect2]:
	var boundsArr: Array[Rect2] = []
	for child in modules.get_children():
		var module := child as Module
		var moduleSize: Vector2 = Modules.scales[module.type]
		var width: float = moduleSize.x * Modules.GRID_SIZE
		var height: float = moduleSize.y * Modules.GRID_SIZE
		var boundry := Rect2(module.global_position.x - Modules.GRID_SIZE * 0.5, module.global_position.y + Modules.GRID_SIZE * 0.5 - height, width, height)
		boundsArr.append(boundry)
	return boundsArr
