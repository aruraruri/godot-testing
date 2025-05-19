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
@onready var body_tilt: LookAtModifier3D = $body
@onready var collision: CollisionShape3D = $RigidCollisionShape3D

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

func _physics_process(delta: float) -> void:
	if freeze:
		var avg = (left_target.position + right_target.position) / 2
		var target_pos = avg + transform.basis.y * ground_offset
		var distance = transform.basis.y.dot(target_pos - position)
		position = lerp(position, position + transform.basis.y * distance, move_speed * delta)
	_handle_tilt(delta)
