extends Node2D

@onready var audio_control := $"../Audio_Control"

@onready var global_light: DirectionalLight2D = $Global_Light
var ceiling_lamps: Array
var electric_light: Array

var default_ceiling_lamp_color: Color
var flicker_id = 0
var closeness: MonsterCloseness = MonsterCloseness.DISTANT
var close_to_monster: Area2D
var very_close_to_monster: Area2D
var fix_on_ready_area_bug: bool = false
@export var very_close_to_monster_color: Color = Color.RED

enum MonsterCloseness {
	DISTANT,
	CLOSE,
	VERY_CLOSE
}


func on_main_finished_ready():
	ceiling_lamps = get_tree().get_nodes_in_group("ceiling_lamp")
	electric_light = get_tree().get_nodes_in_group("electric_light")
	
	if len(ceiling_lamps) > 0:
		default_ceiling_lamp_color = ceiling_lamps[0].color
	
	close_to_monster = get_tree().get_first_node_in_group("close_to_monster_area") as Area2D
	close_to_monster.area_entered.connect(on_near_monster.bind().bind(MonsterCloseness.CLOSE, false))
	close_to_monster.area_exited.connect(on_near_monster.bind().bind(MonsterCloseness.DISTANT, false))

	very_close_to_monster = get_tree().get_first_node_in_group("very_close_to_monster_area") as Area2D
	very_close_to_monster.area_entered.connect(on_near_monster.bind().bind(MonsterCloseness.VERY_CLOSE, true))
	very_close_to_monster.area_exited.connect(on_near_monster.bind().bind(MonsterCloseness.CLOSE, true))
	
	#
	randomly_switch_closeness()

func randomly_switch_closeness():
	var delay = randf_range(60, 120)
	await get_tree().create_timer(delay).timeout
	
	if self.closeness == MonsterCloseness.DISTANT:
		if randi_range(0,1) == 0: on_near_monster(null, MonsterCloseness.CLOSE, false)
		else: on_near_monster(null, MonsterCloseness.VERY_CLOSE, false)
		
		var id = self.flicker_id
		await get_tree().create_timer(randf_range(2, 3)).timeout
		if self.flicker_id == id:
			on_near_monster(null, MonsterCloseness.DISTANT, false)
	randomly_switch_closeness()

func on_near_monster(area: Area2D, closeness: MonsterCloseness, from_very_close: bool):
	if (area != null and not area.is_in_group("player_collision")) or closeness == self.closeness:
		return
	
	if closeness == MonsterCloseness.DISTANT:
		set_ceiling_lamp_flicker(false, default_ceiling_lamp_color)
	elif closeness == MonsterCloseness.CLOSE:
		if not fix_on_ready_area_bug and self.closeness == MonsterCloseness.VERY_CLOSE and not from_very_close:
			# Only on startup. Disable that close_to_monster_area can switch from very_close to close
			self.fix_on_ready_area_bug = true
			return 
		set_ceiling_lamp_flicker(true, default_ceiling_lamp_color)
	elif closeness == MonsterCloseness.VERY_CLOSE:
		set_ceiling_lamp_flicker(false, very_close_to_monster_color)
	
	self.closeness = closeness

func set_ceiling_lamp_flicker(enabled:bool, color: Color = default_ceiling_lamp_color):
	flicker_id += 1
	for lamp:PointLight2D in ceiling_lamps:
		lamp.color = color
		if enabled:
			var sound_pitch = randf_range(0.7, 1.2)
			var delay = randf_range(0, 1.5)
			_ceiling_lamp_flicker_animation(flicker_id, lamp, color, sound_pitch, delay)


func _ceiling_lamp_flicker_animation(id:int, ceiling_lamp:PointLight2D, color:Color, sound_pitch: float, delay: float = 0):
	if delay != 0:
		await get_tree().create_timer(delay).timeout
		if self.flicker_id != id: return
	
	ceiling_lamp.color = Color.BLACK
	audio_control.play_light_flicker(ceiling_lamp, false, sound_pitch)
	
	var black_out_duration = randf_range(0.1, 0.5)
	await get_tree().create_timer(black_out_duration).timeout
	if self.flicker_id != id: return
	
	ceiling_lamp.color = color
	audio_control.play_light_flicker(ceiling_lamp, true, sound_pitch)
	
	var new_flicker_delay = randf_range(0.5, 1.5)
	await get_tree().create_timer(new_flicker_delay).timeout
	if self.flicker_id != id: return
	
	_ceiling_lamp_flicker_animation(id, ceiling_lamp, color, sound_pitch)
	
