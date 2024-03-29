extends Node2D
""" Standard Attack Card """
var selected = false
var details = {
	title = 'card',
	description = 'description',
	display_details = 'aggressive: ',
	img = null,
	cost = '',
	move_dir = 'none',
	move_distance = 0,
	speed_change = 0,
	amount_per_deck = 0,
	rarity = 0, # set val when start game in algo and save to cards, this gives us how many
				# per deck and how easy to find in meta game
	in_deck = 'current',
	type = [],
	card_count = 0,
	buff_length = 0,
	buff_value = 0,
	buff_type = '',
	invincible_steps = 0,
	invincible_rounds = 0,
	dig_amount = 0,
	jump_air_time = 0,
	aoe = 0,
	stability_bonus = 0,
	count_towards_hand_limit = true,
	id = 0,
	index = 0
}

var remote_set = false

func set_display_details():
	get_node("title").set_text(str(details.title))
	get_node("description").set_text(str(details.description))
	get_node("cost").set_text('+'+str(abs(details.cost)))
	if details.img != null:
		get_node("Sprite").set_texture(details.img)


func set_unique_details():
	details.title = 'HOLD STEADY'
	details.move_distance = 0
	details.stability_bonus = 15
	details.move_dir = 'none'
	details.type = ['none']
	details.description = 'Hold Steady and don\'t move'
	var costs = card_preload.set_card_costs_and_starting_decks(details)
	details.cost = costs[0]
	details.amount_per_deck = costs[1]
	set_display_details()


func on_play_additional_detail():
	pass


func on_play():
	details.played = true
	game.resolve_card(self.details)


func on_leave_play():
	pass


func on_turn_start():
	pass


func on_turn_end():
	pass


func unplayed():
	pass


func _ready():
	if not remote_set:
		set_unique_details()

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass


func _on_Button_pressed():
	game.mouse_card_select(self, self.details)


func _on_Button_mouse_entered():
	game.mouse_card_hover(self)


func _on_Button_mouse_exited():
	game.mouse_card_exit_hover(self)
