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


@export var tilt_limit_right: float = 6.4
@export var tilt_limit_left: float = -6.4
var atLimit: bool = false

var fallen: bool = false
signal player_fall

func _ready() -> void:
	var ragdoll = get_tree().get_root().get_node("TestingMap/DemonRagdoll")
	print(ragdoll)
	ragdoll.bones_sleep.connect(get_up)
	
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
		fall() # Turn on physics
		return
	
	# get_up is instead called through ragdoll "bones_sleep" signal
	#get_up()

func fall():
	#do once
	if (!fallen):
		emit_signal("player_fall", velocity)

	fallen = true
	mesh.hide()
	
func get_up():
	tilt_target.position.y = 0.0
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

func _physics_process(delta: float) -> void:
	if !fallen:
		var avg = (left_target.position + right_target.position) / 2
		var target_pos = avg
		#charbody3d.position.y = lerp(charbody3d.position.y, target_pos.y, (move_speed) * delta)
	
		
		#height setting
		position.y = lerp(position.y, target_pos.y, (move_speed) * delta)
		_handle_movement(delta)
		_handle_rotation(delta)
		
		
		move_and_slide()
		
	_handle_tilt(delta)
