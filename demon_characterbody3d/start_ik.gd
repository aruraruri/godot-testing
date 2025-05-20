@tool

extends SkeletonIK3D

func _ready():
	start()
	
func fall():
	stop()
	
func get_up():
	start()
