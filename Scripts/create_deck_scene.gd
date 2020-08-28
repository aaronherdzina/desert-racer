extends Node2D
""" NOTES ON DECK CREAION: We instance cards from card_preload.general_display_deck into all_instanced_cards...
    to show 1 of all cards. When they choose a card we find a match in cards_for_deck which had 3 of every card...
	instanced from card_preload.general_creation_deck. This way we can just show 1 of each and not remove any from...
	the display deck At the same time a card and we have a instanced cards to display actual count in created deck
	and deck to choose from, when a card is chosen we add the uninstanced card to current_deck_for_game which is the...
	acutal deck and is instanced into the player's current_deck on battle start"""
	
	# TLDR: instance decks from card_preload to display cards to choose from and cards chosen..
	#.. different to display actually card count in created deck and 1 per card in display to choose from
	# when card is chosen also add uninstaced match into current_deck_for_game which is used for gameplay


## KNOWN issues, right now because we have a bunch of duping nodes (multiples of same cards)
## display deck doesn't actually show more than 1 of each unique kind

var all_instanced_cards = [] # use these to ref for player and to choose frome
var current_deck_display = [] # keep choices from cards_for_deck here
var current_deck_for_game = [] # keep choices from cards_for_deck here
var cards_for_deck = [] # take these to put into deck so not removing from all_instanced_cards
var show_first_card = true
var focused_size = Vector2(.34, .34)
var unfocused_size = Vector2(.23, .23)
const HIGHLIGHT_COLOR = Color(1, 1, .5, 1)
const DEFAULT_COLOR = Color(1, 1, 1, 1)
var in_deck = false
var yielding = false
var x_buffer = 220

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass


func get_deck_stats():
	pass


func spawn_cards():
	generate_creation_deck()
	for card in card_preload.general_display_deck:
		var c = main.instancer(card)
		all_instanced_cards.append(c)
		c.position = Vector2(-1000, -1000)
		c.visible = false
	#	c.position = get_node("card_container").position
		c.z_index = 100
		if show_first_card:
			c.z_index = 110
	for c in card_preload.general_creation_deck:
		cards_for_deck.append(c)
		c.position = Vector2(-1000, -1000)
		c.visible = true

	main.menu_list = all_instanced_cards
	main.menu_idx = 0


func check_limit(list, expected_card):
	var card_count = 0
	for card in list:
		if expected_card.details.title == card.details.title:
			card_count += 1

	if card_count >= expected_card.details.amount_per_deck:
		print('too many ' + str(expected_card.details.title) + ' in deck')
		return [false, card_count]
	return [true, card_count]


func generate_creation_deck():
	var hold_card_instances = []
	card_preload.general_creation_deck = []
	
	for c in card_preload.total_deck:
		var card = main.instancer(c)
		hold_card_instances.append(card)
	for c in hold_card_instances:
		print('c ' + str(c))
		for a in range(0, c.details.amount_per_deck):
			card_preload.general_creation_deck.append(c)



func move_card_to_deck(list, idx):
	if len(current_deck_for_game) < card_preload.deck_limit:
		for c in range(0, len(cards_for_deck)):
			cards_for_deck[c].modulate = DEFAULT_COLOR
			cards_for_deck[c].set_scale(unfocused_size)
			if cards_for_deck[c].details.title == list[idx].details.title:
				var limit_details = check_limit(current_deck_display, list[idx])
				if limit_details[0]:
					if not 'Node' in str(cards_for_deck[c]):
						return false
					# cards_for_deck is the instanced version of card_preload.general_creation_deck
					# THESE SHOULD STAY IN SYNC/ORDER AND THERE IS NO ISSUE
					print('added ' + str(cards_for_deck[c].details.title) + ' to display deck')
					#cards_for_deck[c].modulate = HIGHLIGHT_COLOR 
					var card_instance = main.instancer(card_preload.return_card_string_to_preload(
													cards_for_deck[c].details.title)
												)
					card_instance.add_to_group("remove_from_create")
					current_deck_display.append(card_instance)
					current_deck_for_game.append(card_preload.return_card_string_to_preload(
													card_preload.general_creation_deck[c].details.title)
												)
					cards_for_deck[c].visible = false
					cards_for_deck[c].z_index = 555 + c
					cards_for_deck[c].set_scale(unfocused_size)
					cards_for_deck[c].details.card_count = limit_details[1] + 1
					cards_for_deck[c].position = get_node("deck_container").global_position
					break
				else:
					if main.master_sound: main.master_sound.get_node("no_effect").play()
					if main.master_sound: main.master_sound.get_node("no_effect").play()
		#main.validate_menu_idx(idx, list, 'right')
		return false
	else:
		if main.master_sound: main.master_sound.get_node("no_effect").play()
		if main.master_sound: main.master_sound.get_node("no_effect").play()
		return true


func adjust_focus(list, idx, right=true):
	var card_count = 0
	var total_count = 0
	var display_count = 0
	var buffer = 20
	var starting_pos = get_node("card_container").global_position
	var starting_deck_pos = get_node("deck_container").global_position
	var titles = []
	for card in current_deck_display:
		titles.append(card.details.title)
	print('current_deck_display ' + str(titles))
	for card in current_deck_display:
		display_count += 1
		#card.position.x = (starting_pos.x + (display_count * buffer)) - 300
		if idx < len(list) and card.name != list[idx].name:
			total_count += 1
			card.z_index = 100 + total_count
			card.set_scale(unfocused_size)
			card.visible = true
			card.modulate = DEFAULT_COLOR
			card.get_node('description').visible = false
		else:
			card.z_index = 500
			card.set_scale(focused_size)
			card.visible = true
			card.modulate = DEFAULT_COLOR
			card.get_node('description').visible = true
		if idx < len(list) and card.details.title == list[idx].details.title:
			card_count += 1
	for card in all_instanced_cards:
		if idx < len(list) and card.name != list[idx].name:
			card.z_index = 100
			card.visible = true
			card.modulate = DEFAULT_COLOR
			card.set_scale(unfocused_size)
			card.get_node('description').visible = false
		else:
			card.z_index = 500 
			card.visible = true
			card.modulate = DEFAULT_COLOR
			card.set_scale(focused_size)
			card.get_node('description').visible = true
	
	var last_card = null
	var next_card = null
	var current_card = null
	if list == all_instanced_cards:
		if len(all_instanced_cards) - 1 >= 0:
			last_card = all_instanced_cards[len(all_instanced_cards) - 1]
		if len(all_instanced_cards) > 0:
			next_card = all_instanced_cards[0]
		if idx - 1 >= 0 and idx - 1 < len(all_instanced_cards):
			last_card = all_instanced_cards[idx - 1]
		if idx + 1 >= 0 and idx + 1 < len(all_instanced_cards):
			next_card = all_instanced_cards[idx + 1]
		if len(all_instanced_cards) > 0:
			current_card = all_instanced_cards[idx]
		if next_card: next_card.position = Vector2(starting_pos.x + x_buffer, starting_pos.y)
		if last_card: last_card.position = Vector2(starting_pos.x - x_buffer, starting_pos.y)
		if current_card: current_card.position = starting_pos
	else:
		if len(current_deck_display) - 1 >= 0:
			last_card = current_deck_display[len(current_deck_display) - 1]
		if len(current_deck_display) > 0:
			next_card = current_deck_display[0]
		if idx - 1 >= 0 and idx - 1 < len(current_deck_display):
			last_card = current_deck_display[idx - 1]
		if idx + 1 >= 0 and idx + 1 < len(current_deck_display):
			next_card = current_deck_display[idx + 1]
		if idx >= 0 and idx < len(current_deck_display):
			current_card = current_deck_display[idx]
		if next_card: next_card.position = Vector2(starting_deck_pos.x + x_buffer, starting_deck_pos.y)
		if last_card: last_card.position = Vector2(starting_deck_pos.x - x_buffer, starting_deck_pos.y)
		if current_card: current_card.position = starting_deck_pos
	if next_card:
		next_card.visible = true
		next_card.z_index = 200 
		next_card.set_scale(unfocused_size)
	if last_card: 
		last_card.visible = true
		last_card.z_index = 200
		last_card.set_scale(unfocused_size)
	if current_card: current_card.visible = true
	
	if main.menu_list == all_instanced_cards or main.menu_list == current_deck_display:
		for card in main.menu_list:
			if card != next_card and card != last_card and card != current_card:
				card.visible = false
	if idx < len(list):
		get_node("card_count").set_text(str(card_count) + '/' + str(list[idx].details.amount_per_deck))
		get_node("card_id").set_text(str(list[idx].details.card_count))
	get_node("deck size").set_text("DECK SIZE: " + str(len(current_deck_display)) + "/" + str(card_preload.deck_limit))
	get_node("min deck size").set_text("MINIMUM DECK SIZE: " + str(card_preload.deck_min))


func return_to_menu():
	if not yielding:
		if len(current_deck_for_game) >= card_preload.deck_min:
			meta.savable.player.custom_deck = current_deck_for_game
			meta.savable.player.decks.append(meta.savable.player.custom_deck)
		for c in all_instanced_cards:
			if not main.checkIfNodeDeleted(c):
				c.queue_free()
		for c in cards_for_deck:
			if not main.checkIfNodeDeleted(c):
				c.queue_free()
		main.clear_array(all_instanced_cards)
		main.clear_array(cards_for_deck)
		main.clear_array(current_deck_display)
		
		self.queue_free()
