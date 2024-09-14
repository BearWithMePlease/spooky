extends Node

@export_category("Ceiling Light Sound")
@export var sound_light_on: AudioStreamMP3
@export var sound_light_off: AudioStreamMP3
@export var sound_light_volume: float = -15.0

@export_category("Foot Steps")
@export var sound_foot_steps: Array[AudioStreamMP3]
@export var sound_foot_volume: float = -10

@onready var foot_steps: AudioStreamPlayer = $Foot_Steps

var sound_effects: Array
var is_playing_footsteps: bool = false
var delay_between_steps: float

func on_main_finished_ready():
	self.sound_effects = get_tree().get_nodes_in_group("sound_effects")

	# Start all sound effects
	for audio_player:AudioStreamPlayer2D in sound_effects:
		audio_player.play()
	
	foot_steps.volume_db = sound_foot_volume

func play_light_flicker(light_source: PointLight2D, to_enabled: bool, pitch_scale: float = 1.0):
	var sound_player: AudioStreamPlayer2D = light_source.get_children().filter(func(node:Node): return node.is_in_group("sound_ceiling_light"))[0]
	
	sound_player.stream = sound_light_on if to_enabled else sound_light_off
	sound_player.pitch_scale = pitch_scale
	sound_player.volume_db = sound_light_volume
	sound_player.play()

# Call when player is running: play_footsteps(true, .1)
func play_footsteps(enabled: bool, delay_between_steps: float):
	self.delay_between_steps = delay_between_steps
	
	if enabled:
		if self.is_playing_footsteps == false:
			_footstep_loop(sound_foot_steps.pick_random())
	else:
		foot_steps.stop()
	
	self.is_playing_footsteps = enabled
	
func _footstep_loop(audiostream: AudioStreamMP3):
	foot_steps.stream = audiostream
	foot_steps.pitch_scale = randf_range(0.7, 0.8)
	foot_steps.play()
	
	await get_tree().create_timer(delay_between_steps + audiostream.get_length()).timeout
	_footstep_loop(sound_foot_steps.pick_random())
