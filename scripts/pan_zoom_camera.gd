extends Camera2D

class_name PanZoomCamera

const PLAYER_ZOOM: int = 5;
@export var min_zoom := 0.1
@export var max_zoom := 5.0
@export var zoom_factor := 0.1
@export var zoom_duration := 0.2
@export var mainScene: MainScene = null;
var zoom_level: float = 1
var position_before_drag
var position_before_drag2

var is_active := true

@export var randomStrength: float = 30.0
@export var shakeFade: float = 5.0
var rng = RandomNumberGenerator.new()
var shake_strength: float = 0.0

func setActive(state: bool) -> void:
	is_active = state
	
func apply_shake() -> void:
	shake_strength = randomStrength

func _ready():
	pass
	#GlobalEvents.center_camera.connect(center_on_tables)

func _process(delta: float) -> void:
	if shake_strength > 0:
		shake_strength = lerpf(shake_strength, 0, shakeFade * delta)
		self.offset = _randomOffset()
		
func _randomOffset() -> Vector2:
	return Vector2(
		rng.randf_range(-shake_strength, shake_strength),
		rng.randf_range(-shake_strength, shake_strength)
	)

func set_zoom_level(level: float, mouse_world_position = self.get_global_mouse_position()):
	var old_zoom_level = zoom_level
	
	zoom_level = clampf(level, min_zoom, max_zoom)
	
	var direction = (mouse_world_position - self.global_position)
	var new_position = self.global_position + direction - ((direction) / (zoom_level/old_zoom_level))
	
	self.zoom = Vector2(zoom_level, zoom_level)
	self.global_position = new_position
	
func center_on_bunker() -> void:
	var boundry: Rect2 = mainScene.getBunkerBounds();
	var max_x = boundry.position.x + boundry.size.x + Module.GRID_SIZE;
	var min_x = boundry.position.x - Module.GRID_SIZE;
	var max_y = boundry.position.y + boundry.size.y + Module.GRID_SIZE;
	var min_y = boundry.position.y - Module.GRID_SIZE;
	
	var center = Vector2((max_x - min_x) / 2 + min_x, (max_y - min_y) / 2 + min_y)
	global_position = center
	
	# Find out the zoom
	var screen_width = get_viewport().get_visible_rect().size.x
	var project_width = max_x - min_x + 300

	#if project_width > screen_width:
	var new_zoom_level = screen_width / project_width
	set_zoom_level(new_zoom_level, global_position)
		
func center_on_player() -> void:
	position = Vector2(0,0);
	set_zoom_level(5, global_position);
