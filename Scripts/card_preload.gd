extends Sprite
""" PRELOAD ALL CARDS HERE """
var card_detail_template = {
	title = 'card',
	description = 'description',
	display_details = 'aggressive: ',
	img = null,
	cost = '',
	move_dir = 'none',
	move_distance = 0,
	speed_change = 0,
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
	amount_per_deck = 0,
	count_towards_hand_limit = true,
	id = 0,
	index = 0
}

var deck_limit = 30
var deck_min = 15

# costs for our card cost algo which determines rarity
var move_cost = 5
var curve_cost = 20
var dig_cost = 15
var invincible_cost = 30
var jump_cost = 40 # per round in air
var aoe_cost = 10
var base_cost = 0
var projectile_cost = 25
var mine_cost = 45
var basic_unique_projectile_cost = 35
var speed_cost = 5
var buff_len_cost = 10
var buff_val_cost = 5
var redraw_cost = 40

## per deck ranges,
var six_per_deck = 5
var four_per_deck = 20
var three_per_deck = 35
var two_per_deck = 50
var one_per_deck = 65 # this is actually just anything more than two per deck
###

#########################################
### MOVEMENT
const move_right_1 = preload("res://Scenes/cards/card_move_right_1.tscn")
const move_right_2 = preload("res://Scenes/cards/card_move_right_2.tscn")
const move_up_1 = preload("res://Scenes/cards/card_move_up_1.tscn")
const move_up_2 = preload("res://Scenes/cards/card_move_up_2.tscn")
const move_left_1 = preload("res://Scenes/cards/card_move_left_1.tscn")
const move_left_2 = preload("res://Scenes/cards/card_move_left_2.tscn")
const move_down_1 = preload("res://Scenes/cards/card_move_down_1.tscn")
const move_down_2 = preload("res://Scenes/cards/card_move_down_2.tscn")

const curve_up_right_2 = preload("res://Scenes/cards/card_curve_up_right_2.tscn")
const curve_up_left_2 = preload("res://Scenes/cards/card_curve_up_left_2.tscn")
const curve_down_right_2 = preload("res://Scenes/cards/card_curve_down_right_2.tscn")
const curve_down_left_2 = preload("res://Scenes/cards/card_curve_down_left_2.tscn")
###

### WEAPON
const missile_1 = preload("res://Scenes/cards/card_missile_1.tscn")
const card_bomb_1 = preload("res://Scenes/cards/card_bomb_1.tscn")
const card_float_1 = preload("res://Scenes/cards/card_floater_mine.tscn")
const card_mine_1 = preload("res://Scenes/cards/card_mine_1.tscn")

###

### BONUS
const move_boost_1 = preload("res://Scenes/cards/card_move_boost_1.tscn")

###

### MISC
const hold_steady = preload("res://Scenes/cards/card_hold_steady.tscn")
const redraw = preload("res://Scenes/cards/card_redraw.tscn")
const recycle_1 = preload("res://Scenes/cards/card_recycle_1.tscn")
###

### JUMP
const jump_1 = preload("res://Scenes/cards/card_jump_1.tscn")
const jump_2 = preload("res://Scenes/cards/card_jump_2.tscn")
const jump_3 = preload("res://Scenes/cards/card_jump_3.tscn")
###


### SPEED
const speed_up_1 = preload("res://Scenes/cards/card_speed_up_1.tscn")
const speed_down_1 = preload("res://Scenes/cards/card_speed_down_1.tscn")
###

### Losing control
const unstable_right_1 = preload("res://Scenes/cards/card_unstable_right_1.tscn")
const unstable_right_2 = preload("res://Scenes/cards/card_unstable_move_right_2.tscn")
const unstable_left_1 = preload("res://Scenes/cards/card_unstable_move_left_1.tscn")
const unstable_left_2 = preload("res://Scenes/cards/card_unstable_move_left_2.tscn")
const unstable_up_1 = preload("res://Scenes/cards/card_unstable_move_up_1.tscn")
const unstable_up_2 = preload("res://Scenes/cards/card_unstable_move_up_2.tscn")
const unstable_down_1 = preload("res://Scenes/cards/card_unstable_move_down_1.tscn")
const unstable_down_2 = preload("res://Scenes/cards/card_unstable_move_down_2.tscn")
const unstable_speed_up_2 = preload("res://Scenes/cards/card_unstable_speed_up_2.tscn")

####


# evey single card for testing purposes
var total_deck = [unstable_speed_up_2, unstable_down_2, unstable_down_1, unstable_up_2, unstable_up_1,
				  unstable_left_2, unstable_left_1,
				  unstable_right_2, unstable_right_1, recycle_1, card_bomb_1, card_float_1, redraw, move_right_2, move_left_1, move_left_2,
				  move_right_1, hold_steady, card_mine_1, 
				  speed_up_1, speed_down_1, move_down_1, move_down_2,
				  move_up_1, move_up_2, missile_1, move_boost_1, jump_3, jump_2, jump_1,
				  curve_up_right_2, curve_up_left_2, curve_down_right_2, curve_down_left_2]
##


# for display to choose from when making a deck
var general_display_deck = [recycle_1, hold_steady, redraw,
							card_bomb_1, card_mine_1, missile_1, card_float_1,
							move_right_2, move_right_1, move_left_1, move_left_2,
							move_down_2, move_down_1, move_up_1, move_up_2,
							speed_up_1, speed_down_1, move_boost_1, jump_3, jump_2, jump_1,
							curve_up_right_2, curve_up_left_2, curve_down_right_2, curve_down_left_2]

# to take player choice and move into created deck and not remove from list above:
# 3 of each card for limit or 2 or 1 based on rarity
# emotion_processor, guard, guard, guard, examine, examine, examine, tough_question, tough_question, tough_question, question, question, question
# this is used async twice in 1 loop, this can not change in more than one spot
# this changes automatically before deck creation based on card rarity
var general_creation_deck = []

# everythin is in this deck twice because in thise case we do want potential to grab multiples
var losing_control_cards = [unstable_speed_up_2, unstable_speed_up_2,
							unstable_down_2, unstable_up_2,
							unstable_left_2, unstable_right_2,
							unstable_down_2, unstable_down_1, unstable_up_2,
							unstable_up_1, unstable_left_2, unstable_left_1,
							unstable_right_2, unstable_right_1]

# starting deck for playing
var general_deck = [card_mine_1, card_mine_1,
					recycle_1, recycle_1, card_bomb_1, card_bomb_1, redraw,
					move_boost_1, hold_steady,
					hold_steady, hold_steady, hold_steady,
					speed_up_1, speed_down_1,
					move_right_1, move_down_1, move_down_1, move_down_2, move_down_2,
					move_up_1, move_up_2, move_up_2, missile_1, missile_1,
					move_up_1, move_left_1, move_left_2, move_right_2]

var slick_deck = [hold_steady, hold_steady, move_up_1, move_up_1, 
				 move_down_1, move_down_1, move_down_1, move_up_1,
				 move_left_1, move_left_1, move_right_1,
				 move_right_1, speed_up_1, speed_up_1,
				 speed_down_1, speed_down_1, hold_steady, hold_steady,
				 missile_1, missile_1, move_down_2, move_left_2, move_up_2, move_right_2]

var tech_deck = [card_bomb_1, move_up_1, move_up_1, missile_1,
				 move_down_1, move_down_1, move_left_1, move_left_1, move_right_1,
				 move_right_1, speed_up_1, speed_down_1, recycle_1, redraw, redraw,
				 hold_steady, hold_steady, hold_steady, hold_steady, 
				 missile_1, move_left_2, move_right_2]

var raven_deck = [move_up_1, move_up_1, move_up_2, curve_up_left_2, curve_up_left_2,
				 curve_up_right_2, curve_up_right_2, curve_down_right_2, curve_down_right_2,
				curve_down_left_2, curve_down_left_2,
				 move_down_1, move_down_1, move_down_2, move_left_1, move_left_1,
				 move_right_1, jump_3, jump_2, jump_1, jump_1,
				 move_right_1, speed_up_1, speed_down_1,
				 hold_steady, hold_steady, hold_steady, missile_1, move_left_2, move_right_2]

var testing_deck = [card_bomb_1, card_bomb_1, card_bomb_1, move_left_1, move_right_1,
					move_down_1, move_up_1, card_mine_1, card_float_1]


var tutorial_deck_0 = [move_up_1, move_left_1, move_right_2]
var tutorial_deck_1 = [move_down_1, move_down_1, move_down_1]
var tutorial_deck_2 = [move_left_1, move_right_2, missile_1]
var tutorial_deck_3 = [move_left_2, speed_up_1, move_right_2]
var tutorial_deck_4 = [speed_up_1, speed_down_1, move_up_1]
var tutorial_deck_5 = [jump_1, jump_1, jump_1]
var tutorial_deck_6 = [unstable_left_2, unstable_down_2, unstable_speed_up_2]
var tutorial_deck_7 = [hold_steady, hold_steady, hold_steady]

var tutorial_0_expected_card = 'UP'
var tutorial_1_expected_card = 'DOWN'
var tutorial_2_expected_card = 'MISSILE'
var tutorial_3_expected_card = 'LEFT'
var tutorial_4_expected_card = 'SPEED DOWN'
var tutorial_5_expected_card = 'JUMP'
var tutorial_6_expected_card = 'SPEED UP'
var tutorial_7_expected_card = 'STEADY'

var instanced_tutorial_deck_0 = []
var instanced_tutorial_deck_1 = []
var instanced_tutorial_deck_2 = []
var instanced_tutorial_deck_3 = []
var instanced_tutorial_deck_4 = []
var instanced_tutorial_deck_5 = []
var instanced_tutorial_deck_6 = []
var instanced_tutorial_deck_7 = []


func set_preload_decks():
	for card in tutorial_deck_0:
		var c = card.instance()
		get_node('/root').add_child(c)
		instanced_tutorial_deck_0.append(c)
	for card in tutorial_deck_1:
		var c = card.instance()
		get_node('/root').add_child(c)
		instanced_tutorial_deck_1.append(c)
	for card in tutorial_deck_2:
		var c = card.instance()
		get_node('/root').add_child(c)
		instanced_tutorial_deck_2.append(c)
	for card in tutorial_deck_3:
		var c = card.instance()
		get_node('/root').add_child(c)
		instanced_tutorial_deck_3.append(c)
	for card in tutorial_deck_4:
		var c = card.instance()
		get_node('/root').add_child(c)
		instanced_tutorial_deck_4.append(c)
	for card in tutorial_deck_5:
		var c = card.instance()
		get_node('/root').add_child(c)
		instanced_tutorial_deck_5.append(c)
	for card in tutorial_deck_6:
		var c = card.instance()
		get_node('/root').add_child(c)
		instanced_tutorial_deck_6.append(c)
	for card in tutorial_deck_7:
		var c = card.instance()
		get_node('/root').add_child(c)
		instanced_tutorial_deck_7.append(c)


func return_unstable_card_string_to_preload(card_title):
	""" For 0 cost cards when losing control """
	if 'RIGHT 1' in card_title:
		return unstable_right_1
	if 'RIGHT 2' in card_title:
		return unstable_right_2
	if 'LEFT 1' in card_title:
		return unstable_left_1
	if 'LEFT 2' in card_title:
		return unstable_left_2
	if 'UP 1' in card_title:
		return unstable_up_1
	if 'UP 2' in card_title:
		return unstable_up_2
	if 'DOWN 1' in card_title:
		return unstable_down_1
	if 'DOWN 2' in card_title:
		return unstable_down_2
	if 'SPEED UP 2' in card_title:
		return unstable_speed_up_2


func return_card_string_to_preload(card_title):
	if 'CURVE UP RIGHT 2' in card_title:
		return curve_up_right_2
	if 'CURVE UP LEFT 2' in card_title:
		return curve_up_left_2
	if 'CURVE DOWN RIGHT 2' in card_title:
		return curve_down_right_2
	if 'CURVE DOWN LEFT 2' in card_title:
		return curve_down_left_2
	if 'RIGHT 1' in card_title and not 'CURVE' in card_title:
		return move_right_1
	if 'RIGHT 2' in card_title and not 'CURVE' in card_title:
		return move_right_2
	if 'HOLD STEADY' in card_title:
		return hold_steady
	if 'DOWN 1' in card_title and not 'SPEED' in card_title and not 'CURVE' in card_title:
		return move_down_1
	if 'DOWN 2' in card_title and not 'SPEED' in card_title and not 'CURVE' in card_title:
		return move_down_2
	if 'UP 1' in card_title and not 'SPEED' in card_title and not 'CURVE' in card_title:
		return move_up_1
	if 'UP 2' in card_title and not 'SPEED' in card_title and not 'CURVE' in card_title:
		return move_up_2
	if 'SPEED DOWN 1' in card_title:
		return speed_down_1
	if 'SPEED UP 1' in card_title:
		return speed_up_1
	if 'LEFT 1' in card_title and not 'CURVE' in card_title:
		return move_left_1
	if 'LEFT 2' in card_title and not 'CURVE' in card_title:
		return move_left_2
	if 'EXPLOSIVE MISSILE 1' in card_title:
		return card_bomb_1
	if 'MISSILE' in card_title and not 'EXPLOSIVE' in card_title:
		return missile_1
	if 'MOVE BOOST 3' in card_title:
		return move_boost_1
	if 'REDRAW' in card_title:
		return redraw
	if 'RECYCLE TERRAIN 5' in card_title:
		return recycle_1
	if 'FLOATER' in card_title:
		return card_float_1
	if 'MINE' in card_title:
		return card_mine_1
	if 'JUMP 1' in card_title:
		return jump_1
	if 'JUMP 2' in card_title:
		return jump_2
	if 'JUMP 3' in card_title:
		return jump_3
		
		

		
	print('*******')
	print('CARD ' + str(card_title) + 'NOT FOUND IN return_card_string_to_preload ' +\
		  ' in card_preload.gd, FIX')
	print('*******')
	get_tree().quit()
	return false



func set_card_costs_and_starting_decks(card):
	var cost = base_cost
	var amount_per_deck = 0
	if 'LOSING CONTROL' in card.description:
		return [0 - card.stability_bonus, amount_per_deck]
	for d in range(0, abs(card.move_distance)):
		cost += move_cost
	for s in range(0, abs(card.speed_change)):
		cost += speed_cost
	for bv in range(0, abs(card.buff_value)):
		cost += buff_val_cost
	for bl in range(0, abs(card.buff_length)):
		cost += buff_len_cost
	for aoe in range(0, abs(card.aoe)):
		cost += aoe_cost
	for j in range(0, abs(card.jump_air_time)):
		cost += jump_cost

	if 'projectile' in str(card.type):
		if 'MINE' in str(card.type):
			cost += mine_cost
		if 'FLOATER' in str(card.type) or 'EXPLOSIVE' in str(card.type):
			cost += basic_unique_projectile_cost
		cost += projectile_cost
	if 'redraw' in str(card.type):
		cost += redraw_cost

	if 'invincible' in str(card.type):
		cost += invincible_cost
	if 'dig' in str(card.type):
		cost += dig_cost
	if 'curve' in str(card.type):
		cost += curve_cost

	cost -= card.stability_bonus
	if cost <= six_per_deck:
		amount_per_deck = 6
	elif cost > six_per_deck and cost <= four_per_deck:
		amount_per_deck = 4
	elif cost > four_per_deck and cost <= three_per_deck:
		amount_per_deck = 3
	elif cost > three_per_deck and cost <= two_per_deck:
		amount_per_deck = 2
	elif cost > two_per_deck:
		amount_per_deck = 1
	else:
		print('cant find card cost: ' + str(cost))
	return [cost, amount_per_deck]


func _ready():
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
