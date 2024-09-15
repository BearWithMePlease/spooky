extends Node2D
class_name Storm

const IRL_SECONDS_TO_INGAME_HOURS := 1.0 / 3.5;
@export var timeDisplay: Label = null;
var _time: DateTime;
var _currentAberration := 0.0;
var _stopp_time: bool = false
const ABERRATION_TRANSITION := 0.5;

class DateTime:
	var irlSeconds: float; # irl seconds
	
	func _init(startTime: float = 0.0) -> void:
		irlSeconds = startTime;
		
	func getInGameHours() -> float:
		return irlSeconds * IRL_SECONDS_TO_INGAME_HOURS;
		
	func getDay() -> int:
		return int(getInGameHours() / 24.0);
		
	func getHours() -> int:
		return int(getInGameHours()) % 24
	
	func getMinutes() -> int:
		var gameHours := getInGameHours();
		return int((gameHours - getHours() - getDay() * 24.0) * 60.0);

func _ready() -> void:
	_time = DateTime.new(36.0 / IRL_SECONDS_TO_INGAME_HOURS);
	
func isStorm() -> bool:
	return _time.getHours() < 12;

func _process(delta: float) -> void:
	if _stopp_time:
		return
	
	_time.irlSeconds += delta;
	timeDisplay.add_theme_color_override("font_color", Color("562923") if isStorm() else Color("3b6d62"));
	timeDisplay.text = "Day " + str(_time.getDay()) + ": ";
	timeDisplay.text += ("0" if _time.getHours() < 10 else "") + str(_time.getHours()) + ":";
	timeDisplay.text += ("0" if _time.getMinutes() < 10 else "") + str(_time.getMinutes());

	var targetAberration := (1.0 if isStorm() else 0.0);
	_currentAberration = lerp(_currentAberration, targetAberration, ABERRATION_TRANSITION * delta);
	RenderingServer.global_shader_parameter_set("aberrationStrength", _currentAberration);
	
	
