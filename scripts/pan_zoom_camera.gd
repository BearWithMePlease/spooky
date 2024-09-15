extends Camera2D

class_name PanZoomCamera

@export var min_zoom := 0.1
@export var max_zoom := 5.0
@export var zoom_factor := 0.1
@export var zoom_duration := 0.2
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
	
