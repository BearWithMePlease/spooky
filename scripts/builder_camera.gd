extends Camera2D

@export var min_zoom := 0.5
@export var max_zoom := 1.5
@export var zoom_factor := 0.1

var zoom_level: float = 1.0
var position_before_drag
var position_before_drag2

func _unhandled_input(event):
	if event.is_action_pressed("zoom_in"):
		set_zoom_level(zoom_level + zoom_factor)
	elif event.is_action_pressed("zoom_out"):
		set_zoom_level(zoom_level - zoom_factor)
	elif event.is_action_pressed("drag"):
		position_before_drag = event.global_position
		position_before_drag2 = self.global_position
	elif event.is_action_released("drag"):
		position_before_drag = null
	elif event is InputEventPanGesture:
		self.global_position += event.delta * 20
	elif event is InputEventScreenDrag:
		self.global_position -= event.relative
	elif event is InputEventMagnifyGesture:
		if event.factor > 1:
			set_zoom_level(zoom_level + (zoom_factor * 0.5))
		elif event.factor < 1:
			set_zoom_level(zoom_level - (zoom_factor * 0.5))
	
	if position_before_drag and event is InputEventMouseMotion:
		self.global_position = position_before_drag2 + (position_before_drag - event.global_position) * (1/zoom_level)


func set_zoom_level(level: float, mouse_world_position = self.get_global_mouse_position()):
	var old_zoom_level = zoom_level
	
	zoom_level = clampf(level, min_zoom, max_zoom)
	
	var direction = (mouse_world_position - self.global_position)
	var new_position = self.global_position + direction - (direction / (zoom_level / old_zoom_level))
	
	self.zoom = Vector2(zoom_level, zoom_level)
	self.global_position = new_position
