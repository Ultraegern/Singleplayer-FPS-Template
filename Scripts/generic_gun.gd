@icon("res://Assets/Icons/gun.png")
extends Node3D
class_name Gun

@export var damage: float
@export var fire_rate: float
@export_enum("Semi Auto", "Full Auto") var fire_mode
@export var icon: Texture2D
