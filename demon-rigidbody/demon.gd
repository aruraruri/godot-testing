extends RigidBody3D
@export var move_speed: float = 5.0
@export var turn_speed: float = 1.0
@export var ground_offset: float = 0
@export var sprint_speed: float = 10.0
@export var tilt_speed: float = 30
@export var mass_offset_speed = 0.1
@onready var left_target: Marker3D = $CharacterBody3D/leftLegIKTarget
@onready var right_target: Marker3D = $CharacterBody3D/rightLegIKTarget
@onready var tilt_target: Marker3D = $CharacterBody3D/Armature/Skeleton3D/bodyTiltTarget
@onready var collision: CollisionShape3D = $RigidCollisionShape3D
@onready var charbody3d: CharacterBody3D = $CharacterBody3D

@export var tilt_limit_right: float = 6.4
@export var tilt_limit_left: float = -3.7
var atLimit: bool = false
@onready var physical_bone_simulator_3d: PhysicalBoneSimulator3D = $Armature/Skeleton3D/PhysicalBoneSimulator3D

	
### testing tilt manually
func _handle_tilt(delta: float):
	if Input.is_action_pressed("tilt_left"):
		if tilt_target.position.y < tilt_limit_left:
			tilt_target.position.y = tilt_limit_left
			atLimit = true
		else:
			tilt_target.position.y -= tilt_speed * delta
			#center_of_mass.x -= mass_offset_speed
			atLimit = false
		
	if Input.is_action_pressed("tilt_right"):
		if tilt_target.position.y > tilt_limit_right:
			tilt_target.position.y = tilt_limit_right
			atLimit = true
			
		else:
			tilt_target.position.y += tilt_speed * delta
			#center_of_mass.x += mass_offset_speed
			atLimit = false
	
	if atLimit:
		freeze = false # Turn on physics
		#physical_bone_simulator_3d.physical_bones_start_simulation()
		return
	
	#physical_bone_simulator_3d.physical_bones_stop_simulation()
	freeze = true
	
func _handle_movement(delta):

	var input_dir = Input.get_vector("left", "right", "up", "down").normalized()
	var movement_vector = (Vector3(input_dir.x, ground_offset, input_dir.y))
	#print(movement_vector)
	
	charbody3d.velocity = charbody3d.velocity.lerp(movement_vector * move_speed, 0.5)
	#print(velocity)
	
	# move rigid body collision along
	#translate(Vector3(input_dir.x, 0, input_dir.y) * move_speed * delta)
	
	
func _handle_rotation(delta):
	var look_dir = Input.get_vector("look_left", "look_right", "look_up", "look_down").normalized()
	var target_angle = atan2(look_dir.x, look_dir.y) - PI
	
	if (look_dir):
		charbody3d.rotation.y = lerp_angle(charbody3d.rotation.y, target_angle, turn_speed * delta)

func _physics_process(delta: float) -> void:
	if freeze:
		var avg = (left_target.position + right_target.position) / 2
		var target_pos = avg + transform.basis.y * ground_offset
		var distance = transform.basis.y.dot(target_pos - position)
		position = lerp(position, position + transform.basis.y * distance, move_speed * delta)
	
		
		# height setting
		#position.y = lerp(position.y, target_pos.y, (move_speed) * delta)
		_handle_movement(delta)
		_handle_rotation(delta)
		
		
		charbody3d.move_and_slide()
		
	_handle_tilt(delta)
