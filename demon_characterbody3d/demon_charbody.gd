extends CharacterBody3D
@export var move_speed: float = 5.0
@export var turn_speed: float = 1.0
@export var ground_offset: float = 0
@export var sprint_speed: float = 3.0
@export var normal_sprint_speed: float = 3.0
@export var after_fall_sprint_speed: float = 2.0
@export var tilt_speed: float = 1.5
@export var sprint_tilt_speed: float = 2.5
@export var mass_offset_speed = 0.1
@onready var left_target: GodotIKEffector = $Armature/Skeleton3D/GodotIKLegIK/leftIKRoot/leftLegIKTarget
@onready var right_target: GodotIKEffector = $Armature/Skeleton3D/GodotIKLegIK/rightIKRoot/rightLegIKTarget
@onready var sideways_tilt_target: Marker3D = $Armature/Skeleton3D/SidewaysBodyTiltTarget
@onready var forwards_tilt_target: Marker3D = $Armature/Skeleton3D/ForwardBackwardBodyTiltTarget
@onready var mesh: MeshInstance3D = $Armature/Skeleton3D/char_lowpoly
@onready var forward_backward_body_tilt_target: Marker3D = $Armature/Skeleton3D/ForwardBackwardBodyTiltTarget
@onready var lean_grace_timer: Timer = $lean_grace_timer

@onready var LfootCast: RayCast3D = $Armature/Skeleton3D/CustomBoneAttachmentL/LFootRayCast3D
@onready var RfootCast: RayCast3D = $Armature/Skeleton3D/CustomBoneAttachmentR/RFootRayCast3D

@onready var fallRay: RayCast3D = $FallRayCast3D

@onready var player_fall_audio: AudioStreamPlayer3D = $AudioStreamPlayer3D_playerfall


@export var tilt_limit_back: float = -6.0
#@export var tilt_limit_forwards: float = 2.0

@export var tilt_limit_right: float = 2.5
@export var tilt_limit_left: float = -2.5
@export var tilt_recovery_lerp_weight = 0.008
var left_foot_stable: bool = true
var right_foot_stable: bool = true
var left_foot_on_ground: bool = true
var right_foot_on_ground: bool = true
var can_tilt: bool = true
var atLimit: bool = false
var fall_direction: String
var fallen: bool = false
var sprinting: bool = false
var sprint_stamina: float = 100.0
signal player_fall
signal player_tilt_side
signal player_tilt_back

func _ready() -> void:
	var ragdoll = get_tree().get_root().get_node("TestingMap/DemonRagdoll")
	#print(ragdoll)
	ragdoll.bones_sleep.connect(get_up)
	
func is_ground_angle_walkable(normal: Vector3):
	var difference = normal.dot(Vector3.UP)
	#print(difference)
	if (difference > 0.80):
		return true
	else:
		return false
	
func _handle_tilt(delta: float): 
	left_foot_stable = is_ground_angle_walkable(LfootCast.get_collision_normal())
	right_foot_stable = is_ground_angle_walkable(RfootCast.get_collision_normal())
	left_foot_on_ground = LfootCast.is_colliding()
	right_foot_on_ground = RfootCast.is_colliding()
	
	# recover balance if both feet are on the ground and the ground is even enough
	if (left_foot_on_ground and right_foot_on_ground and left_foot_stable and right_foot_stable):
		# TILT RECOVERY WEIGHT with HARD-CODED ZERO OUT POS
		sideways_tilt_target.position.y = lerp(sideways_tilt_target.position.y, 0.0, tilt_recovery_lerp_weight)
		forwards_tilt_target.position.z = lerp(forwards_tilt_target.position.z, -1.0, tilt_recovery_lerp_weight)
		#print("feet on ground")
		
	# make sure foot raycasts are always pointing downwards
	if (!left_foot_on_ground or !left_foot_stable) && can_tilt:
		#print("left foot off ground")

		if sideways_tilt_target.position.y < tilt_limit_left:
			sideways_tilt_target.position.y = tilt_limit_left
			fall_direction = "left"
			atLimit = true
		else:
			sideways_tilt_target.position.y -= tilt_speed * delta
			#center_of_mass.x -= mass_offset_speed
			atLimit = false
			
	

	if (!right_foot_on_ground or !right_foot_stable) && can_tilt:
		#print("right foot off ground")
		

		if sideways_tilt_target.position.y > tilt_limit_right:
			sideways_tilt_target.position.y = tilt_limit_right
			fall_direction = "right"
			atLimit = true
			
		else:
			sideways_tilt_target.position.y += tilt_speed * delta
			#center_of_mass.x += mass_offset_speed
			atLimit = false
			
			
			
	if (!right_foot_on_ground or !right_foot_stable and !left_foot_on_ground or !left_foot_stable) && can_tilt:
		# neither feet not on ground nor walkable ground angle
		#print(forwards_tilt_target.position.z)
		if forwards_tilt_target.position.z < tilt_limit_back:
			forwards_tilt_target.position.z = tilt_limit_back
			fall_direction = "backward"
			atLimit = true
			
		else:
			forwards_tilt_target.position.z -= tilt_speed*3 * delta
			#center_of_mass.x += mass_offset_speed
			atLimit = false
			
	emit_signal("player_tilt_side", sideways_tilt_target.position.y, tilt_limit_left, tilt_limit_right)
	emit_signal("player_tilt_back", forwards_tilt_target.position.z, tilt_limit_back)
	
	if atLimit:
		fall() # Turn on physics
		return
	
	# get_up is instead called through ragdoll "bones_sleep" signal
	#get_up()

func fall():
	#do once
	if (!fallen):
		var forward_dir = -global_transform.basis.z.normalized()
		var up_dir = fallRay.get_collision_normal().normalized() # terrains up dir
		emit_signal("player_fall", velocity, fall_direction, forward_dir, up_dir)
		player_fall_audio.play()

	fallen = true
	hide()

# reference to PhysicalBones root from signal
func get_up(root_ref):
	position = root_ref.position
	forward_backward_body_tilt_target.position.z = 0.0
	sideways_tilt_target.position.y = 0
	forwards_tilt_target.position.z = 0
	atLimit = false
	fallen = false
	can_tilt = false
	sprint_speed = after_fall_sprint_speed
	lean_grace_timer.start()
	#$stepTargetContainer.position = position
	
	left_target.force_foot_to_target()
	right_target.force_foot_to_target()
	left_target.step()
	right_target.step()
	
	show()
	
func _on_lean_grace_timer_timeout() -> void:
	print("timeout!")
	sprint_speed = lerp(after_fall_sprint_speed, normal_sprint_speed, 1)
	can_tilt = true
	
func _sprint(delta):
		sprinting = true
		if can_tilt:
			forward_backward_body_tilt_target.position.z -= sprint_tilt_speed * delta
			#print("postion ", forwards_tilt_target.position.z)
			if forward_backward_body_tilt_target.position.z < tilt_limit_back:
				fall_direction = "backward"
				atLimit = true
		
func _recover_sprint(delta):
		sprinting = false
		forward_backward_body_tilt_target.position.z = lerp(forward_backward_body_tilt_target.position.z, 0.0, tilt_recovery_lerp_weight)

func _handle_movement(delta):

	var input_dir = Input.get_vector("left", "right", "up", "down").normalized()
	var movement_vector = (Vector3(input_dir.x, 0, input_dir.y))
	#print(movement_vector)
	if Input.is_action_pressed("sprint"):
		_sprint(delta)
		velocity = velocity.lerp(movement_vector * sprint_speed, 0.5)
	else:
		_recover_sprint(delta)
		velocity = velocity.lerp(movement_vector * move_speed, 0.5)
	#print(velocity)
	
	# move rigid body collision along
	#translate(Vector3(input_dir.x, 0, input_dir.y) * move_speed * delta)
	
	
func _handle_rotation(delta):
	var look_dir = Input.get_vector("look_left", "look_right", "look_up", "look_down").normalized()
	var target_angle = atan2(look_dir.x, look_dir.y) - PI
	
	if (look_dir):
		rotation.y = lerp_angle(rotation.y, target_angle, turn_speed * delta)

func _physics_process(delta: float) -> void:
	if !fallen:
		#height setting with ik targets
		
		#var avg = (left_target.position + right_target.position) / 2
		var target_pos = Vector3(fallRay.get_collision_point().x, fallRay.get_collision_point().y + ground_offset, fallRay.get_collision_point().z)
		position.y = lerp(position.y, target_pos.y, 0.2)
		
		_handle_movement(delta)
		_handle_rotation(delta)
		_handle_tilt(delta)
		
		move_and_slide()
		
	
