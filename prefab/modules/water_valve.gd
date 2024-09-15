extends Area2D

class_name WaterValve

const WATER_RAISE_TIME := 2.0;
const WATER_UP_Y := 31.0;
const WATER_DOWN_Y := 33.0;
@onready var _waterSprite: Sprite2D = $WaterLayer;
@onready var _particles: CPUParticles2D = $CPUParticles2D;
var _waterIsRaisen := false;
var _waterRaiseTimer := 0.0;

func _ready() -> void:
	_particles.emitting = false;

func raiseUpWater() -> void:
	if _waterIsRaisen:
		return;
	_waterIsRaisen = true;
	_particles.emitting = true;

func _process(delta: float) -> void:
	if _waterIsRaisen:
		_waterRaiseTimer = min(WATER_RAISE_TIME, _waterRaiseTimer + delta);
		var procent = _waterRaiseTimer / WATER_RAISE_TIME;
		_waterSprite.position.y = lerp(WATER_DOWN_Y, WATER_UP_Y, procent);
