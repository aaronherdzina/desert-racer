extends Node2D


var c_scale = Vector2(.18, .18)
var x_buffer = 125
var y_buffer = 210
var cols = 5
var rows = 11

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass


func show_next_deck():
	for n in get_tree().get_nodes_in_group("shown_deck_card"):
		if main.checkIfNodeDeleted(n) == false:
			n.visible = false
			n.queue_free()
	var column = 0
	var row = 0
	for card in main.menu_list[main.menu_idx]:
		row += 1
		var c = main.instancer(card)
		c.visible = true
		c.z_index = 1000
		c.add_to_group("remove_on_game_start")
		c.add_to_group("shown_deck_card")
		c.set_scale(c_scale)
		c.position = get_node("hand_pos_1").global_position
		if row % rows == 0:
			row = 1
			column += 1
		c.position.x += x_buffer * row
		c.position.y += y_buffer * column
	if main.menu_idx == 0:
		get_node("Label").set_text("GENERAL DECK")
	elif main.menu_idx == 1:
		get_node("Label").set_text("SLICK'S DECK")
	elif main.menu_idx == 2:
		get_node("Label").set_text("TECH'S DECK")
	elif main.menu_idx == 3:
		get_node("Label").set_text("RAVEN'S DECK")
	else:
		var count = main.menu_idx - 2
		get_node("Label").set_text("Custom Deck " + str(count))
		
