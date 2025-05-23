extends GodotIKEffector

@export var step_target: Node3D
@export var walk_step_distance: float = 0.5
@export var sprint_step_distance: float = 1.0
@export var walk_step_duration: float = 0.1
@export var sprint_step_duration: float = 0.2
@onready var demon_charbody: CharacterBody3D = $"../../../../.."
@onready var player_step_sound: AudioStreamPlayer3D = $"../../../../../AudioStreamPlayer3D_playersteps"
@export var adjacent_target: GodotIKEffector

var is_stepping := false

# tween callback when step is complete
func step_over():
	is_stepping = false
	
	
func _process(_delta):
	if demon_charbody.sprinting:
		if !is_stepping && !adjacent_target.is_stepping && abs(global_position.distance_to(step_target.global_position)) > sprint_step_distance:
			print("sprinting!")
			step()
	elif !is_stepping && !adjacent_target.is_stepping && abs(global_position.distance_to(step_target.global_position)) > walk_step_distance:
		step()

func step():
	player_step_sound.play()
	var target_pos = step_target.global_position
	var half_way = (global_position + step_target.global_position) / 2
	is_stepping = true
	player_step_sound.play()
	
	var t = get_tree().create_tween()
	# vec3 is the step height for tweening
	t.tween_property(self, "global_position", half_way + Vector3(0, 0.2, 0), 0.1)
	t.tween_property(self, "global_position", target_pos, 0.1)
	t.tween_callback(step_over)
	
func force_foot_to_target():
	print("ik_target forcing foot to target")
	is_stepping = false
	global_position = step_target.global_position
