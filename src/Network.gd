extends Node


const MAX_PLAYERS = 8

onready var client = Client
var players = { }
var self_data = {name = '',position=Vector2(0,0),skin = 0,kills = 0, deaths = 0}
var own_id = 1
var server_id = 0
var pingTimer = null
var lobby : String
var server = false
var servername = 'test'
signal connected

func _ready(): 
	client.connect("lobby_joined", self, "_lobby_joined")
	client.connect("lobby_sealed", self, "_lobby_sealed")
	client.connect("connected", self, "_connected")
	client.connect("disconnected", self, "_disconnected")
	client.rtc_mp.connect("peer_connected", self, "_on_player_connected")
	client.rtc_mp.connect("peer_disconnected", self, "_on_player_disconnected")
	client.rtc_mp.connect("server_disconnected", self, "_on_server_disconnected")
	client.rtc_mp.connect("connection_succeeded", self, "_connected_to_server")
	
func _process(delta):
	client.rtc_mp.poll()
	
func _connected(id):
	pass
	#print_debug("Signaling server connected with ID: %d" % id)
	

func _disconnected():
	pass
	#print_debug("Signaling server disconnected: %d - %s" % [client.code, client.reason])


func _lobby_joined(lobby):
	#print_debug("Joined lobby %s" % lobby)
	self.lobby = lobby
	if server:
		emit_signal("connected")
		register_server_to_lobby()

func _lobby_sealed():
	#print_debug("Lobby has been sealed")
	pass
	
func create_server(player_name,skin,server_name ):
	self_data.name = player_name
	self_data.skin = skin
	players[1] = self_data
	client.start(Global.matchmaker,"")
	server = true
	self.servername = server_name
	
	
func join_server(player_name,skin,server):
	self_data.name = player_name
	self_data.skin = skin
	client.start(Global.matchmaker, server)
	
	
func _connected_to_server():
	#print_debug("connected")
	emit_signal("connected")
	own_id =get_tree().get_network_unique_id() 
	players[own_id] = self_data
	rpc("_send_player_info",own_id,self_data)

	
remote func _send_player_info(id,info):
	players[id] = info
	var new_player = preload("res://src/player/Player.tscn").instance()
	new_player.name = str(id)
	new_player.set_network_master(id)
	new_player.get_node("PlayerCam").queue_free()
	new_player.remove_child(new_player.get_node("PlayerCam"))
	get_tree().get_root().add_child(new_player)
	new_player.init(info.name,info.position,info.skin,id)
	#get_tree().get_root().get_node(str(own_id)).print_message(info.name + " joined the game")

	
remote func _request_player_info(request_from_id, player_id):
	if get_tree().is_network_server():
		rpc_id(request_from_id, '_send_player_info', player_id, players[player_id])
		
func update_position(id,position):
	players[id].position = position
	
func _on_player_disconnected(id):
	get_tree().get_root().get_node(str(own_id)).print_message(players[id].name + " left the game")
	players.erase(id)
	if get_tree().is_network_server():
		_player_left_lobby()

func close():
	client.stop()
	get_tree().network_peer = null
	get_tree().get_root().get_node(str(own_id)).queue_free()
	get_tree().get_root().get_node(str(1)).queue_free()
	
func _on_player_connected(connected_player_id):
	var local_player_id = get_tree().get_network_unique_id()
	if not(get_tree().is_network_server()):
		rpc_id(1, '_request_player_info', local_player_id, connected_player_id)
	else:
		_player_joined_lobby()

func _on_server_disconnected():
	get_tree().get_root().get_node(str(own_id)).queue_free()
	get_tree().get_root().get_node(str(1)).queue_free()
	get_tree().network_peer = null
	
func print_message(message,rcv = false):
	if not  get_tree().is_network_server() and not rcv:
		rpc_id(1,'_send_message',message)
		return
	elif get_tree().is_network_server():
		rpc('_send_message',message)
	get_tree().get_root().get_node(str(own_id)).print_message(message)

remote func _send_message(message):
	print_message(message,true)

func register_server_to_lobby():
	var httpRequest = HTTPRequest.new()
	get_tree().get_root().add_child(httpRequest)
	httpRequest.connect("request_completed", self, "_server_create_request_completed",[httpRequest])
	var error = httpRequest.request(Global.lobby+"/servers",[],false,HTTPClient.METHOD_POST,'{"name":"'+servername+'","map":"default","lobby":"'+lobby+'"}')
	if error != OK:
		push_error("Error during http request"+str(error))

func _server_create_request_completed(result, response_code, headers, body,httpRequest):
	if response_code == 200:
		var json = JSON.parse(body.get_string_from_utf8())
		server_id = int(json.result.success)
		pingTimer = Timer.new()
		get_tree().get_root().add_child(pingTimer)
		pingTimer.wait_time = 5.0
		pingTimer.connect("timeout",self,"_on_PingTimer_timeout")
		pingTimer.start()
	httpRequest.queue_free()

func _ping_request_completed(result, response_code, headers, body,httpRequest):
	if response_code == 200:
		pass
	httpRequest.queue_free()
	
func _on_PingTimer_timeout():

	var httpRequest = HTTPRequest.new()
	get_tree().get_root().add_child(httpRequest)
	httpRequest.connect("request_completed", self, "_ping_request_completed",[httpRequest])
	var error = httpRequest.request(Global.lobby+"/ping/"+str(server_id),[],false,HTTPClient.METHOD_GET,"")
	if error != OK:
		push_error("Error during http request"+str(error))
		
func _player_joined_lobby():
	var httpRequest = HTTPRequest.new()
	get_tree().get_root().add_child(httpRequest)
	httpRequest.connect("request_completed", self, "_ping_request_completed",[httpRequest])
	var error = httpRequest.request(Global.lobby+"/playerjoin/"+str(server_id),[],false,HTTPClient.METHOD_GET,"")
	if error != OK:
		push_error("Error during http request"+str(error))
		
func _player_left_lobby():
	var httpRequest = HTTPRequest.new()
	get_tree().get_root().add_child(httpRequest)
	httpRequest.connect("request_completed", self, "_ping_request_completed",[httpRequest])
	var error = httpRequest.request(Global.lobby+"/playerleave/"+str(server_id),[],false,HTTPClient.METHOD_GET,"")
	if error != OK:
		push_error("Error during http request"+str(error))
		
remote func show_banner(text):
	get_tree().get_root().get_node(str(own_id)).show_banner(text) 

func banner_to(id,text):
	rpc_id(id,"show_banner",text)

remote func _register_kill(killer,killed):
	players[killer].kills += 1
	players[killed].deaths += 1
	if get_tree().is_network_server():
		rpc("_register_kill", killer,killed)
func register_kill(killer,killed):
	if not get_tree().is_network_server():
		rpc_id(1,"_register_kill",killer,killed)
	else:
		_register_kill(killer,killed)
