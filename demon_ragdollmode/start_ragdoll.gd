extends Node3D

@onready var physics_bones := find_child("PhysicalBoneSimulator3D", true, false) as PhysicalBoneSimulator3D
var character: CharacterBody3D

func _ready() -> void:

	character = get_tree().get_root().get_node("TestingMap/DemonCharbody")
	character.player_fall.connect(handle_fall)
	
func handle_fall() -> void:
	global_transform = character.transform
	physics_bones.physical_bones_stop_simulation()
	physics_bones.physical_bones_start_simulation()
	print("FALL TRIGGERED FROM player_fall SIGNAL")
	
	
