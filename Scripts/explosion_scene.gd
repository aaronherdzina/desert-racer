extends Node2D

var removal_timer = 5

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass

func _process(delta):
	if removal_timer > 0:
		removal_timer -= delta
	if removal_timer <= 0:
		queue_free()
