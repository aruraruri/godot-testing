extends Node3D

@onready var physics_bones := find_child("PhysicalBoneSimulator3D", true, false) as PhysicalBoneSimulator3D
var character: CharacterBody3D
@onready var bones_to_monitor: Array[Node] = find_children("Physical Bone*", "PhysicalBone3D", true, false)
var active_bones: Array[Node] = []
@onready var root_ref = $"Armature/Skeleton3D/PhysicalBoneSimulator3D/Physical Bone Root"
@onready var impulse_ray_left: RayCast3D = $impulseLeft
@onready var impulse_ray_right: RayCast3D = $impulseRight
@export var sweep_strenght: float = 200.0

@onready var ragdoll_skeleton: Skeleton3D = $Armature/Skeleton3D
var character_skeleton: Skeleton3D

@export var pose_blend_duration := 0.5  # Seconds to blend between poses
var pose_blend_timer := 0.0
var is_blending_pose := false
var pre_blend_poses := {}  # Dictionary to store initial poses

signal bones_sleep

func _ready() -> void:
	# disable and hide ragdoll initially
	set_physics_process(false)
	hide()
	# connect to character fall signal
	character = get_tree().get_root().get_node("TestingMap/DemonCharbody")
	character.player_fall.connect(handle_fall)
	character_skeleton = character.get_node("Armature/Skeleton3D")  # Adjust path as needed

func copy_skeleton_pose(immediate: bool = false):
	if ragdoll_skeleton.get_bone_count() != character_skeleton.get_bone_count():
		push_warning("Skeleton bone counts don't match!")
		return
	
	if immediate:
		# Immediate copy without blending
		for bone_idx in ragdoll_skeleton.get_bone_count():
			var bone_pose = character_skeleton.get_bone_pose(bone_idx)
			ragdoll_skeleton.set_bone_pose_position(bone_idx, bone_pose.origin)
			ragdoll_skeleton.set_bone_pose_rotation(bone_idx, bone_pose.basis.get_rotation_quaternion())
			ragdoll_skeleton.set_bone_pose_scale(bone_idx, bone_pose.basis.get_scale())
	else:
		# Start blending process
		pre_blend_poses.clear()
		for bone_idx in ragdoll_skeleton.get_bone_count():
			pre_blend_poses[bone_idx] = {
				"position": ragdoll_skeleton.get_bone_pose_position(bone_idx),
				"rotation": ragdoll_skeleton.get_bone_pose_rotation(bone_idx),
				"scale": ragdoll_skeleton.get_bone_pose_scale(bone_idx)
			}
		pose_blend_timer = 0.0
		is_blending_pose = true

func handle_fall(velocity, fall_direction, forward_dir, up_dir) -> void:
	print("FALL TRIGGERED FROM player_fall SIGNAL")
	set_physics_process(true)
	
	# Start with immediate pose copy from character
	copy_skeleton_pose(true)
	
	# Then initiate blending to current character pose
	copy_skeleton_pose(false)
	
	# transfer ragdoll over to player
	global_transform = character.transform
	
	# start stop sim to reset sim state to standing
	physics_bones.physical_bones_stop_simulation()
	physics_bones.physical_bones_start_simulation()
	
	# show ragdoll
	show()
	
	print("monitored bones: ", bones_to_monitor)
	# set bones to active (without duplicate bones_to_monitor was emptying on second fall onwards)
	active_bones = bones_to_monitor.duplicate()
	print("ACTIVE BONES: ", active_bones)
	
	# apply physics impulse to active bones
	for i in range(active_bones.size() - 1, -1, -1):
		var bone = active_bones[i]
		bone.apply_central_impulse(velocity*6)
		
	var right_dir = forward_dir.cross(up_dir).normalized()
	var left_dir = -right_dir
	var backward_dir = -forward_dir

	match fall_direction:
		"right":
			active_bones[11].apply_central_impulse(left_dir * sweep_strenght)
			active_bones[9].apply_central_impulse(left_dir * sweep_strenght)

		"left":
			active_bones[9].apply_central_impulse(right_dir * sweep_strenght)
			active_bones[11].apply_central_impulse(right_dir * sweep_strenght)

		"backward":
			active_bones[0].apply_central_impulse(up_dir * sweep_strenght)
			active_bones[3].apply_central_impulse(backward_dir * sweep_strenght)
			active_bones[3].apply_central_impulse(backward_dir * sweep_strenght)
			active_bones[2].apply_central_impulse(backward_dir * sweep_strenght)
			active_bones[9].apply_central_impulse(forward_dir * sweep_strenght)
			active_bones[11].apply_central_impulse(forward_dir * sweep_strenght)

		"forward":
			active_bones[9].apply_central_impulse(backward_dir * sweep_strenght)
			active_bones[11].apply_central_impulse(backward_dir * sweep_strenght)
	
func _physics_process(delta: float) -> void:
	
	#CHECKING WHEN ALL BONES GO TO SLEEP -> fire signal to player controller to rise
	for i in range(active_bones.size() - 1, -1, -1):
		var bone = active_bones[i]
		# bone activity threshold
		if bone.get_linear_velocity().length() < 0.00025:
			print("bone removed: ", bone)
			active_bones.remove_at(i)
	
	# MAYBE WANT!!! to have a threshold instead -> over half of bones sleeping = bones_sleep
	# Bone sleep checking
	if active_bones.is_empty():
		# Force skeleton update before copying pose
		ragdoll_skeleton.skeleton_updated.connect(_on_skeleton_updated, CONNECT_ONE_SHOT)
		
	
	
func _on_skeleton_updated():
	
	# 1. Store the ragdoll's final pose
	var ragdoll_poses = {}
	for bone_idx in ragdoll_skeleton.get_bone_count():
		ragdoll_poses[bone_idx] = {
			"position": ragdoll_skeleton.get_bone_pose_position(bone_idx),
			"rotation": ragdoll_skeleton.get_bone_pose_rotation(bone_idx),
			"scale": ragdoll_skeleton.get_bone_pose_scale(bone_idx)
		}
	
	emit_signal("bones_sleep", root_ref, ragdoll_poses)
	hide()
	set_physics_process(false)
	
