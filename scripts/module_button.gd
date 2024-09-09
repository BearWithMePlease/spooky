extends Button

@export var module_type: Modules.ModuleType = Modules.ModuleType.NONE
@export var module_direction: Modules.ModuleDirection = Modules.ModuleDirection.N

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if module_type == Modules.ModuleType.NONE:
		push_error("Module type is NONE")
		return
		
	var path = Modules.get_module_path(module_type, module_direction)
	var texture: CompressedTexture2D = load(path)
	
	$"./Module_Img".texture = texture
	
	var callable = Callable($"..".on_module_type_select).bind(module_type, texture)
	self.pressed.connect(callable)
	
