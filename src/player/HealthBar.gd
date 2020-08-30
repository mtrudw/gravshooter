extends Control

onready var health_under = $HealthUnder
onready var health_over = $HealthOver
onready var update_tween = $Tween

export (float) var max_health = 100

export (Color) var healty_color= Color.green
export (Color) var warn_color = Color.yellow
export (Color) var hurt_color = Color.red

export (float) var warn_value = 0.5
export (float) var hurt_value = 0.2

func _ready():
	health_under.max_value = max_health
	health_over.max_value = max_health

func update_health(value):
	if value != health_over.value:
		health_over.value = value
		update_tween.interpolate_property(health_under,"value",health_under.value,value,0.4,Tween.TRANS_SINE,Tween.EASE_IN_OUT,0.2)
		update_tween.start()
	
	_set_color(value)

func _set_color(value):
	if value < max_health*hurt_value:
		health_over.tint_progress = hurt_color
	elif value < max_health*warn_value:
		health_over.tint_progress = warn_color
	else:
		health_over.tint_progress = healty_color
	
