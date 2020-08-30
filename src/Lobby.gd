extends Control

var servers

func _ready():
	request_servers()
	Network.connect("connected",self,"load_level")
	
func request_servers():
	var httpRequest = HTTPRequest.new()
	add_child(httpRequest)
	httpRequest.connect("request_completed", self, "_server_request_completed",[httpRequest])
	var error = httpRequest.request(Global.lobby+"/servers",[],false,HTTPClient.METHOD_GET,"")
	if error != OK:
		push_error("Error during http request"+str(error))
		
func _server_request_completed(result, response_code, headers, body,httpRequest):
	httpRequest.queue_free()
	if response_code == 200:
		var json = JSON.parse(body.get_string_from_utf8())
		servers = json.result.success
	$ItemList.clear()
	for i in servers.size():
		$ItemList.add_item(str(servers[i].currentPlayers) +" Player(s)   ---    "+servers[i].name )
		$ItemList.set_item_metadata($ItemList.get_item_count() - 1, servers[i].id)
		
func _on_btnCreate_pressed():
	Network.create_server($edtPlayerName.text.left(15),$Sprite.frame,$edtServerName.text.left(15))
	#load_level()

func load_level():
	get_tree().change_scene("res://src/World.tscn")
	pass

func _on_btnJoin_pressed():
	var servers = $ItemList.get_selected_items()
	var id = $ItemList.get_item_metadata(servers[0])
	var httpRequest = HTTPRequest.new()
	add_child(httpRequest)
	httpRequest.connect("request_completed", self, "_ip_request_completed",[httpRequest])
	var error = httpRequest.request(Global.lobby+"/requestip/"+str(id),[],false,HTTPClient.METHOD_GET,"")
	if error != OK:
		push_error("Error during http request"+str(error))


func _ip_request_completed(result, response_code, headers, body,httpRequest):
	httpRequest.queue_free()
	if response_code == 200:
		var json = JSON.parse(body.get_string_from_utf8())
		var server = json.result.success
		Network.join_server($edtPlayerName.text.left(15),$Sprite.frame,server)
		#load_level()

		
func _on_HSlider_value_changed(value):
	$Sprite.frame = int(value)


func _on_RefreshTimer_timeout():
	request_servers()


func _on_ItemList_item_selected(index):
	$btnJoin.disabled = false


func _on_ItemList_nothing_selected():
	$btnJoin.disabled = true
