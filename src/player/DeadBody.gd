extends RigidBody2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	$killTimer.start()
	



func _on_killTimer_timeout():
	queue_free()
