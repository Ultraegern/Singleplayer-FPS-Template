extends CharacterBody3D
class_name Enemy

@export var max_health: float = 100
var health: float

func _ready() -> void:
	health = max_health

func take_damage(damage: float) -> void:
	health -= damage
	if health <= 0.0:
		queue_free()
