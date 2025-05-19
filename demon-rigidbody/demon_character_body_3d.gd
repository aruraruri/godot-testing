extends CharacterBody3D

@export var move_speed: float = 7.0
@export var turn_speed: float = 5.0
@export var ground_offset: float = 0.0
@export var leg_distance_fall_threshold: float = 1.2
@export var fall_speed: float = 1.0

@onready var l_leg = $leftLegIKTarget
@onready var r_leg = $rightLegIKTarget

@onready var l_ik = $Armature/Skeleton3D/leftLegIK
@onready var r_ik = $Armature/Skeleton3D/rightLegIK

func _physics_process(delta: float) -> void:
	move_and_slide()

func _process(delta: float) -> void:
	# make charbody height from leg ik pos
	var avg = (l_leg.position + r_leg.position) / 2
	var target_pos = avg
	# height setting
	position.y = lerp(position.y, target_pos.y, (move_speed) * delta)
	_handle_movement(delta)
	_handle_rotation(delta)
	
func _handle_movement(delta):

	var input_dir = Input.get_vector("left", "right", "up", "down").normalized()
	var movement_vector = (Vector3(input_dir.x, ground_offset, input_dir.y))
	#print(movement_vector)
	
	velocity = velocity.lerp(movement_vector * move_speed, 0.5)
	#print(velocity)
	
func _handle_rotation(delta):
	var look_dir = Input.get_vector("look_left", "look_right", "look_up", "look_down").normalized()
	var target_angle = atan2(look_dir.x, look_dir.y) - PI
	
	if (look_dir):
		rotation.y = lerp_angle(rotation.y, target_angle, turn_speed * delta)

func _basis_from_normal(normal: Vector3) -> Basis:
	var result = Basis()
	result.x = normal.cross(transform.basis.z)
	result.y = normal
	result.z = transform.basis.x.cross(normal)

	result = result.orthonormalized()
	result.x *= scale.x 
	result.y *= scale.y 
	result.z *= scale.z 
	
	return result
