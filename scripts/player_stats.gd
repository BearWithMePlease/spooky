extends Control

var health: float = 100
var ammunition: int = 0
var ammunition_pool_total: int = 0

@onready var health_label := $Health
@onready var ammo_label := $Ammo

func _ready() -> void:
	_update_text()

func _process(delta: float) -> void:
	set_health($"../../Player".HP)
	set_ammo($"../../Player/gun".ammunition, $"../../Player/gun".ammunition_pool_total)
	

func _update_text():
	var at_count = clampi(ceili(health / 10.0), 0, 10)
	health_label.text = "Health:\n[" + '@'.repeat(at_count) +  ' '.repeat(10 - at_count) + "]"

	ammo_label.text = "Ammo:\n" + str(ammunition) + "|" + str(ammunition_pool_total)

func set_health(new_health:int):
	if new_health == self.health:
		return
	
	self.health = clampi(new_health, 0, 100)
	_update_text()

func set_ammo(new_ammunition:int, ammunition_pool_total:int):
	self.ammunition = max(0, new_ammunition)
	self.ammunition_pool_total = max(0, ammunition_pool_total)
	_update_text()
