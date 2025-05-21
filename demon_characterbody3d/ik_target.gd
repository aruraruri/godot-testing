extends Marker3D

@export var step_target: Node3D
@export var step_distance: float = 1.0

@export var adjacent_target: Node3D

var is_stepping := false

func _process(delta):
	if !is_stepping && !adjacent_target.is_stepping && abs(global_position.distance_to(step_target.global_position)) > step_distance:
		step()

func step():
	var target_pos = step_target.global_position
	var half_way = (global_position + step_target.global_position) / 2
	is_stepping = true
	
	var t = get_tree().create_tween()
	# vec3 is the step height for tweening
	t.tween_property(self, "global_position", half_way + Vector3(0, 0.2, 0), 0.1)
	t.tween_property(self, "global_position", target_pos, 0.1)
	t.tween_callback(func(): is_stepping = false)
