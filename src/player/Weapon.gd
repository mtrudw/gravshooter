extends Node2D

export (float) var fireRate = 3.0
export (float, 0 ,1) var accuracy = 0.8
export (float) var velocity = 800
export (float) var damage = 5
export (bool) var splash = false
export (float) var splashRadius = 10
export (bool) var splashOnContact = true
export (float) var lifeTime = 0.8
export (int) var player = -1
export (int) var ammo = 1
export (int) var magazine = 30
export (float) var reloadTime = 0.0
export (int) var shots = 1
export (bool) var eject_shell = false
export (bool) var eject_mag = false

var shots_fired = 0
var reloading = false

var Bullet = preload("res://src/Weapons/Bullet.tscn")
var Eject = preload("res://src/player/Ejectable.tscn")
func _ready():
	randomize()
	
func _physics_process(delta):
	if is_network_master():
		var mousepos = get_global_mouse_position()
		rpc_unreliable('_point_gun',mousepos)
		if Input.is_action_pressed("shoot") and $FireTimer.is_stopped():
			if shots_fired < magazine and not reloading:
				for i in shots:
					rpc('_shoot',mousepos,$Sprite/ShootyBit.global_position,(1-accuracy) * (randf()*PI/4 - PI/8))
				shots_fired += 1
				rpc_unreliable('_shot_effects')
				$FireTimer.start(1/fireRate)
			else: 
				rpc('_reload')
		if Input.is_action_pressed("reload"):
			rpc('_reload')
			
sync func _reload():
	if $ReloadTimer.is_stopped():
		$ReloadTimer.start(reloadTime)
		reloading = true
		$ReloadSound.play()
		if eject_mag:
			var shell = Eject.instance()
			add_child(shell)
			shell.get_node("Sprite").frame=1
			shell.global_position = $Sprite/AmmoEject.global_position

sync func _point_gun(aim_position):
	$Sprite.look_at(aim_position)
	if (int(abs($Sprite.rotation_degrees))%360 > 90) and (int(abs($Sprite.rotation_degrees))%360 < 270):
		$Sprite.flip_v = true
	else:
		$Sprite.flip_v = false
		
sync func _shoot(aim_position,weapon_position,jitter):
	var bullet = Bullet.instance()
	bullet.lifeTime = lifeTime
	bullet.damage = damage
	bullet.player = player
	bullet.splash = splash
	bullet.get_node("Sprite").frame=ammo
	add_child(bullet)
	bullet.global_position = weapon_position
	var trajectory = (aim_position-weapon_position).normalized()
	trajectory = trajectory.rotated(jitter)
	bullet.look_at(aim_position)
	bullet.apply_impulse(Vector2.ZERO,bullet.mass*velocity * trajectory)
	$GunSound.playing = true


sync func _shot_effects():
	if eject_shell:
		var shell = Eject.instance()
		add_child(shell)
		shell.get_node("Sprite").frame=0
		shell.global_position = $Sprite/AmmoEject.global_position
		shell.apply_central_impulse(Vector2(0,-30-60*randf()))

func _on_FireTimer_timeout():
	$FireTimer.stop()
	
func _on_ReloadTimer_timeout():
	$ReloadTimer.stop()
	shots_fired = 0
	reloading = false
	
func load_from_data(data):
	rpc("_load_from_data",data)
	
sync func _load_from_data(data):
	fireRate = data.rate
	accuracy = data.accuracy
	velocity = data.velocity
	damage = data.damage
	lifeTime = data.lifetime
	ammo = data.bullet
	splash = data.splash
	magazine = data.magazine
	reloadTime = data.reloadTime
	shots = data.shots
	shots_fired = data.shots_fired
	eject_mag = data.eject_mag
	eject_shell = data.eject_ammo
	$ReloadTimer.stop()
	reloading = false
	var audio_file = data.sound

	var sfx = load(audio_file) 
	sfx.set_loop(false)
	$GunSound.stream = sfx

	audio_file = data.reload_sound
	var rsfx = load(audio_file) 
	rsfx.set_loop(false)
	$ReloadSound.stream = rsfx

	$Sprite.frame =  data.frame






