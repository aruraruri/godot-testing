extends CharacterBody3D

@export var move_speed: float = 7.0
@export var turn_speed: float = 5.0
@export var ground_offset: float = 0.0
@export var leg_distance_fall_threshold: float = 1.2
@export var fall_speed: float = 1.0

@onready var l_leg = $Character/leftIkTarget
@onready var r_leg = $Character/rightIkTarget

@onready var l_ik = $Character/Skeleton3D/leftIk
@onready var r_ik = $Character/Skeleton3D/rightIk

func _physics_process(delta: float) -> void:
	#var plane1 = Plane(global_position ,l_leg.global_position, r_leg.global_position)
	#var plane2 = Plane(Vector3.UP)
	#var avg_normal = ((plane1.normal + plane2.normal ) / 2).normalized()
	move_and_slide()

func _process(delta: float) -> void:
	#var target_basis = _basis_from_normal(Vector3.UP)
	#transform.basis = lerp(transform.basis, target_basis, move_speed * delta).orthonormalized()
	
	var avg = (l_leg.position + r_leg.position) / 2
	var target_pos = avg 
	# DIVIDE MOVESPEED BY TWO for player to always be able to overcome this height position set
	position.y = lerp(position.y, target_pos.y, (move_speed) * delta)
	_handle_movement(delta)
	
	
	
func _fall_towards(delta: float, fall_position: Vector3) -> void:
	var fall_direction = (fall_position - position).normalized()
	
	#var fall_transform = _basis_from_normal((fall_direction))
	rotation = lerp(rotation, fall_direction, delta * fall_speed)
	#print(fall_direction)
	
	
func _handle_movement(delta):

	var input_dir = Input.get_vector("left", "right", "up", "down").normalized()
	var movement_vector = (Vector3(input_dir.x, ground_offset, input_dir.y))
	#print(movement_vector)
	
	velocity = velocity.lerp(movement_vector * move_speed, 0.5)
	#print(velocity)
	#move_and_slide()
	
	#global_translate(movement_vector * move_speed * delta)
	
	
	
	var look_dir = Input.get_vector("look_left", "look_right", "look_up", "look_down").normalized()
	var target_angle = atan2(look_dir.x, look_dir.y) - PI/2
	
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
