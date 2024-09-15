extends Node2D
class_name Module

const GRID_SIZE = 64
const MODULE_PATH = "res://imgs/modules/"
const HASH_SHIFT = 16 # -> max value 2^16 otherwise collision possible

enum ModuleDirection {
	N = 0b00, # None
	L = 0b01, # Left
	R = 0b10, # Right
	H = 0b11, # Horizontal (Left+Right)
}

enum ModuleVerticalDirection {
	N = 0b0000, # None
	U = 0b0100, # Up
	D = 0b1000, # Down
	V = 0b1100  # Vertical (Up+Down)
}

enum ModuleType {
	NONE,
	CORRIDOR,
	GENERATOR,
	COMMUNICATION,
	ENTRY,
	WATER,
	WEAPONS,
	HOSPITAL,
	BEDROOM
}

# Module has base size of grid_size. Larger modules can be of n*grid_size in each direction
# module_scales[ModuleType] = Vector2(n,k) (actual_size = n * grid_size)
static var scales = {
	ModuleType.NONE: Vector2(0,0),
	ModuleType.CORRIDOR: Vector2(1,1),
	ModuleType.GENERATOR: Vector2(4,2),
	ModuleType.COMMUNICATION: Vector2(2,2),
	ModuleType.ENTRY: Vector2(3,2),
	ModuleType.WATER: Vector2(3,2),
	ModuleType.WEAPONS: Vector2(2,2),
	ModuleType.HOSPITAL: Vector2(3, 2),
	ModuleType.BEDROOM: Vector2(2, 2),
}

# Module has docking slots. Add slot to array where docking a different module is possible
# ONLY ONE CONNECTION PER SIDE
# IMPORTANT: left connection is first vector && right connection is last vector
static var connections = {
	ModuleType.NONE: [],
	ModuleType.CORRIDOR: [Vector2(1,1)],
	ModuleType.GENERATOR: [Vector2(1,1), Vector2(4,1)],
	ModuleType.COMMUNICATION: [Vector2(1,1), Vector2(2,1)],
	ModuleType.ENTRY: [Vector2(1,1), Vector2(3,1)],
	ModuleType.WATER: [Vector2(1,1), Vector2(3,1)],
	ModuleType.WEAPONS: [Vector2(1,1), Vector2(2,1)],
	ModuleType.HOSPITAL: [Vector2(1,1), Vector2(3, 1)],
	ModuleType.BEDROOM: [Vector2(1,1), Vector2(2,1)],
}

static var max_module_count = {
	ModuleType.NONE: 0,
	ModuleType.CORRIDOR: 64,
	ModuleType.GENERATOR: 1,
	ModuleType.COMMUNICATION: 1,
	ModuleType.ENTRY: 1,
	ModuleType.WATER: 2,
	ModuleType.WEAPONS: 2,
	ModuleType.HOSPITAL: 1,
	ModuleType.BEDROOM: 3
}

var is_mover: bool
var connected: bool = false

var type: Module.ModuleType
var direction: Module.ModuleDirection
var vertical_direction: Module.ModuleVerticalDirection

var sprite: Sprite2D
var connection_left: CollisionPolygon2D
var connection_right: CollisionPolygon2D

# Only used if type is corridor
var ceiling_light: PointLight2D
var ceiling_light_sound: AudioStreamPlayer2D
var connection_ceiling: CollisionPolygon2D
var connection_floor: CollisionPolygon2D
var vertical_connection_left: CollisionPolygon2D
var vertical_connection_right: CollisionPolygon2D
var vertical_ceiling_left: CollisionPolygon2D
var vertical_ceiling_right: CollisionPolygon2D
var vertical_floor_left: CollisionPolygon2D
var vertical_floor_right: CollisionPolygon2D
var ladder_up: CollisionShape2D
var ladder_down: CollisionShape2D

func _ready() -> void:
	# Useful for debugging:
	# init(Vector2(0,0), Module.ModuleType.CORRIDOR, Module.ModuleDirection.H, Module.ModuleVerticalDirection.U)
	
	var module_mover = get_node_or_null("%Module_Mover")
	if module_mover != null and self.get_instance_id() == module_mover.get_instance_id():
		is_mover = true
		z_index = 100

func init(module_position:Vector2, type:Module.ModuleType, direction: Module.ModuleDirection, vertical_direction: Module.ModuleVerticalDirection = Module.ModuleVerticalDirection.N):
	self.position = module_position
	self.type = type
	self.direction = direction
	self.vertical_direction = vertical_direction
	
	fetch_nodes()
	set_direction(direction, vertical_direction)
	
	self.visible = true
	sprite.modulate = Color.WHITE

	var scales = Module.scales[self.type]
	sprite.position.x = -Module.GRID_SIZE / 2.0
	sprite.position.y = -(max(0, scales.y - 1.0) * Module.GRID_SIZE + Module.GRID_SIZE / 2.0)

func fetch_nodes():
	self.sprite = get_node_or_null(^"Sprite")
	if self.sprite == null:
		push_error("Failed to fetch sprite node")

	if self.is_mover:
		return
	
	self.connection_left = get_node_or_null(^"Sprite/Borders/Connection_Left")
	self.connection_right = get_node_or_null(^"Sprite/Borders/Connection_Right")
	if self.connection_left == null || self.connection_right == null:
		push_error("Failed to fetch some Essential nodes")
	
	# Only used if type is corridor
	if self.type == Module.ModuleType.CORRIDOR:
		self.ceiling_light = get_node_or_null(^"Sprite/Lights/Ceiling_Light")
		self.ceiling_light_sound = get_node_or_null(^"Sprite/Lights/Ceiling_Light/Sound")
		self.connection_ceiling = get_node_or_null(^"Sprite/Borders/Ceiling")
		self.connection_floor = get_node_or_null(^"Sprite/Borders/Floor")
		self.vertical_connection_left = get_node_or_null(^"Sprite/Borders/Vertical_Connection_Left")
		self.vertical_connection_right = get_node_or_null(^"Sprite/Borders/Vertical_Connection_Right")
		self.vertical_ceiling_left = get_node_or_null(^"Sprite/Borders/Vertical_Ceiling_Left")
		self.vertical_ceiling_right = get_node_or_null(^"Sprite/Borders/Vertical_Ceiling_Right")
		self.vertical_floor_left = get_node_or_null(^"Sprite/Borders/Vertical_Floor_Left")
		self.vertical_floor_right = get_node_or_null(^"Sprite/Borders/Vertical_Floor_Right")
		self.ladder_down = get_node_or_null(^"Sprite/Interactables/Ladder/Down")
		self.ladder_up = get_node_or_null(^"Sprite/Interactables/Ladder/Up")


static func get_module_path(type: Module.ModuleType, direction: Module.ModuleDirection, vertical_direction: Module.ModuleVerticalDirection = Module.ModuleVerticalDirection.N):
	var type_str = Module.ModuleType.find_key(type).to_lower()
	var direction_str = Module.ModuleDirection.find_key(direction).to_lower()
	var vertical_direction_str = ("_" + Module.ModuleVerticalDirection.find_key(vertical_direction).to_lower()) if type == Module.ModuleType.CORRIDOR else ""
	
	return Module.MODULE_PATH + type_str + "/" + direction_str + vertical_direction_str + ".png"
	
func set_direction(direction: Module.ModuleDirection, vertical_direction: Module.ModuleVerticalDirection = Module.ModuleVerticalDirection.N):
	self.direction = direction
	self.vertical_direction = vertical_direction
	
	var path = Module.get_module_path(self.type, self.direction, self.vertical_direction)
	self.sprite.texture = load(path)
	handle_doors()

func adjust_direction(direction: Module.ModuleDirection, vertical_direction: Module.ModuleVerticalDirection, removing: bool):
	if removing: set_direction(self.direction & (~direction), self.vertical_direction & (~vertical_direction))	# Remove
	else: set_direction(self.direction | direction, self.vertical_direction | vertical_direction) 				# Add

func handle_doors():
	if self.is_mover or self.connection_left == null or self.connection_right == null:
		return
	
	if self.type != Module.ModuleType.CORRIDOR || self.vertical_direction == Module.ModuleVerticalDirection.N:
		# Handle every module type except when a corridor has a vertical direction
		self.connection_left.disabled = direction & Module.ModuleDirection.L != 0
		self.connection_right.disabled = direction & Module.ModuleDirection.R != 0
		
		if self.type == Module.ModuleType.CORRIDOR:
			self.ceiling_light.visible = true
			self.vertical_connection_left.disabled = true
			self.vertical_connection_right.disabled = true
			self.ladder_down.disabled = true
			self.ladder_up.disabled = true
	else:
		# Handle vertical corridor direction
		self.ceiling_light.visible = false
		self.ceiling_light_sound.volume_db = -100 # Turn off sound
		self.connection_left.disabled = true
		self.connection_right.disabled = true
		
		self.vertical_connection_left.disabled = direction & Module.ModuleDirection.L != 0
		self.vertical_connection_right.disabled = direction & Module.ModuleDirection.R != 0
		self.connection_ceiling.disabled = vertical_direction & Module.ModuleVerticalDirection.U != 0
		self.connection_floor.disabled = vertical_direction & Module.ModuleVerticalDirection.D != 0
		
		self.vertical_ceiling_left.disabled = vertical_direction & Module.ModuleVerticalDirection.U == 0
		self.vertical_ceiling_right.disabled = self.vertical_ceiling_left.disabled
		
		self.vertical_floor_left.disabled = vertical_direction & Module.ModuleVerticalDirection.D == 0
		self.vertical_floor_right.disabled = self.vertical_floor_left.disabled
	
		self.ladder_down.disabled = vertical_direction & Module.ModuleVerticalDirection.D == 0
		self.ladder_up.disabled = vertical_direction & Module.ModuleVerticalDirection.U == 0
	
	# Set Light occulsions
	self.connection_left.visible = not self.connection_left.disabled
	self.connection_right.visible = not self.connection_right.disabled
	
	if self.type == Module.ModuleType.CORRIDOR:
		self.vertical_connection_left.visible = not self.vertical_connection_left.disabled
		self.vertical_connection_right.visible = not self.vertical_connection_right.disabled
	
		self.connection_ceiling.visible = self.vertical_direction & Module.ModuleVerticalDirection.U == 0
		self.connection_floor.visible = self.vertical_direction & Module.ModuleVerticalDirection.D == 0
		
		self.vertical_ceiling_left.visible = self.vertical_direction & Module.ModuleVerticalDirection.U != 0
		self.vertical_ceiling_right.visible = self.vertical_direction & Module.ModuleVerticalDirection.U != 0
		
		self.vertical_floor_left.visible = self.vertical_direction & Module.ModuleVerticalDirection.D != 0
		self.vertical_floor_right.visible = self.vertical_direction & Module.ModuleVerticalDirection.D != 0
		
