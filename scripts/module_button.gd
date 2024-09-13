extends Button
class_name ModuleButton

@export var module_type: Modules.ModuleType = Modules.ModuleType.NONE

var _placeable_count: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if module_type == Modules.ModuleType.NONE:
		push_error("Module type is NONE")
		return
		
	var path = Modules.get_icon_path(module_type)
	$"Module_Img".texture = load(path)
	
	set_placeable_count(Modules.max_module_count[self.module_type])
	
	var callable = Callable($"..".on_module_type_select).bind(module_type)
	self.pressed.connect(callable)
	

func set_placeable_count(new_count: int):
	self._placeable_count = clampi(new_count, 0, Modules.max_module_count[self.module_type])
	$Count.text = str(self._placeable_count)
	
	self.disabled = self._placeable_count == 0

func add_to_placeable_count(value: int):
	set_placeable_count(self._placeable_count + value)
