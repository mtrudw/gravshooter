extends RigidBody2D

export (float) var lifeTime = 10
export (float) var damage = 10.0
export (int) var player = -1
export (bool) var splash = true
var last_collision_pos = 0
var explosion = null
var hurtbox = null
func _ready():
	$killTimer.start(lifeTime)
	if splash:
		explosion = preload("res://src/Weapons/Explosion.tscn").instance()
		hurtbox = preload("res://src/Weapons/HurtBox.tscn").instance()
		
sync func explode(pos):
	get_tree().get_root().add_child(explosion)
	explosion.global_position = pos
	explosion.boom()
	get_tree().get_root().call_deferred("add_child",hurtbox)
	hurtbox.damage = damage
	hurtbox.player = player
	hurtbox.global_position = pos
	queue_free()

func _on_killTimer_timeout():
	queue_free()
	if splash:
		if is_network_master():
			rpc("explode",global_position)
		
func _on_Bullet_body_entered(body):
	if !splash:
		if body is Player:
			body.damage(damage,player)
		var impact = preload("res://src/Weapons/ImpactSound.tscn").instance()
		get_tree().get_root().add_child(impact)
		impact.global_position = global_position
		impact.get_node("AudioStreamPlayer2D").play()
		queue_free()
	else:
		if is_network_master():
			rpc("explode",global_position)

