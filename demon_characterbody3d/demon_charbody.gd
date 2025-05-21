extends CharacterBody3D
@export var move_speed: float = 5.0
@export var turn_speed: float = 1.0
@export var ground_offset: float = 0
@export var sprint_speed: float = 10.0
@export var tilt_speed: float = 30
@export var mass_offset_speed = 0.1
@onready var left_target: Marker3D = $leftLegIKTarget
@onready var right_target: Marker3D = $rightLegIKTarget
@onready var sideways_tilt_target: Marker3D = $Armature/Skeleton3D/SidewaysBodyTiltTarget
@onready var forwards_tilt_target: Marker3D = $Armature/Skeleton3D/ForwardBackwardBodyTiltTarget
@onready var mesh: MeshInstance3D = $Armature/Skeleton3D/char_lowpoly

@onready var LfootCast: RayCast3D = $Armature/Skeleton3D/LeftFootBoneAttachment3D/LFootRayCast3D
@onready var RfootCast: RayCast3D = $Armature/Skeleton3D/RightFootBoneAttachment3D/RFootRayCast3D

@onready var fallRay: RayCast3D = $FallRayCast3D

@export var tilt_limit_forwards: float = 4.0

@export var tilt_limit_right: float = 2.5
@export var tilt_limit_left: float = -2.5
@export var tilt_recovery_lerp_weight = 0.008
var atLimit: bool = false
var fall_direction: int
var fallen: bool = false
signal player_fall

func _ready() -> void:
	var ragdoll = get_tree().get_root().get_node("TestingMap/DemonRagdoll")
	#print(ragdoll)
	ragdoll.bones_sleep.connect(get_up)
	
func ground_angle_walkable(normal: Vector3):
	var difference = normal.dot(Vector3.UP)
	#print(difference)
	if (difference > 0.80):
		return true
	else:
		return false
	
func _handle_tilt(delta: float):
	
	# recover balance if both feet are on the ground and the ground is even enough
	if (LfootCast.is_colliding() and RfootCast.is_colliding() and ground_angle_walkable(LfootCast.get_collision_normal()) and ground_angle_walkable(RfootCast.get_collision_normal())):
		# TILT RECOVERY WEIGHT with HARD-CODED ZERO OUT POS
		sideways_tilt_target.position.y = lerp(sideways_tilt_target.position.y, 0.0, tilt_recovery_lerp_weight)
		forwards_tilt_target.position.z = lerp(forwards_tilt_target.position.z, -1.0, tilt_recovery_lerp_weight)
		#print("feet on ground")
		
	# make sure foot raycasts are always pointing downwards
	if (!LfootCast.is_colliding() or !ground_angle_walkable(LfootCast.get_collision_normal())):
		#print("left foot off ground")
		if sideways_tilt_target.position.y < tilt_limit_left:
			sideways_tilt_target.position.y = tilt_limit_left
			fall_direction = -1
			atLimit = true
		else:
			sideways_tilt_target.position.y -= tilt_speed * delta
			#center_of_mass.x -= mass_offset_speed
			atLimit = false
			
	

	if (!RfootCast.is_colliding() or !ground_angle_walkable(RfootCast.get_collision_normal())):
		#print("right foot off ground")
		
		if sideways_tilt_target.position.y > tilt_limit_right:
			sideways_tilt_target.position.y = tilt_limit_right
			fall_direction = 1
			atLimit = true
			
		else:
			sideways_tilt_target.position.y += tilt_speed * delta
			#center_of_mass.x += mass_offset_speed
			atLimit = false
			
			
			
	if (!RfootCast.is_colliding() or !ground_angle_walkable(RfootCast.get_collision_normal()) and !LfootCast.is_colliding() or !ground_angle_walkable(LfootCast.get_collision_normal())):
		#print("right foot off ground")
		
		if forwards_tilt_target.position.z > tilt_limit_forwards:
			forwards_tilt_target.position.z = tilt_limit_forwards
			fall_direction = 0
			atLimit = true
			
		else:
			forwards_tilt_target.position.z += tilt_speed * delta
			#center_of_mass.x += mass_offset_speed
			atLimit = false
			
			
	
	if atLimit:
		fall() # Turn on physics
		return
	
	# get_up is instead called through ragdoll "bones_sleep" signal
	#get_up()

func fall():
	#do once
	if (!fallen):
		emit_signal("player_fall", velocity, fall_direction)

	fallen = true
	mesh.hide()

# reference to PhysicalBones root from signal
func get_up(root_ref):
	position = root_ref.position
	sideways_tilt_target.position.y = 0
	forwards_tilt_target.position.z = 0
	atLimit = false
	fallen = false
	mesh.show()

func _handle_movement(delta):

	var input_dir = Input.get_vector("left", "right", "up", "down").normalized()
	var movement_vector = (Vector3(input_dir.x, 0, input_dir.y))
	#print(movement_vector)
	
	velocity = velocity.lerp(movement_vector * move_speed, 0.5)
	#print(velocity)
	
	# move rigid body collision along
	#translate(Vector3(input_dir.x, 0, input_dir.y) * move_speed * delta)
	
	
func _handle_rotation(delta):
	var look_dir = Input.get_vector("look_left", "look_right", "look_up", "look_down").normalized()
	var target_angle = atan2(look_dir.x, look_dir.y) - PI
	
	if (look_dir):
		rotation.y = lerp_angle(rotation.y, target_angle, turn_speed * delta)
		

func _apply_gravity(delta):
	position.y -= 1.0 * delta

func _physics_process(delta: float) -> void:
	if !fallen:
		#height setting with ik targets
		
		#var avg = (left_target.position + right_target.position) / 2
		var target_pos = Vector3(fallRay.get_collision_point().x, fallRay.get_collision_point().y + + ground_offset, fallRay.get_collision_point().z)
		position.y = lerp(position.y, target_pos.y, 0.1)
		
		_handle_movement(delta)
		_handle_rotation(delta)
		_handle_tilt(delta)
		
		move_and_slide()
		
	
