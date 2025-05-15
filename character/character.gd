extends Node3D

@export var move_speed: float = 7.0
@export var turn_speed: float = 5.0
@export var ground_offset: float = 0.0

@onready var l_leg = $leftIkTarget
@onready var r_leg = $rightIkTarget

func _process(delta: float) -> void:
	#var plane1 = Plane(global_position ,l_leg.global_position, r_leg.global_position)
	#var plane2 = Plane(Vector3.UP)
	#var avg_normal = ((plane1.normal + plane2.normal ) / 2).normalized()
	
	var target_basis = _basis_from_normal(Vector3.UP)
	transform.basis = lerp(transform.basis, target_basis, move_speed * delta).orthonormalized()
	
	var avg = (l_leg.position + r_leg.position) / 2
	var target_pos = avg 
	# DIVIDE MOVESPEED BY TWO for player to always be able to overcome this height position by input
	position = lerp(position, target_pos, (move_speed/2) * delta)
	
	_handle_movement(delta)
	
func _handle_movement(delta):
	var dir = Input.get_axis("ui_down", "ui_up")
	translate(Vector3(dir, 0, 0) * move_speed * delta)
	
	var a_dir = Input.get_axis("ui_right", "ui_left")
	rotate_object_local(Vector3.UP, a_dir * turn_speed * delta)
	
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
