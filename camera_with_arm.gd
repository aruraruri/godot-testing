extends Node3D

@export var follow_weight: float = 1.6

@export var character: CharacterBody3D  
@export var ragdoll: Node3D  

@export var randomStrength: float = 30.0
@export var shakeFade: float = 5.0

@onready var camera: Camera3D = get_child(0)

var ragdoll_skele: Skeleton3D
var ragdoll_arma: Node3D

var ragdoll_root_bone_pos
var ragdoll_target_pos

#var player_side_tilt: float = 0.0
#var player_back_tilt: float = 0.0

var rng = RandomNumberGenerator.new()
var shake_strength: float = 0.0


func apply_shake():
	shake_strength += randomStrength

func randomOffset() -> Vector2:
	return Vector2(rng.randf_range(-shake_strength, shake_strength),rng.randf_range(-shake_strength, shake_strength))
	
func track_player_side_tilt(amt, max_left, max_right):
	if (amt <= max_left - (max_left/3) or amt >= max_right - (max_right/3)):
		print("Camera: player nearing sideways fall threshold, applying shake")
		apply_shake()
	
func track_player_back_tilt(amt, max_back):
	if (amt <= max_back - (max_back/3)):
		print("Camera: player nearing backwards fall threshold, applying shake")
		apply_shake()

func _ready() -> void:
	if !character or !ragdoll:  
		print("Camera: Missing character or ragdoll reference!")  
		return  

	character.player_tilt_side.connect(track_player_side_tilt)
	character.player_tilt_back.connect(track_player_back_tilt)
	
	ragdoll_arma = ragdoll.get_child(0)
	ragdoll_skele = ragdoll_arma.get_child(0)
	ragdoll_skele.skeleton_updated.connect(get_bone_loc)
	


func get_bone_loc():
	
	ragdoll_root_bone_pos = (ragdoll_skele.global_transform * ragdoll_skele.get_bone_global_pose(0).origin)
	# camera_target root bone pos in world space, where we add the bone local space offset to the ragdoll scene root, to get EXACTLY same camera_target positioning as in character camera_target
	ragdoll_target_pos = Vector3(ragdoll_root_bone_pos.x + ragdoll_skele.get_bone_global_pose(0).origin.x, 
								ragdoll_root_bone_pos.y + ragdoll_skele.get_bone_global_pose(0).origin.y, 
								ragdoll_root_bone_pos.z + ragdoll_skele.get_bone_global_pose(0).origin.z)
	
func _process(delta: float) -> void:
	# local shake variable that is added onto global target pos if there should be shake
	var shaky = Vector2()
	if shake_strength > 0:
		shake_strength = lerpf(shake_strength, 0, shakeFade * delta)
		shaky = randomOffset()
		
	# Track camera_target position
	global_position = global_position.lerp(Vector3(character.global_position.x + shaky.x, character.global_position.y + shaky.y, character.global_position.z), follow_weight)

	if (character.fallen):
		global_position = global_position.lerp(ragdoll_target_pos, follow_weight)
