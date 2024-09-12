extends Node

enum SceneType {
	BUNKER_BUILD,
	MAIN_SCENE
}

var packed_scenes := {
	SceneType.BUNKER_BUILD: preload("res://scenes/bunker_builder.tscn"),
	SceneType.MAIN_SCENE: preload("res://scenes/main_scene.tscn")
}

var module_prefabs = {
	Modules.ModuleType.COMMUNICATION: preload("res://prefab/modules/communication.tscn"),
	Modules.ModuleType.CORRIDOR: preload("res://prefab/modules/corridor.tscn"),
	Modules.ModuleType.ENTRY: preload("res://prefab/modules/entry.tscn"),
	Modules.ModuleType.GENERATOR: preload("res://prefab/modules/generator.tscn"),
	Modules.ModuleType.WATER: preload("res://prefab/modules/water.tscn"),
	Modules.ModuleType.WEAPONS: preload("res://prefab/modules/weapons.tscn"),
}

var builder_modules: Array[Module] = []

func switch_scene(from_scene: SceneType, to_scene: SceneType, addidtional = null):
	if from_scene == SceneType.BUNKER_BUILD and to_scene == SceneType.MAIN_SCENE:
		# Add modules to scene
		for old_module:Module in addidtional:
			var module = module_prefabs[old_module.type].instantiate() as Module
			module.init(old_module.position, old_module.type, old_module.direction, old_module.vertical_direction)
			builder_modules.append(module)
	
	get_tree().change_scene_to_packed(packed_scenes[to_scene])
