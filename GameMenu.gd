extends Control



func _on_Button_pressed():
	Network.close()
	get_tree().change_scene("res://src/Lobby.tscn")
	


func _on_Button2_pressed():
	self.hide()
