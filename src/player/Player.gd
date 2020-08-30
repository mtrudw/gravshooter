extends KinematicBody2D

class_name Player

export var speed = 800
export var acceleration = 0.8
export var friction = 0.02
export var gravity = 1200
export var jump = -12800000000
export (float) var max_health = 100

onready var health = max_health
var velocity = Vector2.ZERO
var grav_vector = Vector2(0,1)
var vControl = Vector2(1,0)
var cam_angle = 0
var active_weapon = 0
var own_id = 0
var own_name = ""
var need_camera_flip = false
var spawn_pos : Vector2
puppet var slave_position = Vector2.ZERO
puppet var slave_velocity = Vector2.ZERO
puppet var slave_gravity = Vector2.ZERO
puppet var slave_health = 0

signal dead
var dead = false

var DeadBody = preload("res://src/player/DeadBody.tscn")

func _ready():
	randomize()
	if is_network_master():
		rset('slave_health',max_health)
	$HealthBar.max_health = max_health
	$HealthBar.update_health(max_health)

func networkUpdate():
	rset_unreliable('slave_position',global_position)
	rset('slave_velocity',velocity)
	rset('slave_gravity',grav_vector)
	rset('slave_health',health)
	
func flipGravity(direction):
	if direction.y != 0:
		grav_vector = Vector2(0,direction.y)
	else:
		grav_vector = direction.normalized()
	match grav_vector:
		Vector2(1,0):
			$PlayerCam/HUD/ColorRect/Direction.frame = 1
		Vector2(-1,0):
			$PlayerCam/HUD/ColorRect/Direction.frame = 3
		Vector2(0,1):
			$PlayerCam/HUD/ColorRect/Direction.frame = 2
		Vector2(0,-1):
			$PlayerCam/HUD/ColorRect/Direction.frame = 0
	rpc("_flipSprite",grav_vector)
			
sync func _flipSprite(vect):
	$Sprite.look_at((global_position+10*vect.rotated(-PI/2)))
	need_camera_flip = true

sync func _flipPlayer():
	$Sprite.rotation = 0.0
	self.look_at((global_position+10*grav_vector.rotated(-PI/2)))
	need_camera_flip = false
	
func _input(event):
	if is_network_master():
		if Input.is_action_just_pressed("next_weapon"):
			Global.data.guns[active_weapon].shots_fired = $Weapon.shots_fired
			active_weapon = (active_weapon+1)%Global.data.guns.size()
			$Weapon.load_from_data(Global.data.guns[active_weapon])
		if Input.is_action_just_pressed("prev_weapon"):
			Global.data.guns[active_weapon].shots_fired = $Weapon.shots_fired
			active_weapon = active_weapon - 1 if active_weapon > 0 else Global.data.guns.size()-1
			$Weapon.load_from_data(Global.data.guns[active_weapon])
		if Input.is_action_pressed("ShowStats"):
			show_stats()
		if Input.is_action_just_released("ShowStats"):
			hide_stats()
		$PlayerCam/HUD/ColorRect/WeaponIndicator.frame = Global.data.guns[active_weapon].frame
		
func show_stats():
	$PlayerCam/HUD/Stats/ItemList.clear()
	$PlayerCam/HUD/Stats/ItemList.add_item("Player")
	$PlayerCam/HUD/Stats/ItemList.add_item("Kills")
	$PlayerCam/HUD/Stats/ItemList.add_item("Deaths")
	for peer_id in Network.players:
		$PlayerCam/HUD/Stats/ItemList.add_item(Network.players[peer_id].name)
		$PlayerCam/HUD/Stats/ItemList.add_item(str(Network.players[peer_id].kills))
		$PlayerCam/HUD/Stats/ItemList.add_item(str(Network.players[peer_id].deaths))
	$PlayerCam/HUD/Stats.show()
	
func hide_stats():
	$PlayerCam/HUD/Stats.hide()
func _master_physics(delta):
		var xInput =  Input.get_action_strength("ui_right")*Vector2(1,0) - Input.get_action_strength("ui_left")*Vector2(1,0)
		var yInput =  Input.get_action_strength("ui_down")*Vector2(0,1) - Input.get_action_strength("ui_up")*Vector2(0,1)
		var vInput = xInput+yInput
		if Input.is_action_pressed("flip_grav"):
			if vInput.length() > 0.1:
				flipGravity(vInput)
		else:
			vControl = xInput.x * grav_vector.rotated(-PI/2)
			var velocity_projected = velocity*grav_vector.rotated(-PI/2)
			if (vControl.length() > 0.1):
				velocity = velocity - grav_vector.y*velocity_projected + grav_vector.x*velocity_projected 
				velocity += velocity_projected.linear_interpolate(vControl.normalized()*speed,acceleration)
			elif is_on_floor() or is_on_wall():
				velocity = velocity - grav_vector.y*velocity_projected + grav_vector.x*velocity_projected 
				velocity += velocity_projected.linear_interpolate(Vector2.ZERO,friction)
		

		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity += jump*grav_vector
		else:
			velocity += grav_vector*gravity*delta
		networkUpdate()

func _physics_process(delta):
	if is_network_master():		
		_master_physics(delta)
		$PlayerCam/HUD/ColorRect/AmmoCounter.text = str($Weapon.magazine - $Weapon.shots_fired)
		if not $Weapon.reloading:
			$PlayerCam/HUD/ColorRect/ProgressBar.max_value = $Weapon/FireTimer.wait_time
			$PlayerCam/HUD/ColorRect/ProgressBar.value = $Weapon/FireTimer.time_left
		else:
			$PlayerCam/HUD/ColorRect/ProgressBar.max_value = $Weapon/ReloadTimer.wait_time
			$PlayerCam/HUD/ColorRect/ProgressBar.value = $Weapon/ReloadTimer.time_left
	else:
		global_position = slave_position
		velocity = slave_velocity
		grav_vector = slave_gravity
		health = slave_health

	velocity=move_and_slide(velocity,-1*grav_vector)
#	var phi = self.get_angle_to(global_position+grav_vector)-PI/2
#	cam_angle = lerp(cam_angle,phi,0.5)
#	self.rotate(cam_angle)
	if need_camera_flip and is_on_floor():
		rpc("_flipPlayer")
	$HealthBar.update_health(health)
	if get_tree().is_network_server():
		Network.update_position(int(name),global_position)
		
func init(name,start_position,skin,id):
	own_name = name
	$NameTag.text = name
	global_position = start_position
	$Sprite.frame=skin
	own_id =id
	$Weapon.player = own_id
	$Weapon.load_from_data(Global.data.guns[active_weapon])

func set_spawn(pos):
	spawn_pos = pos


sync func _die(player):
	$Sprite.visible = false
	$Weapon.visible = false
	$HealthBar.visible = false
	$NameTag.visible = false
	$PlayerCollision.set_deferred('disabled',true)
	set_physics_process(false)
	$Weapon.set_physics_process(false)
	var dead_body = DeadBody.instance()
	get_tree().get_root().add_child(dead_body)
	dead_body.get_node("Sprite").frame = randi()%3
	dead_body.global_position = global_position
	if is_network_master():
		Network.print_message(Network.players[player].name +" killed " + own_name)
		$RespawnTimer.start()
	
func toggle_menu():
	$PlayerCam/HUD/GameMenu.visible = not $PlayerCam/HUD/GameMenu.visible
	
sync func _respawn():
	health = max_health
	if is_network_master():
		global_position = spawn_pos
		rset('slave_position',spawn_pos)
		rset('slave_health',health)
		dead = false
	$Sprite.set_deferred("visible", true)
	$Weapon.set_deferred("visible", true)
	$HealthBar.set_deferred("visible", true)
	$NameTag.set_deferred("visible", true)
	$PlayerCollision.disabled = false
	set_physics_process(true)
	$Weapon.set_physics_process(true)
	
remote func show_banner(text):
	if is_network_master():
		$PlayerCam/HUD/KillLabel.text = text
		$PlayerCam/HUD/MsgTimer.start()

func _set_health(value,player):
	health = clamp(value,0,max_health)
	rpc_unreliable('_hit_effects')
	if health == 0 and not dead:
		emit_signal("dead")
		dead = true
		rpc('_die',player)
		Network.register_kill(player,Network.own_id)
		Network.banner_to(player, "You killed "+Network.self_data.name)
		show_banner(Network.players[player].name + " killed you")
		for i in Global.data.guns.size():
			Global.data.guns[i].shots_fired = 0
	
sync func _hit_effects():
	if $ParticleStopTimer.is_stopped():
		$CPUParticles2D.emitting = true
		$ParticleStopTimer.start()
	
func damage(amount,player):
	if is_network_master() and (player != own_id):
		_set_health(health - amount,player)

func _on_RespawnTimer_timeout():
	rpc("_respawn")
	
remote func print_message(message):
	$PlayerCam/HUD/Messages.text += message + "\n"


func _on_MsgTimer_timeout():
	$PlayerCam/HUD/KillLabel.text = ""


func _on_ParticleStopTimer_timeout():
	$CPUParticles2D.emitting = false
	$ParticleStopTimer.stop()
	
	
