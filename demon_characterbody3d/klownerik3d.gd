# Klowner's SkeletonIK FABRIK solver
# Copyright (C) 2025 Mark Riedesel
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE 
# SOFTWARE.
@tool

class_name KlownerIK3D
extends SkeletonModifier3D

var selected_bone_indices: PackedInt32Array  # Ordered from root to tail
var bones: Array[Transform3D];
var bone_origins: PackedVector3Array
var bone_lengths: PackedFloat32Array
var bone_directions: PackedVector3Array
var bone_rotations: Array[Quaternion];
var bone_chain_length := 0.0

@export_node_path var target_node: NodePath
@export_enum(" ") var root_bone: String
@export_enum(" ") var tail_bone: String
@export var pre_rotate := true  # Perform initial rotation from root to tail of IK chain to point to target
@export var error_tolerance := 0.001
@export var rotate_tail := true
@export var enable_twist := false

func _validate_property(property: Dictionary) -> void:
	if property.name == "root_bone" or property.name == "tail_bone":
		var skeleton := get_skeleton()
		if skeleton:
			property.hint = PROPERTY_HINT_ENUM
			property.hint_string = skeleton.get_concatenated_bone_names()


func _process_modification() -> void:
	var skeleton := get_skeleton() 
	if not skeleton:
		return
	_update_selected_bone_indices(skeleton)
	if selected_bone_indices.size() < 3:
		push_warning("not enough bones in chain (minimum: 3): {}".format([selected_bone_indices.size()]))
		return
	_fabrik_solver(skeleton)


func _update_selected_bone_indices(skeleton: Skeleton3D) -> void:
	if not root_bone or not tail_bone:
		return
	var root_bone_index := skeleton.find_bone(root_bone)
	var tail_bone_index := skeleton.find_bone(tail_bone)
	if tail_bone_index < 0 or root_bone_index < 0:
		push_warning("Unable to find both end bones of selected bone chain")
		return
	selected_bone_indices.clear()
	while tail_bone_index != root_bone_index:
		selected_bone_indices.push_back(tail_bone_index)
		tail_bone_index = skeleton.get_bone_parent(tail_bone_index)
		if tail_bone_index < 0:
			push_warning("Selected root bone does not appear to be an ancestor of the selected tail bone")
			selected_bone_indices.clear()
			return
	selected_bone_indices.push_back(tail_bone_index)
	selected_bone_indices.reverse()


func _fabrik_solver(skeleton: Skeleton3D) -> void:
	var target: Node3D = get_node(target_node) if target_node else self
	var ik_target_origin :=  skeleton.to_local(target.global_transform.origin)  # skeleton space

	# Resize temporary buffers to accommodate selected bones
	var num_joints := selected_bone_indices.size()
	if bones.size() != num_joints + 1:
		bones.resize(num_joints + 1)
		bone_origins.resize(num_joints)
		bone_lengths.resize(num_joints)
		bone_directions.resize(num_joints)
		bone_rotations.resize(num_joints)

  # Collect current bone transforms
	for i in num_joints:
		var b := selected_bone_indices[i]
		bones[i] = skeleton.get_bone_global_pose(b)
		bone_origins[i] = bones[i].origin

  # Add zero-length bone to the end of the processing chain to simplify later iteration
		bones[-1] = Transform3D(bones[-2].basis, Vector3.ZERO)

  # Calculate chain lengths, directions, and rotations
	bone_chain_length = 0.0
	for i in num_joints:
		var parent_bone := bones[i]
		var child_bone := bones[i + 1]
		var bone_length := parent_bone.origin.distance_to(child_bone.origin)
		bone_lengths[i] = bone_length
		bone_directions[i] = (child_bone.origin - parent_bone.origin).normalized()
		bone_rotations[i] = parent_bone.basis.get_rotation_quaternion()
		bone_chain_length += bone_length  # accumulate total chain length
 
  # Calculate pre-inverse kinematics transformations
	var pre_transform: Transform3D
	if pre_rotate:
		var chain_direction := (bone_origins[-1] - bone_origins[0]).normalized() as Vector3
		var target_direction := (ik_target_origin - bone_origins[0]).normalized() as Vector3
		var diff_rotation := Quaternion(target_direction, chain_direction)
		pre_transform = Transform3D(Basis.IDENTITY, -bone_origins[0])
		pre_transform = Transform3D(Basis(diff_rotation), bone_origins[0]) * pre_transform
		for i in num_joints:
			bone_origins[i] *= pre_transform

	if enable_twist:
		# Determine the Y-axis twist of the tail bone relative to the resting position.
		var twist := bone_rotations[num_joints-1]
		for i in num_joints - 1:
			bone_rotations[i] *= twist

	var root_distance_to_target := bone_origins[0].distance_to(ik_target_origin)
	if root_distance_to_target > bone_chain_length:
		var direction := (ik_target_origin - bone_origins[0]).normalized()
		for i in range(1, num_joints):
			bone_origins[i] = bone_origins[i-1] + direction * bone_lengths[i-1]
	else:
		var root_origin := bone_origins[0] #.origin
		var max_iterations := 5
		var iteration := 0
		while iteration < max_iterations:
			iteration += 1
		# Forward reaching phase...
			bone_origins[-1] = ik_target_origin
			for i in range(num_joints - 2, -1, -1):
				bone_origins[i] = bone_origins[i+1] \
				+ (bone_lengths[i] / bone_origins[i+1].distance_to(bone_origins[i])) \
				* (bone_origins[i] - bone_origins[i+1])
		# Backward reaching phase...)
			bone_origins[0] = root_origin
		for i in range(num_joints - 1):
		bone_origins[i+1] = bone_origins[i] \
		  + (bone_lengths[i] / bone_origins[i+1].distance_to(bone_origins[i])) \
		  * (bone_origins[i+1] - bone_origins[i])
	  # Check if tail bone is sufficiently close to the target position
	  if bone_origins[-1].distance_to(ik_target_origin) < error_tolerance:
		break

  # Apply transformations to skeleton
  for i in num_joints-1:
	bones[i].origin = bone_origins[i]
	var bone_direction := (bone_origins[i+1] - bone_origins[i]).normalized()
	var target_rotation := Quaternion(bone_directions[i], bone_direction)
	if pre_rotate:
	  var bone_x_axis_direction := Quaternion(pre_transform.basis.inverse()) * bone_rotations[i]
	  var roll_correction := Quaternion(target_rotation * Vector3.LEFT, bone_x_axis_direction * Vector3.LEFT)
	  if i < num_joints-1:
		bones[i].basis = Basis(roll_correction * target_rotation * bone_rotations[i])
	else:
	  bones[i].basis = Basis(target_rotation * bone_rotations[i])
	skeleton.set_bone_global_pose(selected_bone_indices[i], bones[i])
  
  if rotate_tail:
	bones[-1].origin = bone_origins[-1]
	bones[-1].basis = skeleton.global_transform.basis.inverse() \
	  * target.global_transform.basis \
	  * Basis(bone_rotations[-1])
	skeleton.set_bone_global_pose(selected_bone_indices[-1], bones[-1])
