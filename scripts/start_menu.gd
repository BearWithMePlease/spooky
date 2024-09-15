extends Node2D

@onready var fake_player := $FakePlayer
@onready var spawn_point := $Animation_Positions/SpawnPoint
@onready var light_control := $Light_Control

var current_movement: FakeMovement
var speed = 100

enum FakeMovement {
	LADDER_UP,
	WALKING_RIGHT,
	LADDER_DOWN
}

func _ready() -> void:
	fake_player.global_position = spawn_point.global_position
	current_movement = FakeMovement.LADDER_UP
	$FakePlayer/Audio_Control.play_footsteps(true, 0.1)
	
	light_control.on_main_finished_ready()
	random_light_flicker()

func _process(delta: float) -> void:
	if current_movement == FakeMovement.WALKING_RIGHT:
		fake_player.position += Vector2(speed * delta, 0)
		fake_player.play("walking")
	elif current_movement == FakeMovement.LADDER_DOWN:
		fake_player.position += Vector2(0, speed * delta)
		fake_player.play("climbing")
	elif current_movement == FakeMovement.LADDER_UP:
		fake_player.position += Vector2(0, -speed * delta)
		fake_player.play("climbing")

func random_light_flicker():
	await get_tree().create_timer(randf_range(5, 10)).timeout
	light_control.on_near_monster(null, light_control.MonsterCloseness.CLOSE, false)
	await get_tree().create_timer(randf_range(1, 2)).timeout
	light_control.on_near_monster(null, light_control.MonsterCloseness.DISTANT, false)
	await get_tree().create_timer(randf_range(5, 10)).timeout
	random_light_flicker()

func left_area_entered(_area: Area2D):
	current_movement = FakeMovement.WALKING_RIGHT

func right_area_entered(_area: Area2D):
	current_movement = FakeMovement.LADDER_DOWN

func despawn(_area: Area2D):
	fake_player.global_position = spawn_point.global_position
	current_movement = FakeMovement.LADDER_UP


func _on_play_game_pressed() -> void:
	Globals.switch_scene(Globals.SceneType.START_MENU, Globals.SceneType.BUNKER_BUILD)
