extends Node2D

var player
func _ready():
	get_tree().connect('network_peer_disconnected', self, '_on_player_disconnected')
	get_tree().connect('server_disconnected', self, '_on_server_disconnected')
	randomize()
	player = preload("res://src/player/Player.tscn").instance()
	player.name = str(get_tree().get_network_unique_id())
	player.set_network_master(get_tree().get_network_unique_id())
	get_tree().get_root().add_child(player)
	var player_data = Network.self_data
	player.init(player_data.name,player_data.position,player_data.skin,get_tree().get_network_unique_id())
	player.connect("dead",self,"send_random_spawn")
	
func _on_player_disconnected(id):
	get_tree().get_root().get_node(str(id)).queue_free()
	
func _on_server_disconnected():
	get_tree().change_scene("res://src/Lobby.tscn")
	
func send_random_spawn():
	var point = randi() % $Map/SpawnPoints.get_child_count()
	player.set_spawn($Map/SpawnPoints.get_child(point).global_position)

func _input(event):
	if Input.is_action_just_released("ui_cancel"):
		player.toggle_menu()
