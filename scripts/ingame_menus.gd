extends Control

@onready var pause_menu := $Pause
@onready var victory_menu := $Victory
@onready var defeat_menu := $Defeat


func _ready() -> void:
	pause_menu.visible = self.get_tree().paused
	victory_menu.visible = false
	defeat_menu.visible = false

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause_game"):
		self.get_tree().paused = !self.get_tree().paused
		pause_menu.visible = self.get_tree().paused

func victory():
	self.get_tree().paused = true
	victory_menu.visible = true
	pause_menu.visible = false

func defeat():
	self.get_tree().paused = true
	defeat_menu.visible = true
	pause_menu.visible = false

func _on_resume_button_pressed() -> void:
	self.get_tree().paused = false
	pause_menu.visible = false


func _on_quit_to_menu_button_pressed() -> void:
	Globals.switch_scene(Globals.SceneType.MAIN_SCENE, Globals.SceneType.START_MENU)
