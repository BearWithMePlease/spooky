extends Node
class_name AudioControl

@onready var light_control := $"../Light_Control"

@export_category("Ceiling Light Sound")
@export var sound_light_on: AudioStreamMP3
@export var sound_light_off: AudioStreamMP3
@export var sound_light_volume: float = -15.0

@export_category("Foot Steps")
@export var sound_foot_steps: Array[AudioStreamMP3]
@export var sound_foot_volume: float = -10
@onready var foot_steps := $Foot_Steps

@export_category("Random Sounds")
@export var sound_random: Array[AudioStreamMP3]
@export var sound_random_volume: float = 5
@export var sound_random_very_close: Array[AudioStreamMP3]
@export var sound_random_very_close_volume: float = -10
@export var will_play_random_sounds:bool = true
@onready var random_sounds: AudioStreamPlayer = $Random_Sounds

@export_category("Gun Shot")
@export var sound_gun_shot_volume: float = -20
var is_shooting:bool = false
var shooting_id: int = 0
@onready var gun_shot_sounds: AudioStreamPlayer = $Gun_Shot

var sound_effects: Array
var is_playing_footsteps: bool = false
var delay_between_steps: float
var is_playing_random_sounds: bool = false

func on_main_finished_ready():
	self.sound_effects = get_tree().get_nodes_in_group("sound_effects")

	# Start all sound effects
	for audio_player:AudioStreamPlayer2D in sound_effects:
		audio_player.play()
	
	foot_steps.volume_db = sound_foot_volume
	random_sounds.volume_db = sound_random_volume
	gun_shot_sounds.volume_db = sound_gun_shot_volume
	
	if will_play_random_sounds:
		play_random_sounds(true)


func play_light_flicker(light_source: PointLight2D, to_enabled: bool, pitch_scale: float = 1.0):
	var sound_player: AudioStreamPlayer2D = light_source.get_children().filter(func(node:Node): return node.is_in_group("sound_ceiling_light"))[0]
	
	sound_player.stream = sound_light_on if to_enabled else sound_light_off
	sound_player.pitch_scale = pitch_scale
	sound_player.volume_db = sound_light_volume
	sound_player.play()

# Call when player is running: play_footsteps(true, .1)
func play_footsteps(enabled: bool, delay_between_steps: float):
	self.delay_between_steps = delay_between_steps
	
	if enabled == self.is_playing_footsteps:
		return
	
	self.is_playing_footsteps = enabled
	if self.is_playing_footsteps:
		_footstep_loop(sound_foot_steps.pick_random())
	
func _footstep_loop(audiostream: AudioStreamMP3):
	if not self.is_playing_footsteps:
		return
	
	if not self.get_tree().paused:
		foot_steps.stream = audiostream
		foot_steps.pitch_scale = randf_range(0.7, 0.8)
		foot_steps.play()
	
	await get_tree().create_timer(delay_between_steps + audiostream.get_length()).timeout
	_footstep_loop(sound_foot_steps.pick_random())

# Call when player is running: play_footsteps(true, .1)
func play_random_sounds(enabled: bool):
	if enabled == self.is_playing_random_sounds:
		return
	
	self.is_playing_random_sounds = enabled
	if self.is_playing_random_sounds:
		await get_tree().create_timer(randf_range(10.0, 20.0)).timeout
		_play_random_sound(sound_random.pick_random())

# Call when player is running: play_footsteps(true, .1)
func _play_random_sound(audiostream: AudioStreamMP3):
	if not self.is_playing_random_sounds:
		return

	var delay_random = randf_range(20.0, 40.0) # Play next sound in 20 to 40 seconds
	
	if light_control.closeness == light_control.MonsterCloseness.VERY_CLOSE:
		audiostream = sound_random_very_close.pick_random()
		random_sounds.volume_db = sound_random_very_close_volume
		delay_random = randf_range(5.0, 15.0)
	else:
		random_sounds.volume_db = sound_random_volume
	
	if not self.get_tree().paused:
		random_sounds.stream = audiostream
		random_sounds.pitch_scale = randf_range(0.7, 0.8)
		random_sounds.play()
	
	await get_tree().create_timer(delay_random + audiostream.get_length()).timeout
	
	_play_random_sound(sound_random.pick_random())

func play_shooting_sound(enabled:bool):
	if self.is_shooting == enabled:
		return
	self.is_shooting = enabled
	self.shooting_id += 1
	
	if enabled:
		_play_shoot_sound(self.shooting_id)
	else:
		gun_shot_sounds.stop()

func _play_shoot_sound(id: int):
	if self.shooting_id != id:
		return
	
	if not self.get_tree().paused:
		gun_shot_sounds.play()
	
	await get_tree().create_timer(gun_shot_sounds.stream.get_length()).timeout
	_play_shoot_sound(id)


func _on_volume_slider_value_changed(value: float) -> void:
	var id = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(id, linear_to_db(value))
