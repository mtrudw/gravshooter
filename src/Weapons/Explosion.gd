extends Node2D


func _ready():
	pass # Replace with function body.

func boom():
	$DebrisBig.emitting = true
	$DebrisSmall.emitting = true
	$FireOuter.emitting = true
	$FireInner.emitting = true
	$Sound.play()
	$killTimer.start()
	


func _on_killTimer_timeout():
	queue_free()
