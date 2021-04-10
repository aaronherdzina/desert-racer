extends Sprite

var savable = {
	col = 6,
	row = 34,
	player = {
		character = 'Slick',
		hp = 1,
		current_deck = [],
		game_deck = [],
		hand_limit = 2,
		stability_max = 200,
		stability_lost_threshold = 20, # hardcode at 20% of max
		decks = [],
		move_distance_mod = 0,
		step_min = 2,
		speed_mod = 0,
		air_time_bonus = 1,
		invincible_time_bonus = 0, # additional steps for invincible cards
		dig_bonus = 1,
		starting_speed = 4,
		unique_cards = [],
		custom_deck = []
	},
	stats = {
		objects_hit = 0,
		objects_shot = 0,
		obstacles_jumped = 0,
		enemy_objects_hit = 0,
		projectiles_shot = 0,
		projectiles_hit = 0,
		enemies_hit = 0,
		enemies_shot = 0,
		steps_taken_in_level = 0,
		times_lost_control = 0,
		steps_out_of_stability = 0,
		all_time_steps = 0,
		rounds = 0,
		enemy_hazard_hit = 0,
		hazard_hit = 0,
		
		 # every time a card is played if we don't already find it here add it,
		# as a dict and count up 1, so we can also keep a tally, then we can give the favorites
		most_used_cards = []
	},
	had_tutorial = false,
	tutorial_idx = 0
}

var round_stats = {
		objects_hit = 0,
		rounds = 0,
		objects_shot = 0,
		obstacles_jumped = 0,
		enemy_objects_hit = 0,
		projectiles_shot = 0,
		projectiles_hit = 0,
		enemies_hit = 0,
		enemies_shot = 0,
		steps_taken_in_level = 0,
		times_lost_control = 0,
		steps_out_of_stability = 0,
		all_time_steps = 0,
		enemy_hazard_hit = 0,
		hazard_hit = 0,
		
		 # every time a card is played if we don't already find it here add it,
		# as a dict and count up 1, so we can also keep a tally, then we can give the favorites
		most_used_cards = []
}

var char_slick = {
	character = 'SLICK',
	hp = 2,
	current_deck = [],
	hand_limit = 3,
	stability_max = 250,
	stability_lost_threshold = 65, # hardcode at 25% of max
	decks = [],
	move_distance_mod = 0,
	step_min = 4,
	air_time_bonus = 0,
	invincible_time_bonus = 0, # additional steps for invincible cards
	dig_bonus = 0, # 
	speed_mod = 1,
	starting_speed = 5,
	locked = false,
	unique_cards = [card_preload.move_boost_1, card_preload.move_boost_1,
				   card_preload.curve_up_right_2, card_preload.curve_up_left_2]
}

var char_tech = {
	character = 'TECH',
	hp = 2,
	current_deck = [],
	hand_limit = 4,
	stability_max = 150,
	stability_lost_threshold = 35, # hardcode at 25% of max
	decks = [],
	move_distance_mod = 0,
	step_min = 2,
	air_time_bonus = 0,
	invincible_time_bonus = 0, # additional steps for invincible cards
	dig_bonus = 0,
	speed_mod = 0,
	starting_speed = 2,
	locked = false,
	unique_cards = [card_preload.recycle_1, card_preload.redraw, card_preload.card_mine_1,
					card_preload.hold_steady, card_preload.hold_steady]
}

var char_raven = {
	character = 'RAVEN',
	hp = 1,
	current_deck = [],
	hand_limit = 3,
	stability_max = 200,
	stability_lost_threshold = 50, # hardcode at 25% of max
	decks = [],
	move_distance_mod = 0,
	step_min = 3,
	air_time_bonus = 1,
	invincible_time_bonus = 0, # additional steps for invincible cards
	dig_bonus = 1,
	speed_mod = 0,
	starting_speed = 4,
	locked = true,
	unique_cards = [card_preload.jump_3, card_preload.jump_2, card_preload.jump_2, card_preload.jump_1]
}

var char_dozer = {
	character = 'DOZER',
	hp = 3,
	current_deck = [],
	hand_limit = 2,
	stability_max = 300,
	stability_lost_threshold = 50, # hardcode at 25% of max
	decks = [],
	move_distance_mod = 0,
	step_min = 3,
	air_time_bonus = 0,
	invincible_time_bonus = 1, # additional steps for invincible cards
	dig_bonus = 1,
	speed_mod = 0,
	starting_speed = 3,
	locked = true,
	unique_cards = []
}

var char_list = [char_slick, char_tech, char_raven]
var char_idx = 0

var global_shadow_modulate_max = .15
var global_shadow_modulate_min = .05
var shadow_pos_x_global_mode = .002
var shadow_pos_y_global_mode = .0002
var dark_red_mod = Color(1, .2, .2, 1)
var light_red_mod = Color(1, .5, .5, 1)
var tile_occupied_color = Color(.4, .4, .4, 1)
var cant_play_card_color = Color(.5, .3, .3, .6)

var screen_cap_array = []
var can_capture = true
var playing_screen_cap = false


var four_col_y = 478
var five_col_y = 429
var six_col_y = 380
var seven_col_y = 331
var eight_col_y = 282
var nine_col_y = 233
var ten_col_y = 184

var tutorial_0_message_1 = 'Welcome to ' + str(main.game_name).capitalize() + '! \n' + \
						  'Your goal is to race to the end safely! '+\
						  'Speaking of which... Quick, use W-A-S-D or the arrow keys on your keyboard, '+\
						  'or the left joystick on a game pad to highlight the card \'MOVE UP 1\' then press (A)/[Enter] to play the card'
var tutorial_0_message_2 = 'Great job!'
var tutorial_1_message_1 = 'Well that helped... for now..\nNow as you can see the obstacle in front of you will hit you next turn if you don\'t move! ' +\
						  '\n\nChoose the card \'MOVE DOWN 1\' to avoid the next obstacle. The tile you end up in will be highlighted with a blue square.'
var tutorial_1_message_2 = 'Perfect!'
var tutorial_2_message_1 = 'Outside of the tutorial you have a limited time or a card will be played for you and you\'ll lose the time you have each turn to pick a card. That can get out of control quick so don\'t waste time. Don\'t worry we can still make it. You drew a \'MISSILE\' card. Standard \'MISSILE\' cards spawn a projectile in your tile and advance forward up to the current speed durning each turn. ' +\
						  'Once it makes contact with something it will explode destroying whatever it hits.\n Play a \'MISSILE\' card.'
var tutorial_2_message_2 = 'Keep it up!'
var tutorial_3_message_1 = 'Behind this popout you\'ll find the speed everything is moving at, the steps/tiles you\'ve traveled and your step/tile goal, and your remaing stability which is the cost of playing cards. I think you know what card to play now. I wish we had a better option but \'MOVE LEFT 2\' is the safest card to play.'
var tutorial_3_message_2 = 'Let\'s see what we get next..'
var tutorial_4_message_1 = 'We\'re cutting it close... Between turns when selecting a card you can see a preview of what is going to happen next turn depneding on the card you have highlighted. '+\
                           'Highlight each card to see where you and the objects will end up. The tile each object stops on is red. There isn\'t really a better option here so choose the \'SPEED DOWN 1\' card to last at least 1 more turn'
var tutorial_4_message_2 = 'Here we go...'
var tutorial_5_message_1 = 'Perfect! Just what we need. It\'s risky but we can choose one of the JUMP 1 cards and soar over obstacles. You\'ll need to be careful since you can\'t play a move card while in the air.'
var tutorial_5_message_2 = 'Excellent!'
var tutorial_6_message_1 = 'All cards cost \'Stability\' to play, which you can see behind this text box outside of the tutorial or right now after you play a card. When run out you draw \'UNSTABLE\' cards automatically no matter what\'s in your deck. ' +\
						  'Looks like we lucked out again. We can\'t move because we\'re in the air, but if we speed up we\'ll be fine.\nChoose the \'SPEED UP\' card.'
var tutorial_6_message_2 = 'Close call!'
var tutorial_7_message_1 = 'You did it! You drew some standard \'HOLD STEADY\' cards which help restore some stability. Play one and cruise to victory!'
var tutorial_7_message_2 = 'We\'re in the clear now!'

"""
var tutorial_0_expected_card = 'UP'
var tutorial_1_expected_card = 'DOWN'
var tutorial_2_expected_card = 'MISSILE'
var tutorial_3_expected_card = 'LEFT'
var tutorial_4_expected_card = 'SPEED DOWN'
var tutorial_5_expected_card = 'JUMP'
var tutorial_6_expected_card = 'CURVE'
var tutorial_7_expected_card = 'SPEED UP'

"""


var tutorial_0_tile_idx = Vector2(8, 4)
var tutorial_1_tile_idx = Vector2(13, 3)
var tutorial_2_tile_idx = Vector2(18, 4)
var tutorial_3_tile_idx = Vector2(24, 4)
var tutorial_4_tile_idx = Vector2(24, 3)
var tutorial_5_tile_idx = Vector2(26, 4)
var tutorial_6_tile_idx = Vector2(26, 5)
var tutorial_7_tile_idx = Vector2(29, 4)

func play_screen_cap_anim():
	if can_capture:
		can_capture = false
	print('screen_cap_array len ' + str(len(screen_cap_array)))
	playing_screen_cap = true
	while playing_screen_cap:
		for sc in screen_cap_array:
			if not playing_screen_cap:
				clear_captures()
				return
			if main.checkIfNodeDeleted(sc) == false:
				sc.rotation = (3.14159)
				sc.flip_h = true
				sc.set_scale(Vector2(.6, .6))
				sc.position = Vector2(750, 300)
				sc.z_index = 4000
				sc.visible = true
				var timer = Timer.new()
				timer.set_wait_time(.09)
				timer.set_one_shot(true)
				main.addToParent(timer)
				timer.start()
				yield(timer, "timeout")
				timer.queue_free()
				if main.checkIfNodeDeleted(sc) == false:
					sc.visible = false
		var timer = Timer.new()
		timer.set_wait_time(.5)
		timer.set_one_shot(true)
		main.addToParent(timer)
		timer.start()
		yield(timer, "timeout")
		timer.queue_free()
				
	clear_captures()


func clear_captures():
	main.clear_array(screen_cap_array)
	screen_cap_array = []
	can_capture = true



func display_effects(path):
	var node = get_node(path)
	var valX = node.position.x
	var valY = node.position.y
	var x_limit = node.position.x
	var y_limit = node.position.y
	var mag = 10
	while get_node("/root").has_node("level"):
		if node and main.checkIfNodeDeleted(node) == false:
			var imgX = node.get_children()[0].position.x
			var imgY = node.get_children()[0].position.y
			for img in node.get_children():
				if node and main.checkIfNodeDeleted(node) == false:
					img.visible = true if rand_range(-1, 1) >= -.9 else false
					if img.visible:
						img.position.x = rand_range(-imgX - mag, imgX + mag)
						img.position.y = rand_range(-imgY - mag, imgY + mag)
					var timer = Timer.new()
					timer.set_wait_time(.02)
					timer.set_one_shot(true)
					get_node("/root").add_child(timer)
					timer.start()
					yield(timer, "timeout")
					timer.queue_free()


func get_capture():
	# start screen capture
	if not can_capture:
		return
	var capture = get_viewport().get_texture().get_data()
	#get_tree().get_root().get_viewport().queue_screen_capture()
	yield(get_tree(), "idle_frame")
	#yield(get_tree(), "idle_frame")
	
	# get screen capture
	#var capture = get_viewport().get_screen_capture()
	
	# make texture
	var texture = ImageTexture.new()
	texture.create(capture.get_width(), capture.get_height(), capture.get_format())
	texture.set_data(capture)
	
	# add sprite with screen capture texture
	var sprite = Sprite.new()
	sprite.set_texture(texture)
	sprite.visible = false
	main.addToParent(sprite, null, true)
	screen_cap_array.append(sprite)


func get_neighboring_tiles(current_tile, directions=[]):
	var l = get_node("/root/level")
	var tile_index = current_tile.index
	var t_len = len(l.level_tiles)
	var potential_tiles = []
	var mod = 1
	if main.checkIfNodeDeleted(l) == false and main.checkIfNodeDeleted(current_tile) == false:
		for dir in directions:
			if 'left' == dir:
				if current_tile.row > 0 and tile_index - 1 - mod > 0 and tile_index - 1 - mod < t_len:
					potential_tiles.append(l.level_tiles[tile_index - 1 - mod])
			elif 'left_up' == dir:
				if current_tile.row > 0 and current_tile.col > 0 and\
				   tile_index - meta.savable.row - 1 - mod > 0 and tile_index - mod - meta.savable.row - 1 < t_len:
					potential_tiles.append(l.level_tiles[tile_index - 1 - mod - meta.savable.row])
			elif 'up' == dir:
				if current_tile.col > 0 and tile_index - mod - meta.savable.row > 0 and tile_index - mod - meta.savable.row < t_len:
					potential_tiles.append(l.level_tiles[tile_index - mod - meta.savable.row])
			elif 'right_up' == dir:
				if current_tile.col > 0 and current_tile.row < meta.savable.row-1 and tile_index - meta.savable.row + 1 - mod > 0 and tile_index - meta.savable.row + 1 - mod < t_len:
					potential_tiles.append(l.level_tiles[tile_index + 1 - mod - meta.savable.row])
			elif 'right' == dir:
				if current_tile.row < meta.savable.row-1 and tile_index + 1 - mod > 0 and tile_index + 1 - mod < t_len:
					potential_tiles.append(l.level_tiles[tile_index + 1 - mod])
			elif 'right_down' == dir:
				if current_tile.row < meta.savable.row-1 and current_tile.col < meta.savable.col-1 and tile_index + meta.savable.row + 1 - mod> 0 and tile_index + meta.savable.row + 1 - mod < t_len:
					potential_tiles.append(l.level_tiles[tile_index + 1 + meta.savable.row - mod])
			elif 'down' == dir:
				if current_tile.col < meta.savable.col-1 and tile_index + meta.savable.row > 0 and tile_index + meta.savable.row - mod < t_len:
					potential_tiles.append(l.level_tiles[tile_index + meta.savable.row - mod])
			elif 'left_down' == dir:
				if current_tile.row > 0 and current_tile.col < meta.savable.col-1 and tile_index + meta.savable.row - 1  - mod > 0 and tile_index + meta.savable.row - 1 - mod < t_len:
					potential_tiles.append(l.level_tiles[tile_index + meta.savable.row - 1 - mod])
	return potential_tiles

func add_round_stats_to_all_time():
	meta.savable.stats.objects_hit += round_stats.objects_hit
	meta.savable.stats.rounds += round_stats.rounds
	meta.savable.stats.objects_shot += round_stats.objects_shot
	meta.savable.stats.enemy_objects_hit += round_stats.enemy_objects_hit
	meta.savable.stats.projectiles_shot += round_stats.projectiles_shot
	meta.savable.stats.projectiles_hit += round_stats.projectiles_hit
	meta.savable.stats.enemies_hit += round_stats.enemies_hit
	meta.savable.stats.enemies_shot += round_stats.enemies_shot
	meta.savable.stats.steps_taken_in_level += round_stats.steps_taken_in_level
	meta.savable.stats.times_lost_control += round_stats.times_lost_control
	meta.savable.stats.steps_out_of_stability += round_stats.steps_out_of_stability
	meta.savable.stats.hazard_hit += round_stats.hazard_hit
	meta.savable.stats.enemy_hazard_hit += round_stats.enemy_hazard_hit


func clear_round_stat():
	round_stats.objects_hit = 0
	round_stats.rounds = 0
	round_stats.hazard_hit = 0
	round_stats.enemy_hazard_hit = 0
	round_stats.objects_shot = 0
	round_stats.enemy_objects_hit = 0
	round_stats.projectiles_shot = 0
	round_stats.projectiles_hit = 0
	round_stats.enemies_hit = 0
	round_stats.enemies_shot = 0
	round_stats.steps_taken_in_level = 0
	round_stats.times_lost_control = 0
	round_stats.steps_out_of_stability = 0


func handle_card_stats(card_dict):
	# card_dict example: {'title': card.title, 'times_played': 1}
	var card_present = false
	
	if len(round_stats.most_used_cards) <= 0:
		round_stats.most_used_cards.append(card_dict)
	if len(savable.stats.most_used_cards) <= 0:
		savable.stats.most_used_cards.append(card_dict)
		
	for card in round_stats.most_used_cards:
		if card['title'] == card_dict['title']:
			card_dict['times_played'] += 1
			card_present = true
			break

	for card in savable.stats.most_used_cards:
		if card['title'] == card_dict['title']:
			card_dict['times_played'] += 1
			card_present = true
			break
	
	if not card_present:
		round_stats.most_used_cards.append(card_dict)
	if not card_present:
		savable.stats.most_used_cards.append(card_dict)


func set_player_keys(new_char, set_meta=false):
	if set_meta: # set the given char to the meta
		savable.player.character = new_char.character
		savable.player.current_deck = new_char.current_deck 
		savable.player.hand_limit = new_char.hand_limit
		savable.player.stability_max = new_char.stability_max
		savable.player.stability_lost_threshold = new_char.stability_lost_threshold
		savable.player.move_distance_mod = new_char.move_distance_mod
		savable.player.step_min = new_char.step_min
		savable.player.speed_mod = new_char.speed_mod
		savable.player.starting_speed = new_char.starting_speed
		savable.player.locked = new_char.locked
		savable.player.unique_cards = new_char.unique_cards
		savable.air_time_bonus = new_char.air_time_bonus
		savable.invincible_time_bonus = new_char.invincible_time_bonus
		savable.dig_bonus = new_char.dig_bonus
	else:
		new_char.character = savable.player.character
		new_char.current_deck = savable.player.current_deck
		new_char.hand_limit = savable.player.hand_limit
		new_char.stability_max = savable.player.stability_max
		new_char.stability_lost_threshold = savable.player.stability_lost_threshold
		new_char.decks = savable.player.decks
		new_char.move_distance_mod = savable.player.move_distance_mod
		new_char.step_min = savable.player.step_min
		new_char.speed_mod = savable.player.speed_mod
		new_char.starting_speed = savable.player.starting_speed
		new_char.locked = savable.player.locked
		new_char.unique_cards = savable.player.unique_cards
		new_char.air_time_bonus = savable.air_time_bonus
		new_char.invincible_time_bonus = savable.invincible_time_bonus
		new_char.dig_bonus = savable.dig_bonus


func animate_cycle_card(card, right=true, in_battle=false, first_card=false):
	if main.checkIfNodeDeleted(card) == true: return
	var anim_time = 10
	var anim_frame_delay = .001
	var scale_change = .2
	var pos = card.position
	var s = card.get_scale()
	if card.details.id == 0:
		if 'create' in main.current_menu:
			if get_node('/root').has_node('create_deck_scene'):
				get_node('/root/create_deck_scene').yielding = true
		card.details.id = 1
		for i in range(0, anim_time):
			if main.checkIfNodeDeleted(card) == false:
				if i < anim_time / 2:
					if in_battle:
						card.position.x += 150 if right else -150
					else:
						card.position.x += 40 if right else -40
					card.set_scale(Vector2(s.x - scale_change, s.y - scale_change))
				else:
					card.set_scale(Vector2(s.x - (scale_change *1.4), s.y - (scale_change * 1.4)))
					if in_battle:
						card.visible = false 
					elif card.position.x > pos.x and right:
						card.position.x -= 50 
					elif not right and card.position.x < pos.x:
						card.position.x += 50 
				var timer = Timer.new()
				timer.set_wait_time(anim_frame_delay)
				timer.set_one_shot(true)
				get_node("/root").add_child(timer)
				timer.start()
				yield(timer, "timeout")
				timer.queue_free()
		if main.checkIfNodeDeleted(card) == false:
			card.position = pos
			card.details.id = 0
			if first_card:
				card.set_scale(game.highlight_card_size)
			else:
				card.set_scale(s)
		var t = Timer.new()
		t.set_wait_time(.25)
		t.set_one_shot(true)
		get_node("/root").add_child(t)
		t.start()
		yield(t, "timeout")
		t.queue_free()
		if 'create' in main.current_menu:
			if get_node('/root').has_node('create_deck_scene'):
				get_node('/root/create_deck_scene').yielding = false
		if in_battle and main.checkIfNodeDeleted(card) == false:
			card.visible = false


func _ready():
	main.loadGameData()
	savable.player.decks.append(card_preload.general_deck)
	savable.player.decks.append(card_preload.slick_deck)
	savable.player.decks.append(card_preload.tech_deck)
	savable.player.decks.append(card_preload.raven_deck)

	if len(meta.savable.player.custom_deck) > 0:
		meta.savable.player.decks.append(meta.savable.player.custom_deck)


func handle_opening_tutorial():
	var tp = main.instancer(main.text_popup)
	turn.step_timer_max = 250
	tp.get_node("Label").set_text("Welcome to " + main.game_name.replace('_', ' ') +"!\n your goal"
								  + " is to survive as long as you can while you escape enemies and dodge hazards.")
	var timer = Timer.new()
	timer.set_wait_time(10)
	timer.set_one_shot(true)
	main.addToParent(timer, null, false)
	timer.start()
	yield(timer, "timeout")
	timer.queue_free()
	tp.get_node("Label").set_text(
		"Your vehicles are high tech but the technology is still mostly unknown and it doesn't always do"
		 + " what you want. Your goal is to reach your distance goal shown in the upper right.")
	var timer2 = Timer.new()
	timer2.set_wait_time(10)
	timer2.set_one_shot(true)
	main.addToParent(timer2, null, false)
	timer2.start()
	yield(timer2, "timeout")
	timer2.queue_free()
	tp.get_node("Label").set_text(
		"Every turn everything moves" + 
		" an amount equal to your current speed, the faster you go the faster you can beat the level" +
		" but the harder it will be to dodge hazards.")
	var timer3 = Timer.new()
	timer3.set_wait_time(10)
	timer3.set_one_shot(true)
	main.addToParent(timer3, null, false)
	timer3.start()
	yield(timer3, "timeout")
	timer3.queue_free()
	tp.get_node("Label").set_text(
		"Every turn you draw cards and have a set amount of time to make a decision. This time altering technology isn't perfect though, if you run out of time a card is played" +
		" for you."
	)
	var timer4 = Timer.new()
	timer4.set_wait_time(7)
	timer4.set_one_shot(true)
	main.addToParent(timer4, null, false)
	timer4.start()
	yield(timer4, "timeout")
	timer4.queue_free()
	tp.get_node("Label").set_text(
		"Every card costs 'stability' and if you hit 0 you'll have less time to play cards. Press left or right to cycle cards and press start/enter to play them")
	var timer5 = Timer.new()
	timer5.set_wait_time(7)
	timer5.set_one_shot(true)
	main.addToParent(timer5, null, false)
	timer5.start()
	yield(timer5, "timeout")
	timer5.queue_free()
	tp.get_node("Label").set_text(
		"Get Ready!")
	var timer6 = Timer.new()
	timer6.set_wait_time(4)
	timer6.set_one_shot(true)
	main.addToParent(timer6, null, false)
	timer6.start()
	yield(timer6, "timeout")
	timer6.queue_free()
	savable.had_tutorial = true
	main.saveGameData()
	tp.queue_free()

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
