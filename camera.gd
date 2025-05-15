extends Camera3D

@export var follow_speed: float = 5.0
@export var target: Node3D
@export var target_offset: float = 5.0

func _process(delta: float) -> void:
	if target:
		# Calculate target position (only X and Z from target, keep camera's current Y)
		var target_pos = Vector3(target.global_position.x, global_position.y, target.global_position.z - target_offset)
		# Move smoothly toward target position
		global_position = global_position.lerp(target_pos, follow_speed * delta)
