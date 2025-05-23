extends SpotLight3D


@export var flicker_chance: float = 0.1 
@export var flicker_duration: float = 0.2
@onready var omni_light_3d_eyes: OmniLight3D = $"../OmniLight3D_Eyes"
@onready var right_eye: MeshInstance3D = $"../RightEye"
@onready var left_eye: MeshInstance3D = $"../LeftEye"
@onready var blink_audio: AudioStreamPlayer3D = $"../AudioStreamPlayer3D_playereyes"


var flickering: bool = false
var flicker_timer: float = 0.0


func _process(delta):
	if flickering:
		flicker_timer += delta
		if flicker_timer >= flicker_duration:
			visible = true
			omni_light_3d_eyes.visible = true
			right_eye.show()
			left_eye.show()
			flickering = false
			flicker_timer = 0.0
	else:
		if randf() < flicker_chance * delta:
			blink_audio.play()
			visible = false
			omni_light_3d_eyes.visible = false
			right_eye.hide()
			left_eye.hide()
			flickering = true
