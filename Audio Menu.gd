extends Control






func _on_TextureButton_pressed():
	$ColorRect.visible = not $ColorRect.visible
	$ColorRect/VBoxContainer/MasterVol.value = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("master"))
	$ColorRect/VBoxContainer/MusicVol.value = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("music"))
	$ColorRect/VBoxContainer/SoundVol.value = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("sounds"))




func _on_MasterVol_value_changed(value):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("master"),value)



func _on_MusicVol_value_changed(value):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("music"),value)


func _on_SoundVol_value_changed(value):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("sounds"),value)
