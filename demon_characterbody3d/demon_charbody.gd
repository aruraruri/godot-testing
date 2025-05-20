extends CharacterBody3D
@export var move_speed: float = 5.0
@export var turn_speed: float = 1.0
@export var ground_offset: float = 0
@export var sprint_speed: float = 10.0
@export var tilt_speed: float = 30
@export var mass_offset_speed = 0.1
@onready var left_target: Marker3D = $leftLegIKTarget
@onready var right_target: Marker3D = $rightLegIKTarget
@onready var tilt_target: Marker3D = $Armature/Skeleton3D/bodyTiltTarget
@onready var mesh: MeshInstance3D = $Armature/Skeleton3D/char_lowpoly

@onready var LfootCast: RayCast3D = $Armature/Skeleton3D/LeftFootBoneAttachment3D/LFootRayCast3D
@onready var RfootCast: RayCast3D = $Armature/Skeleton3D/RightFootBoneAttachment3D/RFootRayCast3D


@export var tilt_limit_right: float = 6.4
@export var tilt_limit_left: float = -3.7
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
	if (difference < 0.5):
		return true
	else:
		return false
	
func _handle_tilt(delta: float):
	
	if (LfootCast.is_colliding() and RfootCast.is_colliding()):
		# TILT RECOVERY WEIGHT with HARD-CODED ZERO OUT POS
		tilt_target.position.y = lerp(tilt_target.position.y, 0.0, tilt_recovery_lerp_weight)
		#print("feet on ground")
	
	if (!LfootCast.is_colliding() or ground_angle_walkable(LfootCast.get_collision_normal())):
		#print("left foot off ground")
		if tilt_target.position.y < tilt_limit_left:
			tilt_target.position.y = tilt_limit_left
			fall_direction = -1
			atLimit = true
		else:
			tilt_target.position.y -= tilt_speed * delta
			#center_of_mass.x -= mass_offset_speed
			atLimit = false
			
	

	if (!RfootCast.is_colliding() or ground_angle_walkable(RfootCast.get_collision_normal())):
		#print("right foot off ground")
		
		if tilt_target.position.y > tilt_limit_right:
			tilt_target.position.y = tilt_limit_right
			fall_direction = 1
			atLimit = true
			
		else:
			tilt_target.position.y += tilt_speed * delta
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
	tilt_target.position.y = 1.214
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
		#height setting/seeing if at least one foot is on the ground
		if (LfootCast.is_colliding() or RfootCast.is_colliding()):
			var avg = (LfootCast.get_collision_point() + RfootCast.get_collision_point()) / 2
			var target_pos = avg
			position.y = lerp(position.y, target_pos.y, 0.1)
		else:
			print("feet not on ground")
			_apply_gravity(delta)
		
		
		_handle_movement(delta)
		_handle_rotation(delta)
		
		
		move_and_slide()
		
	_handle_tilt(delta)
