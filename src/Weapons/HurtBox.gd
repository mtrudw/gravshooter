extends Area2D

export (float) var damage = 5.0
export (bool) var timed = false
export (float) var effect_time = 0.1
export (int) var player = 0
export (int) var gun = 0

signal hitPlayer

func _ready():
	$killTimer.start(effect_time)


func _on_HurtBox_body_entered(body):
	if body is Player:
		body.damage(damage,player)
	if body.is_in_group("Destructible"):
		body.destroy(damage,global_position)



func _on_killTimer_timeout():
	queue_free()
