extends Button

@export var module_type: Modules.ModuleType = Modules.ModuleType.NONE

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if module_type == Modules.ModuleType.NONE:
		push_error("Module type is NONE")
		return
		
	var path = Modules.get_icon_path(module_type)
	$"./Module_Img".texture = load(path)
	
	var callable = Callable($"..".on_module_type_select).bind(module_type)
	self.pressed.connect(callable)
	
