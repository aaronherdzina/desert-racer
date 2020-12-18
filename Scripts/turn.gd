extends Sprite

var stop_moving = false
var step = 4
var preview_step = 4
var step_default = 4
var step_min = 2
var step_limit = 8
var step_timer = 10
var step_timer_max_default = 20
var step_timer_max = 20
var step_timer_max_slow = 50
var step_timer_max_fast = 3
var step_timer_can_change = true

var at_bottom_timer_increase_val = .05
var timer_missed_turn_change = 2
var timer_turn_change_normal = 1
var turns_at_bottom_timer_limit = 10
var at_bottom_timer = false
var turns_at_bottom_timer_count = 0
var object_move_speed = 83
var object_move_time = .4
var lower_timer_low_stability_val = 2
var can_play_card = false

var card_level_1_time_cost = .25
var card_level_2_time_cost = 1
var card_level_3_time_cost = 1.5
var card_level_4_time_cost = 3
var play_another_card = false
var handling_turn = false

var handle_preview = true
var should_end_preview = false
var safely_out_of_preview = true

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass


func play_card(end_turn, here_with_input=false, found_card=null):
	if game.level_over or handling_turn:
		return
	if can_play_card:
		var hold_card = null
		var can_afford = true
		var can_afford_any = false
		game.handle_card_alert('', true)
		
		# Make sure card is there and not removed
		if len(game.hand) > 0 and game.hand_idx < len(game.hand) and game.hand_idx >= 0 and\
		   'Node' in str(game.hand[game.hand_idx]) and\
		   main.checkIfNodeDeleted(game.hand[game.hand_idx]) == false:
			var card = null if not found_card or main.checkIfNodeDeleted(found_card) == true else found_card
			var can_play_card_result = game.validate_can_play_card(game.hand[game.hand_idx]) if not found_card else game.validate_can_play_card(found_card)
			# create alert to show here
			# if we can't play the card
			if not can_play_card_result[0]: 
				can_afford = false
				game.handle_card_alert(can_play_card_result[1])
				for c in game.hand:
					if 'Node' in str(c) and main.checkIfNodeDeleted(c) == false:
						if c.details.cost <= game.player_stability:
							card = c
							can_afford_any = true
							break
				if main.master_sound:
					main.master_sound.get_node("no_effect").play()
				if here_with_input:
					return # can't play, if auto played then set random unwanted effect for losing control
				else:
					var dirs = ['right', 'left', 'up', 'down']
					game.player_move_dir = dirs[rand_range(0, len(dirs))]
					game.player_move_speed = rand_range(0, step)
					if main.checkIfNodeDeleted(card) == false:
						card.modulate = Color(1, 0, 0, .6)
			
			# if this card is not playable because we are in air show tool tip
			elif 'in air' in can_play_card_result[1]:
				if get_node('/root').has_node('level'):
					var l = get_node('/root/level')
					if l and l != null:
						get_node("text_container/high_z_index/in_air_warning").visible = true
						get_node('/root/level').get_node("text_container/high_z_index/afford_tip").visible = false
			
			# if the card is playable or 'card' is not null meaning we auto selected an affordable card
			if can_play_card_result[0] or 'Node' in str(card) and\
			   main.checkIfNodeDeleted(card) == false and card and can_afford_any:
				can_afford_any = true
				if not card: card = game.hand[game.hand_idx]
				if main.master_sound: main.master_sound.get_node("sci fi select").play()
				play_another_card = false
				step_timer_can_change = false
				if main.checkIfNodeDeleted(card) == false:
					var l = get_node("/root/level")
					can_play_card = false
					for c in game.hand:
						if 'Node' in str(c) and main.checkIfNodeDeleted(c) == false:
							if c != card: c.visible = false
					card.set_scale(Vector2(.23, .23))
					card.position = l.get_node("card_middle").global_position
					card.z_index = 700
					hold_card = card
					if 'Node' in str(l) and main.checkIfNodeDeleted(l) == false:
						card.position = get_node("/root/level/played_card_pos").global_position
					card.visible = true
					game.resolve_card(card)
					game.player_stability -= card.details.cost
					l.handle_round_timer()
			
			#print('after move card logic in play card')
			if 'Node' in str(card) and main.checkIfNodeDeleted(card) == false and card:
				hold_card = card
				if can_afford:
					main.handle_card_noises(card)
				else:
					main.get_char_move_noises()

		#print('pre stability changes in play card')
		if play_another_card:
			if 'Node' in str(hold_card) and main.checkIfNodeDeleted(hold_card) == false and hold_card:
				hold_card.visible = false
			game.draw()
			return
		elif end_turn: 
			if game.in_tutorial:
				if game.handling_tutorial_messages:
					game.handling_tutorial_messages = false
				game.previous_tutorial_idx = meta.savable.tutorial_idx
				meta.savable.tutorial_idx += 1
				if meta.savable.tutorial_idx > 7:
					game.in_tutorial = false
			handle_end_of_turn_stability_and_timer()
			handle_turn()
			var timer2 = Timer.new()
			timer2.set_wait_time(1.5)
			timer2.set_one_shot(true)
			get_node("/root").add_child(timer2)
			timer2.start()
			yield(timer2, "timeout")
			timer2.queue_free()
			if main.checkIfNodeDeleted(hold_card) == false and hold_card:
				hold_card.visible = false
		else:
			# we clear step_timer_can_change in draw after handle_turn so reset if handle_turn not called
			step_timer_can_change = true
		#print('card played?')


# warning-ignore:unused_argument
func handle_end_of_turn_stability_and_timer(can_afford_any=true):
	#if not can_afford_any:
	#	game.player_stability += (meta.savable.player.stability_max * .25)
	if game.player_lost_control:
		meta.round_stats.times_lost_control += 1
		turn.step_timer_max -= turn.timer_missed_turn_change
	if turn.step_timer_max <= turn.step_timer_max_fast:
		turn.step_timer_max = turn.step_timer_max_fast
	if turn.step_timer_max > turn.step_timer_max_default:
		turn.step_timer_max = turn.step_timer_max_default


func show_level_details(l, on=true):
	if main.checkIfNodeDeleted(l) == false:
		#l.get_node("tile_container").visible = on
		l.get_node("text_container").visible = on
		for t in l.level_tiles:
			if main.checkIfNodeDeleted(t) == false and 'Node' in str(t) and\
				main.checkIfNodeDeleted(t.get_node("Sprite")) == false:
				if not t.hazard and t.movable:
					t.get_node("Sprite").visible = on
				if t.finish:
					t.get_node("Sprite").visible = true


func handle_turn():
	if game.level_over:
		return
	
	# TODO: Have tutorial be 1 level set to cycle each round with specifically placed
	# obstacles to match tutorial cards being drawn (i.e: tutorial is just one level played out each turn)

	main.can_click_any = false
	""" Handle moving through 'steps' order below, 1-4
		0) Hanlde randomly spawning objects - can maybe just do this at end of turn to not slow down
		1) BEFORE STEPS: Get the next tiles for all active objects and player if moving
		2) Clear tiles vars to avoid incorret collisions, ect
		3) Move everything through next step and to their new tile and set tile vars
		4) resolve collisions for crashing, ect
	"""
	""" NOTE ON COLLISION: There are cases where 2 different objects of any kind can move past..
		.. each other. For example, if player is in tile 4 and a rock is in tile 5. we process moving..
		..together at once then collision, in this case player moves to 5 and rock moves to 4...
		..At this point we check collision which returns nothing because they essentially swapped..
		.. but never landedd on eachothers tile at the same time, we handle this by setting previous_tile
		..in each obj before we change current to its newest spot, however we should ensure that previous
		..is set to current if we don't move left or right otherwise it would give unwanted collisions
	"""
	
	var l = get_node("/root/level")
	l.should_shake_cam = true
	l.cameraShake(1.7, .08)
	should_end_preview = true
	while not safely_out_of_preview:
		var wait_timer = Timer.new()
		wait_timer.set_wait_time(.05)
		wait_timer.set_one_shot(true)
		get_node("/root").add_child(wait_timer)
		wait_timer.start()
		yield(wait_timer, "timeout")
		wait_timer.queue_free()

	step_timer_can_change = false
	game.in_preview = false
	if at_bottom_timer:
		turns_at_bottom_timer_count += 1

	var p = get_node("/root/player")
	l = get_node("/root/level")
	l.repeat_player_tile_call = false
	var pre_loop_objects = get_tree().get_nodes_in_group("active_objects")
	var pre_loop_projectiles = get_tree().get_nodes_in_group("projectile")
	var pre_loop_enemies = get_tree().get_nodes_in_group("active_enemies")
	show_level_details(l, false)
	var total_steps = meta.round_stats.steps_taken_in_level
	#if total_steps > 30 and total_steps < 60 or total_steps > 90 and total_steps < 120 or total_steps > 160:
	#	game.move_sun_and_change_tiles(true)
	#else:
	#	game.move_sun_and_change_tiles(false)
	#print('done checking sun')
	l.get_node("text_container/high_z_index/afford_tip").visible = false
	## 0) Handle randomly spawning objects
	#print('handling turn pre spawning')
# warning-ignore:unused_variable
	if not game.in_tutorial:
		for i in range(0, game.objs_per_turn):
			if rand_range(0, 100) < game.object_chance and len(pre_loop_objects) < game.object_limit:
				l.spawn_objects()
	
# warning-ignore:unused_variable
	if not game.in_tutorial:
		for i in range(0, game.enms_per_turn):
			if rand_range(0, 100) < game.spawn_enm_chance and len(pre_loop_enemies) < game.enemy_limit:
				l.spawn_enemies()
	## 1) BEFORE STEPS: Get next tiles for player if moving and all objects
	print('handling turn pre first wait')
	if main.checkIfNodeDeleted(p) == false and main.checkIfNodeDeleted(p.get_node("preview_body")) == false:
		p.get_node("preview_body").visible = false
	
	print('handling turn pre pre loops')
	if main.checkIfNodeDeleted(l) == false and main.checkIfNodeDeleted(p) == false:
		for e in pre_loop_enemies:
			if main.checkIfNodeDeleted(e) == false and 'Node' in str(e) and e.active and not e.removing and\
			    main.checkIfNodeDeleted(e.current_tile) == false:
				e.move_tiles = []
				e.get_node("preview_body").visible = false
				l.find_enemy_move_tiles(e.move_speed, e, e.move_dir)
		print('handling turn post e pre loops')
		for o in pre_loop_objects:
			if main.checkIfNodeDeleted(o) == false and 'Node' in str(o) and o.active and not o.removing and\
			    main.checkIfNodeDeleted(o.current_tile) == false:
				o.move_tiles = []
				o.get_node("preview_body").visible = false
				l.find_object_move_tiles(turn.step, o)
		print('handling turn post o pre loops')
		for projectile in pre_loop_projectiles:
			if main.checkIfNodeDeleted(projectile) == false and 'Node' in str(projectile) and projectile.active and not projectile.removing:
				projectile.get_node("preview_body").visible = false
				projectile.move_tiles = []
				if not projectile.floater and not projectile.mine:
					projectile.speed = turn.step
				l.find_projectile_move_tiles(turn.step, projectile)
		print('handling turn post projectile pre loops')
		if main.checkIfNodeDeleted(p) == false and not p.removing and\
		   main.checkIfNodeDeleted(p.current_tile) == false:
			p.move_tiles = []
			if game.player_move_speed >= 0:
				l.find_player_move_tiles(game.player_move_speed, p, game.player_move_dir)
				
	if game.level_over:
		return
	meta.round_stats.rounds += 1
	print('handling turn postpre loops and pre step loop')
	handling_turn = true
	var timer2 = Timer.new()
	timer2.set_wait_time(object_move_time/2)
	timer2.set_one_shot(true)
	get_node("/root").add_child(timer2)
	timer2.start()
	yield(timer2, "timeout")
	timer2.queue_free()
	l.handle_background_anims(true)

	if game.level_over:
		return

	for s in range(0, step):
		if game.player_stability <= meta.savable.player.stability_lost_threshold:
			meta.round_stats.steps_out_of_stability += 1
		meta.round_stats.steps_taken_in_level += 1
		var objects = get_tree().get_nodes_in_group("active_objects")
		var projectiles = get_tree().get_nodes_in_group("projectile")
		var enemies = get_tree().get_nodes_in_group("active_enemies")
		# for each step move objects and to their next tile and player if moving
		# also clear vars before move when they are set, after each move things are resolved
		
		## 2) Clear tiles vars to avoid incorret collisions, ect
		l.clear_tile_vars()
		
		if game.set_finish_tiles:
			#print(str(meta.savable.row - game.set_finish_col_idx))
			game.set_finish_col_idx += 1
		## 3) Move everything through next step and to the new tile and set vars
		if main.checkIfNodeDeleted(p) == true or p.removing:
			return
		else:
			if p.player_in_air:
				p.handle_jumping(s)
		#l.set_hazard = true
		#if total_steps > 10 and total_steps < 35 or total_steps > 60:
		#	l.add_level_hazard()
		#else:
		#	l.add_level_hazard(true)
		if s < len(p.move_tiles) and main.checkIfNodeDeleted(p.move_tiles[s]) == false:
			p.set_next_move_tile(s)
			l.get_row_scale(p.get_node('body/Sprite'), p.move_tiles[0], game.default_player_scale, 501, p, true)
	

		p.current_tile.has_player = true # needs to be reset
		print('handling turn step post get player move tile ')
		for proj in projectiles:
			if proj and main.checkIfNodeDeleted(proj) == false and 'Node' in str(proj) and proj.active and not proj.removing:
				if s < len(proj.move_tiles) and main.checkIfNodeDeleted(proj.move_tiles[s]) == false:
					if stop_moving:
						stop_moving = false
					proj.set_next_move_tile(s)
					l.get_row_scale(proj.get_node('body/Sprite'), proj.move_tiles[0], Vector2(1.3, 1.3), 0, proj)
				
				proj.current_tile.has_projectile = true
			else:
				stop_moving = true
		#print('handling turn step post get projetile move tile ')
		for e in enemies:
			if e and main.checkIfNodeDeleted(e) == false and 'Node' in str(e) and e.active and not e.removing:
				if s < len(e.move_tiles) and main.checkIfNodeDeleted(e.move_tiles[s]) == false:
					if stop_moving:
						stop_moving = false
					e.set_next_move_tile(s)
					if main.checkIfNodeDeleted(e.get_node('body')) == false\
					   and main.checkIfNodeDeleted(e.get_node('body/Sprite')) == false:
						l.get_row_scale(e.get_node('body/Sprite'), e.move_tiles[0], Vector2(1.3, 1.3), 0, e)
				e.current_tile.has_enemy = true
			else:
				stop_moving = true
		print('handling turn step post get e move tile ')
		for o in objects:
			if o and main.checkIfNodeDeleted(o) == false and 'Node' in str(o) and o.active and not o.removing:
				if s < len(o.move_tiles) and len(o.move_tiles) > 0 and main.checkIfNodeDeleted(o.move_tiles[s]) == false:
					if stop_moving:
						stop_moving = false
					o.set_next_move_tile(s)
					if len(o.move_tiles) > 0:
						if not o.is_row_block:
							if o.move_tiles[s].has_node("occupied_sprite") and main.checkIfNodeDeleted(o.move_tiles[s].get_node("occupied_sprite")) == false:
								o.move_tiles[s].get_node("occupied_sprite").visible = false
								o.move_tiles[s].movable = true
						elif main.checkIfNodeDeleted(o.move_tiles[s]) == false and\
							   o.move_tiles[s].has_node("occupied_sprite") and\
							   main.checkIfNodeDeleted(o.move_tiles[s].get_node("occupied_sprite")) == false and\
							   main.checkIfNodeDeleted(l) == false and\
							   o.move_tiles[s].has_node("Sprite") and\
							   main.checkIfNodeDeleted(o.move_tiles[s].get_node("Sprite")) == false:
								o.move_tiles[s].get_node("occupied_sprite").visible = true
								o.move_tiles[s].get_node("Sprite").visible = false
								if o.move_tiles[s].finish:
									o.move_tiles[s].get_node("Sprite").visible = true
								o.move_tiles[s].movable = false
								l.get_pit_sprite(o.move_tiles[s])
						if o.is_row_block or not o.move_tiles[s].movable:
							l.get_pit_sprite(o, false, true, true)
				if main.checkIfNodeDeleted(o.current_tile) == false and o.current_tile != null:
					o.current_tile.has_object = true
			else:
				stop_moving = true
		print('handling turn step post get o move tile ')
		for t in l.level_tiles:
			if main.checkIfNodeDeleted(t) == false and\
			   main.checkIfNodeDeleted(t.get_node("Sprite")) == false:
				if t.finish:
					t.get_node("Sprite").visible = true
					t.get_node("Sprite").set_texture(main.CHECKER)
					t.get_node("Sprite").modulate = game.finish_tile_color
		p.current_tile.z_index = 300
		#p.current_tile.get_node("occupied_sprite").visible = true
		var timer = Timer.new()
		timer.set_wait_time(object_move_time/2)
		timer.set_one_shot(true)
		get_node("/root").add_child(timer)
		timer.start()
		yield(timer, "timeout")
		timer.queue_free()
		if main.checkIfNodeDeleted(p) == false and p.player_in_air:
			p.handle_jumping(s)
		var timer3 = Timer.new()
		timer3.set_wait_time(object_move_time/2)
		timer3.set_one_shot(true)
		get_node("/root").add_child(timer3)
		timer3.start()
		yield(timer3, "timeout")
		timer3.queue_free()
	#	print('handling turn step pre collision ')
		
		## 4) resolve collisions
		print('validate collisions')
		game.validate_all_tile_based_collisions()
		print('after validate collisions')
		#game.validate_all_collisions() # previous semi working checks
		#if game.level_over:
		#	return
		
		# restart loop for next step or call end of round stuff
	print('before handle round over in handle turn and center tiles')
	l.center_objects_to_tile()
	if game.level_over:
		return
	if main.checkIfNodeDeleted(p) == false:
		if p.player_in_air:
			p.air_time += 1
			if p.air_time >= p.max_air_time:
				p.air_time = 0
				p.max_air_time = 0
				p.player_can_crash = true
				p.player_in_air = false
				p.rotation = p.starting_rotation
				p.get_node("body/Sprite").position.y = p.starting_sprite_pos_y
				p.get_node("body/Sprite4").position.y = p.starting_sprite4_pos_y
				p.get_node("body").set_scale(p.starting_scale)
	handling_turn = false

	print('before handle round over in handle turn')
	
	l.should_shake_cam = false
	l.cameraShake(0, .000)
	game.handle_round_over()
	print('after handle round over in handle turn')
	# handle win cases, if we can't find a player tile and are over step limit
	# we are over the step limit and player current tile is a finish line tile
	# we are over step limit  + total columns (this means somehow all tiles are finish and the player is being treated as on it?)
	if meta.round_stats.steps_taken_in_level >= overworld.level_step_target - meta.savable.row * .5:
		game.set_finish_tiles = true
		if main.checkIfNodeDeleted(p) == false:
			if main.checkIfNodeDeleted(p.current_tile) == false:
				if p.current_tile.finish:
					game.level_won = true
					print('before end level1')
					game.end_level()
					game.level_over = true
					print('after end level1')
			else:
				game.level_won = true
				print('before end level2')
				game.end_level()
				game.level_over = true
				print('after end level2')
	if meta.round_stats.steps_taken_in_level >= overworld.level_step_target + meta.savable.row:
		game.level_won = true
		print('before end level3')
		game.end_level()
		game.level_over = true
		print('after end level3')
	print('before show level details')
	show_level_details(l, true)
	print('after show level details before handle_turn_start')
	game.call_deferred("handle_turn_start")
	print('handle turn end')


func preview_turn():
	if not handle_preview or game.level_over or not game.in_preview:
		return

	should_end_preview = false
	safely_out_of_preview = false
	print('about to start preview while loop')
	while game.in_preview:
		var enm_previews = false
		var p = get_node("/root/player")
		var l = get_node("/root/level")
		var objects = get_tree().get_nodes_in_group("active_objects")
		var projectiles = get_tree().get_nodes_in_group("projectile")
		var enemies = get_tree().get_nodes_in_group("active_enemies")
	
		if len(enemies) > 0:
			enm_previews = true
		
		## 1) BEFORE STEPS: Get next tiles for player if moving and all objects
		preview_step = step
		
		print('in preview_turn, loop start and pre clear tile vars')
		l.clear_tile_vars()
		if game.level_over or not game.in_preview:
			return
		print('in preview_turn pre player')
		if p and main.checkIfNodeDeleted(p) == false and not p.removing:
			if game.hand_idx < len(game.hand):
				p.get_player_preview_action(game.hand[game.hand_idx])
			if main.checkIfNodeDeleted(p.current_tile) == false:
				p.preview_move_tiles = []
				if game.preview_player_move_speed >= 0:
					l.find_player_move_tiles(game.preview_player_move_speed, p, game.preview_player_move_dir)
				if len(p.preview_move_tiles) > 0 and p.preview_move_tiles[len(p.preview_move_tiles)-1] != null:
					p.set_next_preview_move_tile()
					p.preview_tile.has_player = true # needs to be reset
					if main.checkIfNodeDeleted(p.preview_tile) == false:
						p.preview_tile.get_node("Sprite").modulate = Color(.1, .1, 1, 1)
		else:
			return # if player is not presented that means level is over and should stop now

		if game.level_over or not game.in_preview:
			return
		if enm_previews:
			print('in preview_turn pre enemies')
			for e in enemies:
				if e and main.checkIfNodeDeleted(e) == false and 'Node' in str(e) and e.active and not e.removing and\
				   main.checkIfNodeDeleted(e.current_tile) == false and\
				   main.checkIfNodeDeleted(e.get_node("body")) == false and\
				   main.checkIfNodeDeleted(e.get_node("preview_body")) == false:
					e.get_node("preview_body").visible = true
					e.get_node("preview_body").position = e.get_node("body").position
					l.find_enemy_move_tiles(e.move_speed, e, e.move_dir)
					if len(e.preview_move_tiles) > 0 and main.checkIfNodeDeleted(e.preview_move_tiles[len(e.preview_move_tiles)-1]) == false:
						e.set_next_preview_move_tile()
					if main.checkIfNodeDeleted(e.preview_tile) == false and e.preview_tile.has_node("occupied_sprite") and main.checkIfNodeDeleted(e.preview_tile.get_node("occupied_sprite")) == false:
						e.preview_tile.get_node("occupied_sprite").visible = true

		if game.level_over or not game.in_preview:
			return
		print('in preview_turn after player and before obj')
		for o in objects:
			if o and main.checkIfNodeDeleted(o) == false and 'Node' in str(o) and o.active and not o.removing and\
			   main.checkIfNodeDeleted(o.current_tile) == false and\
			   main.checkIfNodeDeleted(o.get_node("body")) == false and\
			   main.checkIfNodeDeleted(o.get_node("preview_body")) == false:
				o.get_node("preview_body").position = o.get_node("body").position
				o.get_node("preview_body").visible = true
				l.find_object_move_tiles(preview_step, o)
				if len(o.preview_move_tiles) > 0 and main.checkIfNodeDeleted(o.preview_move_tiles[len(o.preview_move_tiles)-1]) == false:
					o.set_next_preview_move_tile()
				if 'Node' in str(o.preview_tile) and main.checkIfNodeDeleted(o.preview_tile) == false and\
				   main.checkIfNodeDeleted(o.preview_tile.get_node("occupied_sprite")) == false:
					o.preview_tile.get_node("occupied_sprite").visible = true

		if game.level_over or not game.in_preview:
			return
		print('in preview_turn after obj and before proj')
		for projectile in projectiles:
			if projectile and main.checkIfNodeDeleted(projectile) == false and 'Node' in str(projectile) and projectile.active and not projectile.removing and\
			   main.checkIfNodeDeleted(projectile.current_tile) == false and main.checkIfNodeDeleted(projectile.get_node("preview_body")) == false:
				projectile.get_node("preview_body").position = projectile.get_node("body").position
				l.find_projectile_move_tiles(preview_step, projectile)
				if len(projectile.preview_move_tiles) > 0 and main.checkIfNodeDeleted(projectile.preview_move_tiles[len(projectile.preview_move_tiles)-1]) == false:
					projectile.set_next_preview_move_tile()
				projectile.get_node("preview_body").visible = true
		print('in preview_turn before player move and after proj')
		
		if game.level_over or not game.in_preview or should_end_preview:
			safely_out_of_preview = true
			l.center_objects_to_tile(true)
			if main.checkIfNodeDeleted(p) == false and main.checkIfNodeDeleted(p.current_tile) == false:
				p.preview_tile = p.current_tile
				p.preview_move_tiles = []
			return
		var timer2 = Timer.new()
		timer2.set_wait_time(object_move_time*1.4)
		timer2.set_one_shot(true)
		get_node("/root").add_child(timer2)
		timer2.start()
		yield(timer2, "timeout")
		timer2.queue_free()
		
		if game.level_over or not game.in_preview or should_end_preview:
			safely_out_of_preview = true
			l.center_objects_to_tile(true)
			if main.checkIfNodeDeleted(p) == false and main.checkIfNodeDeleted(p.current_tile) == false:
				p.preview_tile = p.current_tile
				p.preview_move_tiles = []
			return
		var timer2b = Timer.new()
		timer2b.set_wait_time(object_move_time*1.4)
		timer2b.set_one_shot(true)
		get_node("/root").add_child(timer2b)
		timer2b.start()
		yield(timer2b, "timeout")
		timer2b.queue_free()

		if main.checkIfNodeDeleted(p) == false and main.checkIfNodeDeleted(p.current_tile) == false:
			p.preview_tile = p.current_tile
			p.preview_move_tiles = []
		if game.level_over or not game.in_preview or should_end_preview:
			safely_out_of_preview = true
			l.center_objects_to_tile(true)
			return
		var timer3 = Timer.new()
		timer3.set_wait_time(object_move_time/2)
		timer3.set_one_shot(true)
		get_node("/root").add_child(timer3)
		timer3.start()
		yield(timer3, "timeout")
		timer3.queue_free()
		if game.level_over or not game.in_preview or should_end_preview:
			l.center_objects_to_tile(true)
			safely_out_of_preview = true
			return
