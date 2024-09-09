extends HBoxContainer

class_name Modules

static var GRID_SIZE = 96
static var MODULE_PATH = "res://imgs/modules/"
static var HASH_SHIFT = 16 # -> max value 2^16 otherwise collision possible

enum ModuleDirection {
	N = 0b00, # None
	L = 0b01, # Left
	R = 0b10, # Right
	H = 0b11, # Horizontal (Left+Right)
}

enum ModuleStairDirection {
	N = 0b00, # None
	U = 0b01, # Up
	D = 0b10, # Down
	V = 0b11  # Vertical (Up+Down)
}

enum ModuleType {
	NONE,
	CORRIDOR,
	STAIR,
	ROOM_1,
	ROOM_2,
	ROOM_3
}

# Module has base size of grid_size. Larger modules can be of n*grid_size in each direction
# module_scales[ModuleType] = Vector2(n,k) (actual_size = n * grid_size)
static var scales = {
	ModuleType.NONE: Vector2(0,0),
	ModuleType.CORRIDOR: Vector2(1,1),
	ModuleType.STAIR: Vector2(1,1),
	ModuleType.ROOM_1: Vector2(1,1),
	ModuleType.ROOM_2: Vector2(1,2),
	ModuleType.ROOM_3: Vector2(2,2)
}

# Module has docking slots. Add slot to array where docking a different module is possible
# ONLY ONE CONNECTION PER SIDE
# IMPORTANT: left connection is first vector && right connection is last vector
static var connections = {
	ModuleType.NONE: [],
	ModuleType.CORRIDOR: [Vector2(1,1)],
	ModuleType.STAIR: [Vector2(1,1)],
	ModuleType.ROOM_1: [Vector2(1,1)],
	ModuleType.ROOM_2: [Vector2(1,1)],
	ModuleType.ROOM_3: [Vector2(1,1), Vector2(2,1)]
}

var module_button := preload("res://prefab/ModuleButton.tscn")

@export var color_valid_spot: Color
@export var color_invalid_spot: Color
@export var animation_duration: float = 0.1

var grid: Dictionary = {}

@onready var mover = $"../../Building_Space/Module_Mover"
var moving = false
var grid_position: Vector2
var type: ModuleType = ModuleType.NONE
var mouse_over_gui = false

var animation_running = false
var animation_old_position: Vector2 = Vector2.ZERO
var animation_new_position: Vector2 = Vector2.ZERO
var animation_weight: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mover.visible = false
	
	if len(ModuleType.keys()) != len(scales.keys()) or len(ModuleType.keys()) != len(connections.keys()):
		push_error("ModuleType, module_scales or connections length does not match")
		return
	
	# Instantiate available modules (gui module button)
	for type in ModuleType.values():
		if type == ModuleType.NONE:
			continue
		
		var button = module_button.instantiate()
		button.module_type = type
		button.module_direction = ModuleDirection.N
		self.add_child(button)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if moving:
		var new_grid_position = get_grid_position()
		move_to_cursor(delta, new_grid_position) # move module to cursor with animation
		
		# only process if grid_position has changed or build action
		if new_grid_position == grid_position and not Input.is_action_just_pressed("click"):
			return
		
		var old_grid_position = grid_position
		grid_position = new_grid_position

		if grid_position != old_grid_position and can_build_module(old_grid_position):
			# Remove module direction
			adjust_surroundings(old_grid_position, true)

		# set color highlighting & on click -> build function
		if can_build_module(grid_position):
			mover.modulate = color_valid_spot
			
			var new_mover_direction = adjust_surroundings(grid_position)
			mover.set_direction(new_mover_direction)
			
			if Input.is_action_just_pressed("click"):
				on_build_module()
		else:
			mover.modulate = color_invalid_spot
			mover.set_direction(ModuleDirection.N)

func mouse_gui_status(mouse_over_gui:bool):
	self.mouse_over_gui = mouse_over_gui

static func get_module_path(type: ModuleType, direction: ModuleDirection):
	return MODULE_PATH + ModuleType.find_key(type).to_lower() + "_" + ModuleDirection.find_key(direction).to_lower() + ".png"

# hash grid position. NEEDS to be int due to shift operation
static func get_grid_id(position:Vector2i):
	return (position.x << HASH_SHIFT) + position.y

func move_to_cursor(delta: float, grid_position: Vector2):
	if animation_running:
		animation_weight = clamp(animation_weight + delta / animation_duration, 0, 1)
		mover.position = lerp(animation_old_position, animation_new_position, animation_weight)
		
		if animation_weight == 1.0:
			animation_running = false

	if grid_position != animation_new_position:
		# starting new animation
		animation_running = true
		animation_old_position = mover.position
		animation_new_position = grid_position
		animation_weight = 0

func on_module_type_select(type: ModuleType, texture: CompressedTexture2D):
	print("Using: ", ModuleType.find_key(type))
	
	self.type = type
	moving = true
	animation_new_position = get_grid_position()
	mover.init(animation_new_position, type, ModuleDirection.N)
	mover.z_index = 1
	
	# set offset
	#mover.offset = -scales[type] * grid_size / 2
	

# Gets mouse to grid position. Only works for positive coords
func get_grid_position():
	var mouse_position = mover.get_global_mouse_position()
	
	var coord = Vector2i(roundi(mouse_position.x), roundi(mouse_position.y))
	var modulo = Vector2i(coord.x % GRID_SIZE, coord.y % GRID_SIZE)

	coord.x = coord.x - modulo.x if modulo.x < GRID_SIZE / 2 else coord.x + (GRID_SIZE - modulo.x)
	coord.y = coord.y - modulo.y if modulo.y < GRID_SIZE / 2 else coord.y + (GRID_SIZE - modulo.y)
	
	return Vector2(coord.x, coord.y)

# Check if there is already a module in that position (on grid)
func can_build_module(grid_position: Vector2):
	if mouse_over_gui: return false
	
	# check all grid slots
	for x in range(scales[type].x):
		for y in range(scales[type].y):
			var new_pos = Vector2(grid_position.x + GRID_SIZE * x,grid_position.y - GRID_SIZE * y)
			if grid.has(get_grid_id(new_pos)):
				return false
	
	return true

func adjust_surroundings(position: Vector2, removing = false) -> ModuleDirection:
	var connection_slot_left = position + GRID_SIZE * (connections[type][0]-Vector2.ONE)
	var connection_slot_right = position + GRID_SIZE * (connections[type][len(connections[type])-1]-Vector2.ONE)
	
	var left_position = connection_slot_left + Vector2(-GRID_SIZE, 0)
	var right_position = connection_slot_right + Vector2(GRID_SIZE, 0)
	
	var grid_module: GridModule
	var mover_direction: ModuleDirection = ModuleDirection.N
	if grid.has(get_grid_id(left_position)):
		grid_module = grid.get(get_grid_id(left_position)) as GridModule
		
		if connections[grid_module.node.type].has(grid_module.scale_index):
			grid_module.node.adjust_direction(ModuleDirection.R, removing)
			mover_direction = ModuleDirection.L
	if grid.has(get_grid_id(right_position)):
		grid_module = grid.get(get_grid_id(right_position)) as GridModule
		
		if connections[grid_module.node.type].has(grid_module.scale_index):
			grid_module.node.adjust_direction(ModuleDirection.L, removing)
			if mover_direction == ModuleDirection.L: mover_direction = ModuleDirection.H
			else: mover_direction = ModuleDirection.R
	
	return mover_direction

func on_build_module():
	# Instantiate module prefab
	var node = mover.duplicate() as Module
	node.init(grid_position, type, mover.direction)
	mover.get_parent().add_child(node)
	
	# Add module to each grid slot it occupies
	for x in range(scales[type].x):
		for y in range(scales[type].y):
			print(x," ", y)
			var module = GridModule.new(node, Vector2(x+1,y+1))
			var slot_position = Vector2(node.position.x + GRID_SIZE * x, node.position.y - GRID_SIZE * y)
			grid[get_grid_id(slot_position)] = module
	
	# Clean up
	moving = false
	mover.visible = false
	type = ModuleType.NONE
	grid_position = Vector2(-1, -1)
