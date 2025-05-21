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
@onready var leftIk: SkeletonIK3D = $CharacterBody3D/Armature/Skeleton3D/leftLegIK


@onready var physical_bone_simulator_3d: PhysicalBoneSimulator3D = $"RigidCollisionShape3D/Armature/Skeleton3D/This_is_not_enabled(ragdoll)"

func _ready():
	physical_bone_simulator_3d.physical_bones_start_simulation()
	

	
