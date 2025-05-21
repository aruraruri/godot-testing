extends Node3D

@onready var physics_bones := find_child("PhysicalBoneSimulator3D", true, false) as PhysicalBoneSimulator3D
var character: CharacterBody3D
@onready var bones_to_monitor: Array[Node] = find_children("Physical Bone*", "PhysicalBone3D", true, false)
var active_bones: Array[Node] = []
@onready var root_ref = $"Armature/Skeleton3D/PhysicalBoneSimulator3D/Physical Bone Root"
@onready var impulse_ray_left: RayCast3D = $impulseLeft
@onready var impulse_ray_right: RayCast3D = $impulseRight
@export var sweep_strenght: float = 200.0

signal bones_sleep

func _ready() -> void:
	# disable and hide ragdoll initially
	set_physics_process(false)
	hide()
	# connect to character fall signal
	character = get_tree().get_root().get_node("TestingMap/DemonCharbody")
	character.player_fall.connect(handle_fall)
	
	
func handle_fall(velocity, fall_direction, forward_dir, up_dir) -> void:
	print("FALL TRIGGERED FROM player_fall SIGNAL")
	set_physics_process(true)
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
		if bone.get_linear_velocity().length() < 0.01:
			print("bone removed: ", bone)
			active_bones.remove_at(i)
	
	# MAYBE WANT!!! to have a threshold instead -> over half of bones sleeping = bones_sleep
	if active_bones.is_empty():
		emit_signal("bones_sleep", root_ref)
		print("the bones sleep...")
		physics_bones.physical_bones_stop_simulation()
		hide()
		set_physics_process(false)
		
	
