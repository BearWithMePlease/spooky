extends Sprite2D
class_name Module

var type: Modules.ModuleType
var direction: Modules.ModuleDirection
var vertical_direction: Modules.ModuleVerticalDirection

func init(module_position:Vector2, type:Modules.ModuleType, direction: Modules.ModuleDirection, vertical_direction: Modules.ModuleVerticalDirection = Modules.ModuleVerticalDirection.N):
	self.type = type
	self.vertical_direction = vertical_direction
	set_direction(direction, vertical_direction)
	
	self.position = module_position
	self.z_index = 0
	self.modulate = Color.WHITE
	self.visible = true
	
	# Set Offset - Middle of bottom right slot
	var scales = Modules.scales[self.type]
	offset.x = -Modules.GRID_SIZE / 2.0
	offset.y = -(max(0, scales.y - 1.0) * Modules.GRID_SIZE + Modules.GRID_SIZE / 2.0)

func set_direction(direction: Modules.ModuleDirection, vertical_direction: Modules.ModuleVerticalDirection = Modules.ModuleVerticalDirection.N):
	self.direction = direction
	self.vertical_direction = vertical_direction
	
	var path = Modules.get_module_path(self.type, self.direction, self.vertical_direction)
	self.texture = load(path)

func adjust_direction(direction: Modules.ModuleDirection, vertical_direction: Modules.ModuleVerticalDirection, removing: bool):
	if removing: set_direction(self.direction & (~direction), self.vertical_direction & (~vertical_direction))	# Remove
	else: set_direction(self.direction | direction, self.vertical_direction | vertical_direction) 				# Add
