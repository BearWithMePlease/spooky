extends Node

enum SceneType {
	START_MENU,
	BUNKER_BUILD,
	MAIN_SCENE
}

var packed_scenes := {
	SceneType.START_MENU: preload("res://scenes/start_menu.tscn"),
	SceneType.BUNKER_BUILD: preload("res://scenes/bunker_builder.tscn"),
	SceneType.MAIN_SCENE: preload("res://scenes/main_scene.tscn")
}

var module_prefabs = {
	Module.ModuleType.COMMUNICATION: preload("res://prefab/modules/communication.tscn"),
	Module.ModuleType.CORRIDOR: preload("res://prefab/modules/corridor.tscn"),
	Module.ModuleType.ENTRY: preload("res://prefab/modules/entry.tscn"),
	Module.ModuleType.GENERATOR: preload("res://prefab/modules/generator.tscn"),
	Module.ModuleType.WATER: preload("res://prefab/modules/water.tscn"),
	Module.ModuleType.WEAPONS: preload("res://prefab/modules/weapons.tscn"),
	Module.ModuleType.BEDROOM: preload("res://prefab/modules/bedroom.tscn"),
	Module.ModuleType.HOSPITAL: preload("res://prefab/modules/hospital.tscn"),
}

var builder_modules: Array[Module] = []
var custom_cross := load("res://imgs/cross.png")
var custom_cursor := load("res://imgs/cursor.png")

func switch_scene(from_scene: SceneType, to_scene: SceneType, addidtional = null):
	Input.set_custom_mouse_cursor(null, Input.CURSOR_CROSS)
	Input.set_custom_mouse_cursor(null, Input.CURSOR_ARROW)
	
	if from_scene == SceneType.BUNKER_BUILD and to_scene == SceneType.MAIN_SCENE:
		# Add modules to scene
		builder_modules = [] # TODO: Need to .free() all
		for old_module:Module in addidtional:
			var module = module_prefabs[old_module.type].instantiate() as Module
			module.init(old_module.position, old_module.type, old_module.direction, old_module.vertical_direction)
			builder_modules.append(module)
	
	get_tree().change_scene_to_packed(packed_scenes[to_scene])
	self.get_tree().paused = false
