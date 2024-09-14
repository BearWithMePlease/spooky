extends Node2D

@onready var audio_control := $"../Audio_Control"

@onready var global_light: DirectionalLight2D = $Global_Light
var ceiling_lamps: Array
var electric_light: Array

var default_ceiling_lamp_color: Color

var ceiling_lamp_flicker = false

func on_main_finished_ready():
	ceiling_lamps = get_tree().get_nodes_in_group("ceiling_lamp")
	electric_light = get_tree().get_nodes_in_group("electric_light")
	
	if len(ceiling_lamps) > 0:
		default_ceiling_lamp_color = ceiling_lamps[0].color
	
	set_ceiling_lamp_flicker(true, Color.RED)

func set_ceiling_lamp_flicker(enabled:bool, color: Color = default_ceiling_lamp_color):
	ceiling_lamp_flicker = enabled
	if ceiling_lamp_flicker:
		for lamp:PointLight2D in ceiling_lamps:
			var sound_pitch = randf_range(0.7, 1.2)
			_ceiling_lamp_flicker_animation(lamp, color, sound_pitch)
		

func _ceiling_lamp_flicker_animation(ceiling_lamp:PointLight2D, color:Color, sound_pitch: float):
	if not self.ceiling_lamp_flicker:
		return
	
	ceiling_lamp.color = Color.BLACK
	audio_control.play_light_flicker(ceiling_lamp, false, sound_pitch)
	
	var black_out_duration = randf_range(0.1, 0.5)
	await get_tree().create_timer(black_out_duration).timeout
	
	ceiling_lamp.color = color
	audio_control.play_light_flicker(ceiling_lamp, true, sound_pitch)
	
	var new_flicker_delay = randf_range(0.1, 0.5)
	await get_tree().create_timer(new_flicker_delay).timeout
	_ceiling_lamp_flicker_animation(ceiling_lamp, color, sound_pitch)
	
