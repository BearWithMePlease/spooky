extends Node

var module_prefabs = {
	Modules.ModuleType.COMMUNICATION: preload("res://prefab/modules/communication.tscn"),
	Modules.ModuleType.CORRIDOR: preload("res://prefab/modules/corridor.tscn"),
	Modules.ModuleType.ENTRY: preload("res://prefab/modules/entry.tscn"),
	Modules.ModuleType.GENERATOR: preload("res://prefab/modules/generator.tscn"),
	Modules.ModuleType.WATER: preload("res://prefab/modules/water.tscn"),
	Modules.ModuleType.WEAPONS: preload("res://prefab/modules/weapons.tscn"),
}
