extends Node2D
class_name Module

@onready var sprite = $Sprite

var type: Modules.ModuleType
var direction: Modules.ModuleDirection
var vertical_direction: Modules.ModuleVerticalDirection

func init(module_position:Vector2, type:Modules.ModuleType, direction: Modules.ModuleDirection, vertical_direction: Modules.ModuleVerticalDirection = Modules.ModuleVerticalDirection.N):
	if $Sprite == null:
		push_error("Sprite not defined")
	
	self.position = module_position
	self.type = type
	self.direction = direction
	self.vertical_direction = vertical_direction
	
	set_direction(direction, vertical_direction)

	self.z_index = 0
	self.visible = true
	$Sprite.modulate = Color.WHITE

	var scales = Modules.scales[self.type]
	$Sprite.position.x = -Modules.GRID_SIZE / 2.0
	$Sprite.position.y = -(max(0, scales.y - 1.0) * Modules.GRID_SIZE + Modules.GRID_SIZE / 2.0)

func set_direction(direction: Modules.ModuleDirection, vertical_direction: Modules.ModuleVerticalDirection = Modules.ModuleVerticalDirection.N):
	self.direction = direction
	self.vertical_direction = vertical_direction
	
	var path = Modules.get_module_path(self.type, self.direction, self.vertical_direction)
	$Sprite.texture = load(path)
	handle_doors()

func adjust_direction(direction: Modules.ModuleDirection, vertical_direction: Modules.ModuleVerticalDirection, removing: bool):
	if removing: set_direction(self.direction & (~direction), self.vertical_direction & (~vertical_direction))	# Remove
	else: set_direction(self.direction | direction, self.vertical_direction | vertical_direction) 				# Add

func handle_doors():
	if get_node_or_null(^"Sprite/Borders/Connection_Left") == null || get_node_or_null(^"Sprite/Borders/Connection_Right") == null:
		return
	
	$Sprite/Borders/Connection_Left.disabled = direction & Modules.ModuleDirection.L != 0
	$Sprite/Borders/Connection_Right.disabled = direction & Modules.ModuleDirection.R != 0
	
	if type == Modules.ModuleType.STAIR:
		$Sprite/Borders/Connection_Up.disabled = vertical_direction & Modules.ModuleVerticalDirection.U == 0
		$Sprite/Borders/Connection_Down.disabled = vertical_direction & Modules.ModuleVerticalDirection.D == 0
