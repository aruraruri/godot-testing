extends Node3D

@onready var physics_bones := find_child("PhysicalBoneSimulator3D", true, false) as PhysicalBoneSimulator3D
var character: CharacterBody3D
@onready var bones_to_monitor: Array[Node] = find_children("Physical Bone*", "PhysicalBone3D", true, false)
var active_bones: Array[Node] = []

signal bones_sleeping

func _ready() -> void:
	PhysicalBone3D
	set_physics_process(false)
	print(bones_to_monitor)
	character = get_tree().get_root().get_node("TestingMap/DemonCharbody")
	character.player_fall.connect(handle_fall)
	character.player_rise.connect(handle_rise)
	
func handle_fall() -> void:
	set_physics_process(true)
	global_transform = character.transform
	show()
	physics_bones.physical_bones_stop_simulation()
	physics_bones.physical_bones_start_simulation()
	
	# set bones to active
	active_bones = bones_to_monitor
	print("ACTIVE BONES: ", active_bones)
	print("FALL TRIGGERED FROM player_fall SIGNAL")
	
func handle_rise() -> void:
	hide()
	physics_bones.physical_bones_stop_simulation()
	set_physics_process(false)
	
func _physics_process(delta: float) -> void:
	
	#CHECKING WHEN ALL BONES GO TO SLEEP -> fire signal to player controller to rise
	
	for i in range(active_bones.size() - 1, -1, -1):
		var bone = active_bones[i]
		if bone.get_linear_velocity().length() < 0.01:
			print("bone removed: ", bone)
			active_bones.remove_at(i)
			
	if active_bones.is_empty():
		emit_signal("bones_sleeping")
		print("the bones sleep...")
	
