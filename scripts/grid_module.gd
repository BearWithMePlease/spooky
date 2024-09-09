extends Sprite2D
class_name GridModule

var type: Modules.ModuleType
var direction: Modules.ModuleDirection

func init(position:Vector2, type:Modules.ModuleType, direction: Modules.ModuleDirection):
	self.type = type
	self.position = position
	self.z_index = 0
	self.modulate = Color.WHITE
	self.visible = true
	
	set_direction(direction)

func set_direction(direction: Modules.ModuleDirection):
	self.direction = direction
	
	var path = Modules.get_module_path(self.type, self.direction)
	self.texture = load(path)

func adjust_direction(direction: Modules.ModuleDirection, removing: bool):
	if removing: set_direction(self.direction & (~direction))	# Remove
	else: set_direction(self.direction | direction) 			# Add
