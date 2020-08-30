extends Sprite

var game_delta = 0
var object_chance = 50
var default_object_chance = 50
var default_object_chance_low = 25
var default_object_chance_high = 65
var player_move_dir = 'right'
var player_move_speed = 0
var preview_player_move_speed = 0
var preview_player_move_dir = 'right'
var draw_visual_delay = 1
var discard_deck = []
var added_deck = []
var card_container = []
var removal_deck = []
var hand = []
var hand_idx = 0
var in_preview = false
var card_hand_size = Vector2(.25, .25)
var highlight_card_size = Vector2(.35, .35)
var card_x_buffer = 225
var moving_sun = false
var level_over = false
var level_won = false
var player_lost_control = false
var regen_on_obj = false
var regen_on_enm = false
var regen_on_projectile = false
var regen_val = 0

var obj_row_block_chance = 10
var enm_projectile_chance = 20
var enm_bomb_projectile_chance = 20
var spawn_enm_chance = 20
var enms_per_turn = 1
var objs_per_turn = 2

var global_move_buff = 0
var global_speed_buff = 0

var active_buffs = []

var player_stability = 0

var object_limit = 10
var enemy_limit = 7

var set_finish_tiles = false
var set_finish_col_idx = 0

var finish_tile_color = Color(.95, .95, 1, .3)

var player_continue_tutorial = true
var in_tutorial = false
var use_tutorial_deck = false
var handling_tutorial_messages = false

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass


func set_character_and_cart():
	var selected_char = meta.char_list[meta.char_idx]
	meta.set_player_keys(selected_char, true)


func apply_buffs(type, value, length):
	var buff = {
		'type': type,
		'val': value,
		'length': length,
		'active': true
	}
	active_buffs.append(buff)


func check_and_remove_debuffs(remove_specific=false):
	""" And all active buffs to holding array, clear global array and add back
		re-loop and remove/apply buffs so we can stack but also keep accurate
	"""
	var hold_buffs = []
	global_move_buff = 0
	global_speed_buff = 0
	regen_on_obj = false
	regen_on_enm = false
	regen_on_projectile = false
	if remove_specific:
		for b in active_buffs:
			if 'type' in b and b['type'] != remove_specific:
				hold_buffs.append(b)
	else:
		for b in active_buffs:
			if 'length' in b and b['length'] <= 0 and\
			   'active' in b and b['active']:
				b['active'] = false
			elif 'length' in b and b['length'] > 0:
				b['length'] -= 1
				if 'move_up' in b['type']:
					global_move_buff += 1
				if 'move_down' in b['type']:
					global_move_buff -= 1
				if 'speed_up' in b['type']:
					global_speed_buff += 1
				if 'speed_down' in b['type']:
					global_speed_buff -= 1
				hold_buffs.append(b)
	for i in range(0, len(active_buffs)):
		active_buffs.erase(active_buffs[len(active_buffs)-1])
	active_buffs = hold_buffs
	if 'regen_obj' in str(active_buffs):
		regen_on_obj = true
	if 'regen_enm' in str(active_buffs):
		regen_on_enm = true
	if 'regen_projectile' in str(active_buffs):
		regen_on_projectile = true
	if not 'regen' in str(active_buffs) and regen_val > 0:
		regen_val = 0
	#else:
		#print('active_buffs is ' + str(active_buffs))


func compare_obj_tile_index(o1, o2, specific_index=false, should_check_previous=true):
	# TODOD: only compare objs going passed each other, if left and right or up and down
	if main.checkIfNodeDeleted(o1) == false and main.checkIfNodeDeleted(o2) == false:
		if specific_index:
			if o1.current_tile.index == specific_index or should_check_previous and  o1.previous_tile.index == specific_index or\
			   o2.current_tile.index == specific_index or should_check_previous and  o2.previous_tile.index == specific_index:
				return true
		elif should_check_previous and o1.current_tile.index == o2.previous_tile.index or\
			 should_check_previous and o1.previous_tile.index == o2.current_tile.index or\
			 o1.current_tile.index == o2.current_tile.index or\
			 should_check_previous and o1.previous_tile.index == o2.previous_tile.index: 
			return true
	return false


func trigger_projectiles(which_ones='player'):
	var projectiles = get_tree().get_nodes_in_group("projectile")
	for p in projectiles:
		if which_ones == 'all':
			p.handle_projectile_crash()
		elif which_ones == 'player' and not p.can_hurt_player:
			p.handle_projectile_crash()
		elif which_ones == 'enemy' and p.can_hurt_player:
			p.handle_projectile_crash()


func get_cards_from_losing_control(cards_to_add):
	var count = 0
	for i in range(0, cards_to_add):
		# return out of special control cards that cost 0
		var c_preload = card_preload.losing_control_cards[rand_range(0, len(card_preload.losing_control_cards))]
		if c_preload:
			count += 1
			#print('cards found ' + str(count))
			var c = c_preload.instance()
			get_node("/root").add_child(c)
			if c:
				#print('\n\n\n')
				#print('found card ' + str(c.details.title))
				#print('\n\n\n')
				added_deck.append(c)
		else:
			pass
			#print('didn\' find card but shouldd\'ve')
	#print('should\'ve added ' + str(count) + ' cards')


func get_cards_from_collision(cards_to_add, dir, strength=null):
	for i in range(0, cards_to_add):
		if not strength: strength = rand_range(1, 2)
		# return collision cards that cost 0 # essentially like out of control but mapped
		var c_preload = card_preload.return_unstable_card_string_to_preload(dir.to_upper() + ' ' + str(strength))
		if c_preload:
			var c = c_preload.instance()
			get_node("/root").add_child(c)
			if c:
				#print('\n\n\n')
				#print('found card ' + str(c.details.title))
				#print('\n\n\n')
				added_deck.append(c)
		#else:
			#print('didn\' find card but shouldd\'ve')


func validate_all_tile_based_collisions():
	var objects = get_tree().get_nodes_in_group("active_objects")
	var projectiles = get_tree().get_nodes_in_group("projectile")
	var enemies = get_tree().get_nodes_in_group("active_enemies")
	for p in projectiles: 
		if main.checkIfNodeDeleted(p) == false:
			p.check_tile_based_collision()
	for e in enemies: 
		if main.checkIfNodeDeleted(e) == false:
			e.check_tile_based_collision()
	for o in objects: 
		if main.checkIfNodeDeleted(o) == false:
			o.check_tile_based_collision()
	if get_node("/root").has_node("player"):
		get_node("/root/player").check_tile_based_collision()


func validate_all_collisions():
	print('1SKIPPING VALIDATE COLLISIONS DON\'T FORGET TO FIX1')
	print('2SKIPPING VALIDATE COLLISIONS DON\'T FORGET TO FIX2')
	print('3SKIPPING VALIDATE COLLISIONS DON\'T FORGET TO FIX3')
	return
	var objects = get_tree().get_nodes_in_group("active_objects")
	var projectiles = get_tree().get_nodes_in_group("projectile")
	var enemies = get_tree().get_nodes_in_group("active_enemies")
	var player = null
	if get_node("/root").has_node("player"):
		player = get_node("/root/player")
	var player_should_crash = false
	for e in enemies: 
		if 'Node' in str(e) and main.checkIfNodeDeleted(e) == false and e.active:
			if 'Node' in str(player) and main.checkIfNodeDeleted(player) == false:
				if compare_obj_tile_index(player, e, false, (game.player_move_dir == 'right' and e.move_dir == 'left' or\
														   game.player_move_dir == 'left' and e.move_dir == 'right' or\
														   game.player_move_dir == 'up' and e.move_dir == 'down' or\
														   game.player_move_dir == 'down' and e.move_dir == 'up')):
					if game.regen_on_enm:
						game.player_stability += game.regen_val
					var t = meta.get_neighboring_tiles(e.current_tile, [player_move_dir])
					var pt = meta.get_neighboring_tiles(player.current_tile, [e.move_dir])
					if len(t) > 0:
						if not t[0].movable or t[0].has_enemy or t[0].has_player:
							e.call_deferred("handle_crash")
							e.active = false
						else:
							e.current_tile = e.previous_tile
							e.move_tiles = [t[0]]
					else:
						e.call_deferred("handle_crash")
						e.active = false
					if len(pt) > 0 and len(t) > 0:
						if not t[0].movable or pt[0].has_enemy or pt[0].has_player:
							player_should_crash = true
						else:
							player.current_tile = player.previous_tile
							player.move_tiles = [t[0]]
					meta.round_stats.enemies_hit += 1
					get_cards_from_collision(rand_range(1, meta.savable.player.hand_limit + 1), e.move_dir)
					player_move_speed += 1
					if player_move_speed > turn.step:
						player_move_speed = turn.step
			for e2 in enemies:
				if 'Node' in str(e2) and main.checkIfNodeDeleted(e2) == false and e2.active:
					if e != e2 and compare_obj_tile_index(e2, e, false, (e.move_dir == 'right' and e2.move_dir == 'left' or\
																	   e.move_dir == 'left' and e2.move_dir == 'right' or\
																	   e.move_dir == 'up' and e2.move_dir == 'down' or\
																	   e.move_dir == 'down' and e2.move_dir == 'up')):
						if game.regen_on_enm:
							game.player_stability += game.regen_val * 2
						var t1 = meta.get_neighboring_tiles(e.current_tile, [e2.move_dir])
						var t2 = meta.get_neighboring_tiles(e2.current_tile, [e.move_dir])
						if len(t1) > 0:
							if not t1[0].movable or t1[0].has_enemy or t1[0].has_player:
								e.call_deferred("handle_crash")
								e.active = false
							else:
								e.current_tile = e.previous_tile
								e.move_tiles = [t1[0]]
						else:
							e.call_deferred("handle_crash")
							e.active = false

						if len(t2) > 0:
							if not t2[0].movable or t2[0].has_enemy or t2[0].has_player:
								e2.call_deferred("handle_crash")
								e2.active = false
							else:
								e2.move_tiles = [e2.previous_tile]
								e2.current_tile = t2[0]
						else:
							e2.call_deferred("handle_crash")
							e2.active = false

	#print('start object projectile')
	for projectile in projectiles: # compare objects and player to projectiles
		if 'Node' in str(projectile) and main.checkIfNodeDeleted(projectile) == false and projectile.active:
			if main.checkIfNodeDeleted(player) == false and projectile.parent != str(player) and\
			   compare_obj_tile_index(projectile, player, false, (game.player_move_dir == 'right' and projectile.dir == 'left' or\
														 game.player_move_dir == 'left' and projectile.dir == 'right' or\
														 game.player_move_dir == 'up' and projectile.dir == 'down' or\
														 game.player_move_dir == 'down' and projectile.dir == 'up')):
				player_should_crash = true
				meta.round_stats.projectiles_hit += 1
				projectile.call_deferred("handle_projectile_crash")
				projectile.active = false
				if main.master_sound:
					main.master_sound.get_node("impact").play()
			for e in enemies: 
				if 'Node' in str(e) and main.checkIfNodeDeleted(e) == false and e.active:
					if projectile.parent != str(e) and compare_obj_tile_index(projectile, e, false, (e.move_dir == 'right' and projectile.dir == 'left' or\
																								 e.move_dir == 'left' and projectile.dir == 'right' or\
																								 e.move_dir == 'up' and projectile.dir == 'down' or\
																								 e.move_dir == 'down' and projectile.dir == 'up')):
						meta.round_stats.enemies_shot += 1
						projectile.call_deferred("handle_projectile_crash")
						projectile.active = false
						if game.regen_on_enm:
							game.player_stability += game.regen_val
						e.call_deferred("handle_crash")
						e.active = false
						if main.master_sound:
							main.master_sound.get_node("impact").play()
			for projectile2 in projectiles: # compare objects and player to projectiles
				if 'Node' in str(projectile2) and main.checkIfNodeDeleted(projectile2) == false and projectile2.active:
					if projectile2 != projectile:
						if compare_obj_tile_index(projectile2, projectile):
							projectile.call_deferred("handle_projectile_crash")
							projectile2.call_deferred("handle_projectile_crash")
							projectile2.active = false
							projectile.active = false
							if main.master_sound:
								main.master_sound.get_node("impact").play()
	#print('start object cols')
	for o in objects:
		if 'Node' in str(o) and main.checkIfNodeDeleted(o) == false and o.active:
			for e in enemies:  # compare objects and player to enemies
				if main.checkIfNodeDeleted(e) == false and e.active:
					if compare_obj_tile_index(o, e, false, (e.move_dir == 'right')):
						o.destroy_self()
						o.active = false
						if game.regen_on_obj:
							game.player_stability += game.regen_val
						if game.regen_on_enm:
							game.player_stability += game.regen_val
						meta.round_stats.enemy_objects_hit += 1
						e.call_deferred("handle_crash")
						e.active = false
			for projectile in projectiles: # compare objects and player to projectiles
				if 'Node' in str(projectile) and main.checkIfNodeDeleted(projectile) == false and projectile.active:
					if compare_obj_tile_index(o, projectile, false, (projectile.dir == 'right')):
						o.destroy_self()
						o.active = false
						if regen_on_obj:
							player_stability += regen_val
						if not projectile.can_hurt_player:
							meta.round_stats.objects_shot += 1
						projectile.handle_projectile_crash()
						projectile.active = false
						if main.master_sound:
							main.master_sound.get_node("impact").play()

			if 'Node' in str(player) and main.checkIfNodeDeleted(player) == false and o.active and\
			   compare_obj_tile_index(player, o, false, (game.player_move_dir == 'right')): # compare player to objects
				meta.round_stats.objects_hit += 1
				o.destroy_self()
				o.active = false
				if game.regen_on_obj:
					game.player_stability += game.regen_val
				player_should_crash = true

	if 'Node' in str(player) and main.checkIfNodeDeleted(player) == false and player_should_crash:
		player.call_deferred("handle_crash")


func end_level():
	level_over = true
	main.clear_array(hand)
	main.clear_array(discard_deck)
	main.clear_array(added_deck)
	main.clear_array(meta.savable.player.current_deck)
	discard_deck = []
	added_deck = []
	meta.savable.player.current_deck = []
	hand = []
	var l = null
	if get_node("/root").has_node("level"):
		l = get_node("/root/level")
	
	var p = null
	for p in  get_tree().get_nodes_in_group("player"):
		if main.checkIfNodeDeleted(p) == false:
			p.destroy_self()
	if get_node("/root").has_node("player"):
		if main.checkIfNodeDeleted(p) == false:
			p.call_deferred("destroy_self")
	for e in get_tree().get_nodes_in_group("active_enemies"):
		if main.checkIfNodeDeleted(e) == false:
			e.call_deferred("destroy_self")
	for o in get_tree().get_nodes_in_group("active_objects"):
		if main.checkIfNodeDeleted(o) == false:
			o.destroy_self()
	for proj in get_tree().get_nodes_in_group("projectile"):
		if main.checkIfNodeDeleted(proj) == false:
			proj.destroy_self()
	if l != null and main.checkIfNodeDeleted(l) == false:
		l.queue_free()

	var los = main.instancer(main.LEVEL_OVER_SCENE)
	show_level_stats(los)
	main.current_menu = 'level_over'
	if not level_won:
		overworld.overworld_position = ''
	main.game_started = false
	main.in_menu = true
	main.end_all_sound()
	main.master_sound.get_node("chords").play()
	meta.add_round_stats_to_all_time()
	main.can_click_any = true
	#meta.play_screen_cap_anim()


func show_level_stats(level_scene):
	var card_text = 'Cards Played:'
	level_scene.get_node("death by").visible = true
	if not level_won:
		if meta.round_stats.objects_hit > 0:
			level_scene.get_node("death by").set_text('Death by terrain')
		elif meta.round_stats.projectiles_hit > 0:
			level_scene.get_node("death by").set_text('Death by projectile')
		elif meta.round_stats.enemies_hit > 0:
			level_scene.get_node("death by").set_text('Death by enemy collision')
		elif meta.round_stats.hazard_hit > 0:
			level_scene.get_node("death by").set_text('Death by hazard')
	else:
		level_scene.get_node("death by").set_text('Level Complete!')
	
	level_scene.get_node("rounds").set_text('Total Rounds: ' + str(meta.round_stats.rounds))
	level_scene.get_node("objects_shot").set_text('Objects Shot: ' + str(meta.round_stats.objects_shot))
	level_scene.get_node("projectiles_shot").set_text('Projectiles Shot: ' + str(meta.round_stats.projectiles_shot))
	level_scene.get_node("enemies_shot").set_text('Enemies Shot: ' + str(meta.round_stats.enemies_shot))
	level_scene.get_node("enemy_objects_hit").set_text('Enemies Crashed: ' + str(meta.round_stats.enemy_objects_hit))
	level_scene.get_node("times_lost_control").set_text('Rounds Lost Control: ' + str(meta.round_stats.times_lost_control))
	level_scene.get_node("steps_out_of_stability").set_text('Tiles Moved While Out Of Stability: ' + str(meta.round_stats.steps_out_of_stability))
	level_scene.get_node("steps_taken_in_level").set_text('Total Distance Traveled in Tiles: ' + str(meta.round_stats.steps_taken_in_level))

	var count = 0
	for card in meta.round_stats.most_used_cards:
		count += 1
		card_text += ' ' + str(card['title']) + ' ' + str(card['times_played'])
		if count < len(meta.round_stats.most_used_cards):
			card_text += ','
	level_scene.get_node("cards_used").set_text(card_text)


func highlight_card():
	if main.master_sound: main.master_sound.get_node("card swipe").play()
	for c in hand:
		if main.checkIfNodeDeleted(c) == false and 'Node' in str(c):
			if main.checkIfNodeDeleted(hand[hand_idx]) == false and hand[hand_idx] == c:
				c.set_scale(highlight_card_size)
				c.get_node("background haze").visible = true
			else:
				c.get_node("background haze").visible = false
				c.set_scale(card_hand_size)
			if c.details.cost <= player_stability:
				c.modulate = Color(1, 1, 1, 1)
			else:
				c.modulate = meta.cant_play_card_color
			c.get_node("description").visible = false
	if len(hand) > 0 and hand_idx < len(hand):
		if main.checkIfNodeDeleted(hand[hand_idx]) == false and 'Node' in str(hand[hand_idx]):
			var can_play_card_result = validate_can_play_card(hand[hand_idx])
			if can_play_card_result[0]:
				hand[hand_idx].modulate = Color(1, 1, .5, 1)
			else:
				hand[hand_idx].modulate = meta.cant_play_card_color
			hand[hand_idx].get_node("description").visible = true
	else:
		pass
		#print('hand idx out of score in highlight???? hand ' + str(hand) + ' hand_idx ' + str(hand_idx))


func validate_can_play_card(card):
	""" 
		Return reason for reference elsewhere
	 """
	var p = null
	var reason = 'none'
	if get_node("/root").has_node("player"):
		p = get_node("/root/player")

	if p == null or main.checkIfNodeDeleted(p) == true:
		print('didnt find player? in validate_can_play_card')
		reason = 'no player'
		return [false, reason]

	if card.details.cost > player_stability:
		print('no stability  in validate_can_play_card')
		reason = 'stability'
		return [false, reason]
	if p.player_in_air:
		if 'projectile' in str(card.details.type) or 'jump' in str(card.details.type):
			print('in air jump/projectile in validate_can_play_card')
			reason = 'in air'
			return [false, reason]
	return [true, reason]


func discard_hand(hand_val):
	for card in hand_val:
		if main.checkIfNodeDeleted(card) == false and 'Node' in str(card):
			if not card.details.in_deck == 'removal':
				discard_deck.append(card)
				card.details.in_deck = 'discard'
			card.visible = false
			card.position = Vector2(-1000, -1000)


func handle_round_over():
	""" just before the turn start when everything moves to new tiles """
	print('before hand discard in game.gd')
	discard_hand(hand)
	print('after hand discard in game.gd')
	if game.player_stability > meta.savable.player.stability_max:
		game.player_stability = meta.savable.player.stability_max
	if game.player_stability < 0:
		game.player_stability = 0
	
	print('before card removal')
	removal_deck = []
	print('after card removal')


func resolve_card(card_node):
	if main.checkIfNodeDeleted(card_node) == true or not 'Node' in str(card_node):
		pass
		#print('called resolve_card with no card in game.gd?')
	var l = get_node("/root/level")
	var player = get_node("/root/player")
	if not player or main.checkIfNodeDeleted(player) == true:
		return
	var card = card_node.details
	player_move_dir = 'right'
	player_move_speed = 0

	for t in card.type:
		if t == 'speed':
			turn.step += card.speed_change +\
			global_speed_buff + meta.savable.player.speed_mod
			if turn.step < meta.savable.player.step_min: turn.step = meta.savable.player.step_min
			if turn.step > turn.step_limit: turn.step = turn.step_limit
		elif t == 'move':
			player_move_dir = card.move_dir
			player_move_speed = card.move_distance\
			 + global_move_buff + meta.savable.player.move_distance_mod
			if player_move_dir != 'left':
				player.get_node("body/smoke_shadow_anim").play("move anim")
		elif t == 'buff':
			if 'regen' in card.buff_type:
				regen_val += card.buff_value
			apply_buffs(card.buff_type, card.buff_value, card.buff_length)
		elif t == 'projectile':
			var p = l.spawn_projectiles(player, {'can_hurt_player': false,
										'aoe': card.aoe, 'mine': 'MINE' in card.title,
										'floater': 'FLOATER' in card.title})
			meta.round_stats.projectiles_shot += 1
		elif t == 'jump':
			player.get_node("turn_anim_player").play("idle")
			if not player.player_in_air:
				var sp = main.smoke_puff.instance()
				get_node("/root").add_child(sp)
				player.get_node("body/Sprite").position.y -= 30
				player.get_node("body/Sprite4").position.y -= 30
				player.rotation = (.23)
				sp.z_index = player.z_index - 1
				sp.position = player.current_tile.global_position
				player.max_air_time = card.jump_air_time + meta.savable.player.air_time_bonus
			else:
				player.max_air_time += card.jump_air_time + meta.savable.player.air_time_bonus
			player.half_air_time = round(player.max_air_time * .50)
			player.player_in_air = true
			player.player_can_crash = false
		elif t == 'redraw':
			turn.play_another_card = true
		else:
			pass
			#print('unhandled type: ' + str(t))
	
	# we MUST change previous tile if we don't move left or right. Previous tile..
	# is used when we 'cross over' a collision obj's tile but not land on in in same turn..
	# because each obj moved past eachother to a new tile and set different current tiles..
	# therefore to account for collision that should've happened we use previous tile left or right only
	#if not 'move' in str(card.type) or not 'left' in card.move_dir and not\
	# 'right' in card.move_dir:
	#	player.previous_tile = player.current_tile
	if player_move_speed > turn.step:
		player_move_speed = turn.step
	meta.handle_card_stats({'title': '"' + card.title + '"', 'times_played': 1})
	#print('card resolved completely?')


func handle_added_cards():
	pass


func move_sun_and_change_tiles(move_closer=true):
	if moving_sun:
		return
	#print('sun shouldd move?')
	var l = get_node("/root/level")
	for t in get_tree().get_nodes_in_group("tile"):
		if main.checkIfNodeDeleted(t) == false:
			if t.col < 10 and t.row < 10:
				if t.col*t.row <= 12:
					t.hazard = true if move_closer else false
	if not move_closer:
		if main.checkIfNodeDeleted(l) == false:
			if l.get_node("sun_imgs").position.y > 0:
				moving_sun = true
				if main.master_sound:
					main.master_sound.get_node("heavy wind").stop()
				l.get_node("global_sun_anim").play("move away")
		#l.get_node("sun_imgs").position = Vector2(-48, -161)
	else:
		if main.checkIfNodeDeleted(l) == false:
			if l.get_node("sun_imgs").position.y < 0:
				moving_sun = true
				#print('should move close')
				if main.master_sound:
					main.master_sound.get_node("heavy wind").play()
				l.get_node("global_sun_anim").play("move_close")
		#l.get_node("sun_imgs").position = Vector2(10, 3)


func set_initial_deck():
	""" This func will likely change based on save/loading decks """
	var p = meta.savable.player
	var deck = p.game_deck if len(p.game_deck) > 0 else card_preload.general_deck
	var shuffle_deck = []
	for card in meta.char_list[meta.char_idx].unique_cards:
		deck.append(card)

	for card in deck:
		# loop to avoid duping lists
		var c = main.instancer(card)
		meta.savable.player.current_deck.append(c)
	#print('len before ' + str(len(meta.savable.player.current_deck)))
	for i in range(0, len(meta.savable.player.current_deck)):
		var rand_idx = rand_range(0, len(meta.savable.player.current_deck))
		var random_selected_card = meta.savable.player.current_deck[rand_idx]
		random_selected_card.visible = false
		shuffle_deck.append(random_selected_card)
		meta.savable.player.current_deck.remove(rand_idx)

	meta.savable.player.current_deck = shuffle_deck
	#print('len after ' + str(len(meta.savable.player.current_deck)))
	#print('player deck is ' + str(deck))


func shuffle_discard_to_current():
	# For the length of the discard deck: Take a random index, then take the..
	# ...card of that index in discard deck and append back to current deck 
	# remove that indexed card from discard so we don't pull it again
	# when done completely empty discard to be sure
	# Note: We DON'T want to completely empty current to ensure we don't..
	# ..miss cards playing cards from bad math having use shuffle and empty deck at bad times
	print('BEFORE DISCARD SHUFFLE')
	for i in range(0, len(discard_deck)):
		var rand_idx = rand_range(0, len(discard_deck))
		var random_selected_card = discard_deck[rand_idx]
		random_selected_card.visible = false
		meta.savable.player.current_deck.append(random_selected_card)
		discard_deck.remove(rand_idx)
	print('AFTER DISCARD SHUFFLE')
	return meta.savable.player.current_deck


func handle_turn_start():
	var p = null
	if get_node("/root").has_node("player"):
		p = get_node("/root/player")
	
	var l = null
	if get_node("/root").has_node("level"):
		l = get_node("/root/level")
	
	while handling_tutorial_messages:
		var timer = Timer.new()
		timer.set_wait_time(.1)
		timer.set_one_shot(true)
		get_node("/root").add_child(timer)
		timer.start()
		yield(timer, "timeout")
		timer.queue_free()

	print('handle turn start')
	if not level_over and main.checkIfNodeDeleted(l) == false and main.checkIfNodeDeleted(p) == false:
		var enemies = get_tree().get_nodes_in_group("active_enemies")
		var objects = get_tree().get_nodes_in_group("active_objects")
		var projectiles = get_tree().get_nodes_in_group("projectile")
		for projectile in projectiles:
			if projectile and main.checkIfNodeDeleted(projectile) == false and\
			   'Node' in str(projectile) and projectile.active and not projectile.removing:
				if main.checkIfNodeDeleted(projectile.current_tile) == false: projectile.current_tile.get_node("occupied_sprite").visible = true
				if projectile.parent != '': # clear parent after first round 
					projectile.parent = ''
				if projectile.floater:
					projectile.speed = rand_range(0, 3)
				if projectile.mine:
					projectile.speed = 0
				var directions = ['right', 'left', 'up', 'down']
				if projectile.floater:
					projectile.dir = directions[rand_range(0, len(directions))]
				if projectile.mine:
					projectile.dir = 'none'
				if main.checkIfNodeDeleted(projectile.preview_tile) == false and projectile.preview_tile.hazard:
					projectile.preview_tile.get_node("occupied_sprite").modulate = meta.light_red_mod
		print('handle turn start end AFTER projectile')
		for o in objects:
			if o and main.checkIfNodeDeleted(o) == false and 'Node' in str(o) and o.active and not o.removing:
				if main.checkIfNodeDeleted(o.preview_tile) == false and o.preview_tile.hazard:
					o.preview_tile.get_node("occupied_sprite").modulate = meta.light_red_mod
				if main.checkIfNodeDeleted(o.current_tile) == false: o.current_tile.get_node("occupied_sprite").visible = true
		print('handle turn start end AFTER object')
		for e in enemies:
			if e and main.checkIfNodeDeleted(e) == false and\
			   'Node' in str(e) and e.active and not e.removing:
				if rand_range(0, 100) <= enm_projectile_chance:
					var aoe = 0
					if rand_range(0, 100) <= enm_bomb_projectile_chance:
						aoe = 1
					var floater = rand_range(0, 100) <= enm_projectile_chance * .50
					var mine = not floater and rand_range(0, 100) <= enm_projectile_chance * .50
					if main.checkIfNodeDeleted(e.current_tile) == false:
						l.spawn_projectiles(e, {'can_hurt_player': true,
												'aoe': aoe, 'mine': mine,
												'floater': floater})
				if main.checkIfNodeDeleted(e.current_tile) == false: 
					e.get_enemy_direction()
					e.current_tile.get_node("occupied_sprite").visible = true
				if main.checkIfNodeDeleted(e.preview_tile) == false and e.preview_tile.hazard:
					e.preview_tile.get_node("occupied_sprite").modulate = meta.light_red_mod
		print('handle turn start end AFTER e')
		if game.object_chance <= 50:
			game.object_chance += 1
		if main.checkIfNodeDeleted(p) == false:
			p.get_node("turn_anim_player").play("idle")
		if player_stability <= 0:
			player_lost_control = true
			#print('player losing stability')
			if l:
				l.get_node("text_container/high_z_index/afford_tip").visible = true
				l.get_node("text_container/high_z_index/in_air_warning").visible = false
			get_cards_from_losing_control(meta.savable.player.hand_limit + 1)
		redraw = false
		if main.checkIfNodeDeleted(p) == false:
			if player_stability <= meta.savable.player.stability_lost_threshold:
				if p.get_node("body/anim_container1/smoke_imgs/Sprite2").modulate != Color(1, 1, 1, .5):
					p.get_node("body/anim_container1/smoke_imgs/Sprite2").modulate = Color(1, 1, 1, .5)
				#print('lose control anim')
				if not p.player_in_air:
					p.get_node("turn_anim_player").play("idle_losing_control")
			else:
				if p.get_node("body/anim_container1/smoke_imgs/Sprite2").modulate != Color(1, 1, 1, .2):
					p.get_node("body/anim_container1/smoke_imgs/Sprite2").modulate = Color(1, 1, 1, .2)
				#print('norm anim')
				p.get_node("turn_anim_player").play("idle")
		if main.checkIfNodeDeleted(p) == false and\
			p.player_can_crash and not p.invincible and p.current_tile and\
			main.checkIfNodeDeleted(p.current_tile) == false and\
			not p.current_tile.movable:
			p.call_deferred("handle_crash")
		print('handle turn start end BEFORE DRAW ')
		draw()
		print('handle turn start end AFTER DRAW ')
	main.can_click_any = true


var redraw = false
func draw():
	if game.level_over:
		return
	var l = get_node("/root/level/")
	var p = get_node("/root/player")
	var cd = meta.savable.player.current_deck
	var dd = discard_deck
	var ad = added_deck
	var temp_hand = hand
	if main.checkIfNodeDeleted(p) == true or main.checkIfNodeDeleted(l) == true:
		game.level_over = true
		return
	# Clear hands before modifying/drawing for coming turn
	temp_hand = []
	hand = []
	##

	# Set loop limit based on hand, we count from 0 for indexing so always add 1
	var hand_limit = meta.savable.player.hand_limit + 1
	##
	var tutorial_hand_set = false
	for i in range(0, hand_limit):
		# Draw from current_deck to hand, if its 0 shuffle discard back to hand
		# WE SHOULD NEVER HAVE A len() == 0 current_deck after this
		if in_tutorial and use_tutorial_deck:
			if not tutorial_hand_set:
				temp_hand = get_current_tutorial_deck()
				tutorial_hand_set = true
			else:
				# if we already set our hand for tutorial skip but don't continue loop
				# so we hit the 'Handle display' block in loop below
				pass
		else:
			if len(ad) > 0 and main.checkIfNodeDeleted(ad[0]) == false:
				#print('\n\n')
				#print('card added from ad deck')
				#print('\n\n')
				temp_hand.append(ad[0]) # cards are removed on discard from ad
				ad[0].details.in_deck = 'removal'
				ad[0].modulate = Color(1, .7, .7, 1)
				removal_deck.append(ad[0])
				if len(ad) > 0:
					ad.remove(0)
			elif len(cd) > 0 and main.checkIfNodeDeleted(cd[0]) == false:
				# this serves to reset vals from mid game bonuses like overclocking
				temp_hand.append(cd[0])
				if len(cd) > 0:
					cd.remove(0)
			elif len(dd) > 0 and main.checkIfNodeDeleted(dd[0]) == false:
				temp_hand.append(shuffle_discard_to_current()[0])
				if len(cd) > 0:
					cd.remove(0)
			else:
				print('NO CARDS TO DRAW???')
		##

		# Handle display
		if i < len(temp_hand) and i >= 0:
			if main.checkIfNodeDeleted(temp_hand[i]) == false:
				temp_hand[i].position = l.get_node("hand_pos_0").position
				temp_hand[i].position.x = l.get_node("hand_pos_0").position.x + (i * card_x_buffer)
				temp_hand[i].set_scale(card_hand_size)
				temp_hand[i].details.played = false
				temp_hand[i].visible = true
				temp_hand[i].z_index = 700
				if temp_hand[i].details.in_deck != 'removal':
					temp_hand[i].modulate = Color(1, 1, 1, 1)
					temp_hand[i].details.in_deck = 'hand'
				meta.animate_cycle_card(temp_hand[i], false)
		##

		if main.checkIfNodeDeleted(temp_hand[i]) == false:
			temp_hand[i].set_unique_details()
	# assign global array to configured hand
	hand = temp_hand
	if not turn.play_another_card:
		start_next_round()
	else:
		turn.step_timer_can_change = true
		turn.can_play_card = true
	var can_afford = false
	
	for c in hand:
		if main.checkIfNodeDeleted(c) == false:
			var can_play_card_result = validate_can_play_card(hand[hand_idx])
			if can_play_card_result[0]:
				can_afford = true
			else:
				c.modulate = meta.cant_play_card_color
	if not can_afford:
		player_lost_control = true
		if l and l != null:
			l.get_node("text_container/high_z_index/afford_tip").visible = true
			l.get_node("text_container/high_z_index/in_air_warning").visible = false
		turn.step_timer = 8
		if not redraw:
			redraw = true
			discard_hand(hand)
			if l:
				l.get_node("text_container/high_z_index/afford_tip").visible = true
				l.get_node("text_container/high_z_index/in_air_warning").visible = false
			get_cards_from_losing_control(meta.savable.player.hand_limit + 1)
			draw()
	if main.master_sound:
		main.master_sound.get_node("card shuffle").play()
	##
	#print('hand is '+ str(hand))
	#for c in hand:
	#	if main.checkIfNodeDeleted(c) == false:
	#		print('c is ' + str(c.name))


func get_current_tutorial_deck():
	var tutorial_idx = meta.savable.tutorial_idx
	if tutorial_idx == 0:
		return card_preload.tutorial_deck_0
	elif tutorial_idx == 1:
		return card_preload.tutorial_deck_1
	elif tutorial_idx == 2:
		return card_preload.tutorial_deck_2
	elif tutorial_idx == 3:
		return card_preload.tutorial_deck_3
	elif tutorial_idx == 4:
		return card_preload.tutorial_deck_4
	elif tutorial_idx == 5:
		return card_preload.tutorial_deck_5
	elif tutorial_idx == 6:
		return card_preload.tutorial_deck_6


func start_next_round():
	var p = null
	if get_node("/root").has_node("player"):
		p = get_node("/root/player")
	var l = get_node("/root/level")
	if main.checkIfNodeDeleted(p) == true or main.checkIfNodeDeleted(l) == true:
		return
	var objects = get_tree().get_nodes_in_group("active_objects")
	var projectiles = get_tree().get_nodes_in_group("projectile")
	var enemies = get_tree().get_nodes_in_group("active_enemies")
	turn.can_play_card = true
	hand_idx = 0
	highlight_card()
	turn.step_timer_can_change = true
	turn.step_timer = turn.step_timer_max
	l.handle_background_anims(false)
	check_and_remove_debuffs()
	in_preview = true
	for projectile in projectiles:
		if main.checkIfNodeDeleted(projectile) == false and 'Node' in str(projectile):
			projectile.preview_tile = projectile.current_tile
			projectile.preview_move_tiles = []
	for o in objects:
		if main.checkIfNodeDeleted(o) == false and 'Node' in str(o):
			o.preview_tile = o.current_tile
			o.preview_move_tiles = []
	for e in enemies:
		if main.checkIfNodeDeleted(e) == false and 'Node' in str(e):
			e.move_speed = rand_range(1, turn.step)
			e.preview_tile = e.current_tile
			e.preview_move_tiles = []
	if main.checkIfNodeDeleted(p) == false and 'Node' in str(p):
		p.preview_tile = p.current_tile
		p.preview_move_tiles = []
	player_lost_control = false
	var timer = Timer.new()
	timer.set_wait_time(1)
	timer.set_one_shot(true)
	get_node("/root").add_child(timer)
	timer.start()
	yield(timer, "timeout")
	timer.queue_free()
	turn.call_deferred("preview_turn")

