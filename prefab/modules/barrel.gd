extends Area2D
class_name Barrel;

const LIGHT_FALL_TIME = 0.5;
@export var newBarrel: Texture2D = null;
@export var explodedBarrel: Texture2D = null;
@onready var sprite: Sprite2D = $Sprite;
@onready var particles: CPUParticles2D = $CPUParticles2D;
@onready var light: PointLight2D = $PointLight2D;
var _lightTimer: float = 0.0;
var _isExploded := false;

func explodeBarrel() -> void:
	if _isExploded:
		return;
	sprite.texture = explodedBarrel;
	particles.emitting = true;
	_lightTimer = LIGHT_FALL_TIME;
	_isExploded = true;
	
func isExploded() -> bool:
	return _isExploded;
	
func _process(delta: float) -> void:
	_lightTimer = max(0.0, _lightTimer - delta);
	const MAX_LIGHT := 12.5;
	var procent := _lightTimer / LIGHT_FALL_TIME;
	light.energy = MAX_LIGHT * (procent * procent) # quadratisch
