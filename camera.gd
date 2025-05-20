extends Camera3D

@export var follow_speed: float = 5.0
@export var target_offset_z: float = 5.0
@export var target_offset_y: float = 5.0

@export var character: CharacterBody3D  
@export var ragdoll: Node3D  

var target: Node3D
var ragdoll_skele: Skeleton3D
var ragdoll_arma: Node3D

func _ready() -> void:
	if !character or !ragdoll:  
		print("Camera: Missing character or ragdoll reference!")  
		return  

	character.player_fall.connect(switch_to_ragdoll)
	ragdoll.bones_sleep.connect(switch_to_character)
	ragdoll_arma = ragdoll.get_child(0)
	ragdoll_skele = ragdoll_arma.get_child(0)
	switch_to_character("asd")
	
	if character.player_fall.is_connected(switch_to_ragdoll):
		print("player_fall signal is connected")
	else:
		print("player_fall signal is NOT connected")
	

func switch_to_ragdoll(velocity, fall_direction) -> void:
	print("Switching camera to ragdoll skele")
	if ragdoll_skele:
		target = ragdoll_skele
	else:
		print("No ragdoll reference when trying to switch!")

func switch_to_character(root_ref) -> void:
	print("Switching camera to character")
	if character:
		target = character
	else:
		print("No character reference when trying to switch!")


func _process(delta: float) -> void:
	#print(target.global_position.y)
	if target:
		# Calculate target position (only X and Z from target, keep camera's current Y)
		var target_pos = Vector3(target.global_position.x, target.global_position.y - target_offset_y, target.global_position.z - target_offset_z)
		# Move smoothly toward target position
		global_position = global_position.lerp(target_pos, follow_speed * delta)
		
	if (target == ragdoll_skele):
		var target_pos = Vector3(ragdoll_skele.get_bone_pose_position(0).x, ragdoll_skele.get_bone_pose_position(0).y - target_offset_y, ragdoll_skele.get_bone_pose_position(0).z - target_offset_z)
		global_position = global_position.lerp(target_pos, follow_speed * delta)
