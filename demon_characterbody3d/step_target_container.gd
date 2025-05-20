extends Node3D

@export var offset: float = 40.0

@onready var parent = get_parent()
@onready var previous_position = parent.global_position

func _physics_process(delta: float) -> void:
	var velocity = parent.global_position - previous_position
	global_position = lerp(global_position, parent.global_position + (velocity * offset), 0.5)
	
	previous_position = parent.global_position
