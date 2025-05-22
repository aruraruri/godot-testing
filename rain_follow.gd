extends Node3D

@export var target: Node3D
@export var offset:Vector3 = Vector3(0,20,0)

func _process(delta: float) -> void:
	if !target:
		print("no rain follow target")
		return
	
	global_position = target.global_position + offset
