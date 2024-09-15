extends Node2D
class_name MainScene

signal finished_ready

@export var monster: Monster = null
@onready var modules := $Modules as NavigationRegion2D
@onready var player = $Player

var play_tutorial: bool = true

enum TutorialStep {
	SELECT_WEAPON,
	RELOAD,
	UNHAND,
	PAUSE,
	FINISHED
}

var tutorial_msg = {
	TutorialStep.SELECT_WEAPON: "Press 2 to select weapon",
	TutorialStep.RELOAD: "Press R to reload weapon",
	TutorialStep.UNHAND: "Press 1 to deselect weapon",
	TutorialStep.PAUSE: "Press p to pause the game",
	TutorialStep.FINISHED: "",
}

var current_tutorial_step: TutorialStep = TutorialStep.FINISHED

func _ready() -> void:
	# Fot tutorial select
	get_tree().paused = true
	
	# Load modules from Module Builder (safed in Globals)
	for builder_module in Globals.builder_modules:
		modules.add_child(builder_module)
		
	# Spawn player at spawn point
	var spawn_point = get_tree().get_first_node_in_group("spawn_point") as Node2D
	if spawn_point != null:
		player.global_position = spawn_point.global_position
		#monster.global_position = spawn_point.global_position
		
	# Calculate boundries of bunker to bake navigation polygons
	var bounds := getBunkerBounds();
	modules.navigation_polygon.add_outline(PackedVector2Array([
		bounds.position,
		Vector2(bounds.position.x + bounds.size.x, bounds.position.y),
		bounds.position + bounds.size,
		Vector2(bounds.position.x, bounds.position.y + bounds.size.y)
	]))
	modules.bake_navigation_polygon()
	
	finished_ready.emit()

func getBunkerBounds() -> Rect2:
	var boundries := _getAllModuleBoundingBoxes()
	var from := Vector2(1e9, 1e9)
	var to := Vector2(-1e9, -1e9)
	for boundry in boundries:
		if from.x > boundry.position.x:
			from.x = boundry.position.x
		if to.x < boundry.position.x + boundry.size.x:
			to.x = boundry.position.x + boundry.size.x
		if from.y > boundry.position.y:
			from.y = boundry.position.y
		if to.y < boundry.position.y + boundry.size.y:
			to.y = boundry.position.y + boundry.size.y
	return Rect2(from, to - from);

func _process(delta: float) -> void:
	if current_tutorial_step == TutorialStep.SELECT_WEAPON:
		if Input.is_action_just_pressed("equip gun"):
			change_tutorialstep(TutorialStep.RELOAD)
	elif current_tutorial_step == TutorialStep.RELOAD:
		if Input.is_action_just_pressed("reload"):
			change_tutorialstep(TutorialStep.UNHAND)
	elif current_tutorial_step == TutorialStep.UNHAND:
		if Input.is_action_just_pressed("equip hands"):
			change_tutorialstep(TutorialStep.PAUSE)
	elif current_tutorial_step == TutorialStep.PAUSE:
		if Input.is_action_just_pressed("pause_game"):
			change_tutorialstep(TutorialStep.FINISHED)

func change_tutorialstep(next_step: TutorialStep):
	$GUI/Tutorial/Label.text = ""
	current_tutorial_step = TutorialStep.FINISHED
	
	await get_tree().create_timer(2.0).timeout
	current_tutorial_step = next_step
	$GUI/Tutorial/Label.text = tutorial_msg[current_tutorial_step]
	
	if current_tutorial_step == TutorialStep.FINISHED:
		$GUI/Tutorial/Label.visible = false
		$Storm._stopp_time = false


# Founds boundry of each module
func _getAllModuleBoundingBoxes() -> Array[Rect2]:
	var boundsArr: Array[Rect2] = []
	for child in modules.get_children():
		var module := child as Module
		var moduleSize: Vector2 = Module.scales[module.type]
		var width: float = moduleSize.x * Module.GRID_SIZE
		var height: float = moduleSize.y * Module.GRID_SIZE
		var boundry := Rect2(module.global_position.x - Module.GRID_SIZE * 0.5, module.global_position.y + Module.GRID_SIZE * 0.5 - height, width, height)
		boundsArr.append(boundry)
	return boundsArr

func _on_play_raw_pressed() -> void:
	play_tutorial = false
	transition_to_game()

func _on_play_tutorial_pressed() -> void:
	play_tutorial = true
	
	change_tutorialstep(TutorialStep.SELECT_WEAPON)
	$Storm._stopp_time = true
	
	transition_to_game()

func transition_to_game():
	$GUI/Menus/TutorialSkip/PlayTutorial.visible = false
	$GUI/Menus/TutorialSkip/PlayRaw.visible = false
	$GUI/Menus/TutorialSkip/Label.visible = false
	get_tree().paused = false
	
	var fade_color = Color.WHITE
	fade_color.a = 0
	
	var tutorial_menu := $GUI/Menus/TutorialSkip
	
	var tween = get_tree().create_tween()
	tween.tween_property(tutorial_menu, "modulate", fade_color, 0.5).set_trans(Tween.TransitionType.TRANS_LINEAR)
	
	await get_tree().create_timer(0.5).timeout
	tutorial_menu.visible = false
