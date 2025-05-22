extends Node3D
class_name CustomBoneAttachment

## The Skeleton3D node this attachment belongs to
@export var skeleton: Skeleton3D
## Name of the bone to attach to
@export var bone_name: String = ""
## If true, the node will follow the bone's rotation
@export var attach_rotation: bool = false
## If true, updates in physics process for better sync with CharacterBody3D
@export var use_physics_process: bool = true

var bone_idx: int = -1
var initial_transform: Transform3D
var skeleton_global_transform: Transform3D

func _ready():
	if skeleton == null:
		# Try to find skeleton in parent nodes if not explicitly set
		skeleton = find_parent("Skeleton3D") as Skeleton3D
	
	if skeleton == null:
		push_error("No Skeleton3D found for BoneAttachment")
		return
	
	if bone_name.is_empty():
		push_warning("No bone name specified for BoneAttachment")
		return
	
	bone_idx = skeleton.find_bone(bone_name)
	skeleton.skeleton_updated.connect(_on_modification_processed)
	if bone_idx == -1:
		push_error("Bone '%s' not found in skeleton" % bone_name)
		return
	
	# Store initial transform relative to bone in global space
	
func _on_modification_processed():
	if bone_idx == -1:
		return
	
	# Get the bone's global pose
	var bone_transform = skeleton.get_bone_global_pose(bone_idx)

	# Get the global position
	var bone_global_position = skeleton.global_transform * bone_transform.origin
	# Full attachment (position + rotation)
	global_position = bone_global_position

	
