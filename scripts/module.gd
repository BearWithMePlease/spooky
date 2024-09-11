extends Node2D
class_name Module

var type: Modules.ModuleType
var direction: Modules.ModuleDirection
var vertical_direction: Modules.ModuleVerticalDirection

var sprite: Sprite2D
var connection_left: CollisionPolygon2D
var connection_right: CollisionPolygon2D

# Only used if type is corridor
var ceiling_light: PointLight2D
var connection_ceiling: CollisionPolygon2D
var connection_floor: CollisionPolygon2D
var vertical_connection_left: CollisionPolygon2D
var vertical_connection_right: CollisionPolygon2D
var vertical_ceiling_left: CollisionPolygon2D
var vertical_ceiling_right: CollisionPolygon2D
var vertical_floor_left: CollisionPolygon2D
var vertical_floor_right: CollisionPolygon2D

func _ready() -> void:
	# Useful for debugging:
	# init(Vector2(0,0), Modules.ModuleType.CORRIDOR, Modules.ModuleDirection.H, Modules.ModuleVerticalDirection.U)
	pass

func init(module_position:Vector2, type:Modules.ModuleType, direction: Modules.ModuleDirection, vertical_direction: Modules.ModuleVerticalDirection = Modules.ModuleVerticalDirection.N):
	self.position = module_position
	self.type = type
	self.direction = direction
	self.vertical_direction = vertical_direction
	
	fetch_nodes()
	set_direction(direction, vertical_direction)
	
	self.z_index = 0
	self.visible = true
	sprite.modulate = Color.WHITE

	var scales = Modules.scales[self.type]
	sprite.position.x = -Modules.GRID_SIZE / 2.0
	sprite.position.y = -(max(0, scales.y - 1.0) * Modules.GRID_SIZE + Modules.GRID_SIZE / 2.0)

func fetch_nodes():
	self.sprite = get_node_or_null(^"Sprite")
	self.connection_left = get_node_or_null(^"Sprite/Borders/Connection_Left")
	self.connection_right = get_node_or_null(^"Sprite/Borders/Connection_Right")
	
	if self.sprite == null || self.connection_left == null || self.connection_right == null:
		push_error("Failed to fetch some Essential nodes")
	
	# Only used if type is corridor
	if self.type == Modules.ModuleType.CORRIDOR:
		self.ceiling_light = get_node_or_null(^"Sprite/Lights/Ceiling_Light")
		self.connection_ceiling = get_node_or_null(^"Sprite/Borders/Ceiling")
		self.connection_floor = get_node_or_null(^"Sprite/Borders/Floor")
		self.vertical_connection_left = get_node_or_null(^"Sprite/Borders/Vertical_Connection_Left")
		self.vertical_connection_right = get_node_or_null(^"Sprite/Borders/Vertical_Connection_Right")
		self.vertical_ceiling_left = get_node_or_null(^"Sprite/Borders/Vertical_Ceiling_Left")
		self.vertical_ceiling_right = get_node_or_null(^"Sprite/Borders/Vertical_Ceiling_Right")
		self.vertical_floor_left = get_node_or_null(^"Sprite/Borders/Vertical_Floor_Left")
		self.vertical_floor_right = get_node_or_null(^"Sprite/Borders/Vertical_Floor_Right")
		
		var failed = self.ceiling_light == null || self.connection_ceiling == null || self.connection_floor == null
		failed = failed || self.vertical_connection_left == null || self.vertical_connection_right == null
		failed = failed || self.vertical_ceiling_left == null || self.vertical_ceiling_right == null
		failed = failed || self.vertical_floor_left == null || self.vertical_floor_right == null
		
		if failed:
			push_error("Failed to fetch some Corridor nodes")

func set_direction(direction: Modules.ModuleDirection, vertical_direction: Modules.ModuleVerticalDirection = Modules.ModuleVerticalDirection.N):
	self.direction = direction
	self.vertical_direction = vertical_direction
	
	var path = Modules.get_module_path(self.type, self.direction, self.vertical_direction)
	self.sprite.texture = load(path)
	handle_doors()

func adjust_direction(direction: Modules.ModuleDirection, vertical_direction: Modules.ModuleVerticalDirection, removing: bool):
	if removing: set_direction(self.direction & (~direction), self.vertical_direction & (~vertical_direction))	# Remove
	else: set_direction(self.direction | direction, self.vertical_direction | vertical_direction) 				# Add

func handle_doors():
	if self.type != Modules.ModuleType.CORRIDOR || self.vertical_direction == Modules.ModuleVerticalDirection.N:
		# Handle every module type except when a corridor has a vertical direction
		if self.connection_left == null || self.connection_right == null:
			push_error("Failed to handle essential door borders")
		else:
			self.connection_left.disabled = direction & Modules.ModuleDirection.L != 0
			self.connection_right.disabled = direction & Modules.ModuleDirection.R != 0
			
			if self.type == Modules.ModuleType.CORRIDOR:
				if  self.ceiling_light == null ||  self.vertical_connection_left == null ||  self.vertical_connection_right == null:
					push_error("Failed to handle vertical corridor door borders")
				else:
					self.ceiling_light.visible = true
					self.vertical_connection_left.disabled = true
					self.vertical_connection_right.disabled = true
	else:
		# Handle vertical corridor direction
		var failed =  self.ceiling_light == null ||  self.connection_left == null ||  self.connection_right == null
		failed = failed ||  self.vertical_connection_left == null ||  self.vertical_connection_right == null
		failed = failed || self.connection_ceiling == null ||  self.connection_floor == null
		failed = failed || self.vertical_ceiling_left == null || self.vertical_ceiling_right == null
		failed = failed || self.vertical_floor_left == null || self.vertical_floor_right == null
		if failed:
			push_error("Failed to handle vertical corridor door borders")
		else:
			self.ceiling_light.visible = false
			self.connection_left.disabled = true
			self.connection_right.disabled = true
			
			self.vertical_connection_left.disabled = direction & Modules.ModuleDirection.L != 0
			self.vertical_connection_right.disabled = direction & Modules.ModuleDirection.R != 0
			self.connection_ceiling.disabled = vertical_direction & Modules.ModuleVerticalDirection.U != 0
			self.connection_floor.disabled = vertical_direction & Modules.ModuleVerticalDirection.D != 0
			
			self.vertical_ceiling_left.disabled = vertical_direction & Modules.ModuleVerticalDirection.U == 0
			self.vertical_ceiling_right.disabled = self.vertical_ceiling_left.disabled
			
			self.vertical_floor_left.disabled = vertical_direction & Modules.ModuleVerticalDirection.D == 0
			self.vertical_floor_right.disabled = self.vertical_floor_left.disabled
