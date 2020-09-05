extends Node2D

var b6_default_speed = .3
var b6_slow_speed = .0
var b5_default_speed = .5
var b5_slow_speed = .0
var b4_default_speed = .7
var b4_slow_speed = .00
var b3_default_speed = 1.5
var b3_slow_speed = 0
var b2_default_speed = 1.3
var b2_slow_speed = .0
var b1_default_speed = 2
var b1_slow_speed = 0
var f1_default_speed = .85
var f1_slow_speed = .00
var f2_default_speed = .8
var f2_slow_speed = .0
var f3_default_speed = 10
var f3_slow_speed = .0

var sun_slow_speed = .2
var sun_default_speed = 1.2

var player_slow_speed = .02
var player_default_speed = .1

var smoke_slow_speed = .3
var smoke_default_speed = 5

var level_delta = 0
var t_buffer = 49
var start_buffer = 15
var starting_tile = null
var last_column_tiles = []
var first_column_tiles = []
var top_row_tiles = []
var row_2_tiles = []
var row_3_tiles = []
var row_4_tiles = []
var row_5_tiles = []
var row_6_tiles = []
var bottom_row_tiles = []
var level_tiles = []
var player_start_tile = null
var cam = null
var set_hazard = false
var set_hazard_idx = true
var current_hazard_type = 'movable'
var hazard_idx = 0

var foreground_default_height = 450
var foreground_high_height = 375
var foreground_low_height = 600
var no_player_count = 0

var repeat_player_tile_call = false

const ROW_BLOCK_Y_BUFFER = 4.5
const ROW_BLOCK_X_BUFFER = 45
const OBJ_ROW_BLOCK_SCALE = Vector2(.15, .098)

func _ready():
	game.level_won = false
	game.level_over = false
	game.moving_sun = false
	game.set_finish_tiles = false
	turn.handling_turn = false
	game.set_finish_col_idx = 0
	game.game_delta = 0
	game.global_move_buff = 0
	game.global_speed_buff = 0
	meta.clear_round_stat()
	turn.step_timer_max = turn.step_timer_max_default
	turn.step = turn.step_default
	starting_tile = get_node("starting_tile")
	game.player_stability = meta.savable.player.stability_max
	main.master_sound.get_node("chords").stop()
	main.master_sound.get_node("engine noise 1").stop()
	main.master_sound.get_node("engine noise 2").stop()
	main.master_sound.get_node("wind").play()
	main.master_sound.get_node("music 1").play()
	if meta.savable.player.character == 'SLICK':
		main.master_sound.get_node("engine noise 1").volume_db = -15
		main.master_sound.get_node("tech_passby").play()
		main.master_sound.get_node("engine noise 1").play()
	if meta.savable.player.character == 'TECH':
		main.master_sound.get_node("engine noise 2").volume_db = -20
		main.master_sound.get_node("engine_passby").play()
		main.master_sound.get_node("engine noise 2").play()
	if not meta.savable.had_tutorial:
		meta.handle_opening_tutorial()
	if game.object_chance <= 60:
		game.object_chance += 60
	if game.objs_per_turn < 1:
		game.objs_per_turn = 1
	if game.in_tutorial:
		turn.step = 6
	var tp = main.instancer(main.text_popup)
	tp.get_node('Label').set_text(game.set_tutorial_messages())
	tp.add_to_group("remove_tutorial")
	main.can_click_start = true
	game.handling_tutorial_messages = true
	while game.handling_tutorial_messages: # wait until input clears in main
		var timer = Timer.new()
		timer.set_wait_time(.1)
		timer.set_one_shot(true)
		get_node("/root").add_child(timer)
		timer.start()
		yield(timer, "timeout")
		timer.queue_free()
	for n in get_tree().get_nodes_in_group("remove_tutorial"):
		if n and n != null and main.checkIfNodeDeleted(n) == false:
			n.queue_free()

var removing = false
func destroy_self():
	if removing: return
	removing = true
	queue_free()

func add_level_hazard(remove=false):
	if remove:
		for t in get_tree().get_nodes_in_group("active_hazard_tile"):
			if current_hazard_type == 'movable':
				t.movable = true
			elif current_hazard_type == 'hazard':
				t.hazard = false
			t.texture_can_reset = true
			t.visible = true
			t.remove_from_group("active_hazard_tile")
		return

	if not set_hazard:
		return
	if set_hazard_idx:
		set_hazard_idx = false
		hazard_idx = len(row_2_tiles)
	hazard_idx -= 1
	if hazard_idx >= 0 and hazard_idx < len(row_3_tiles) and\
	   main.checkIfNodeDeleted(row_3_tiles[hazard_idx]) == false:
		row_3_tiles[hazard_idx].visible = false
		row_3_tiles[hazard_idx].texture_can_reset = false
		if current_hazard_type == 'movable':
			row_3_tiles[hazard_idx].movable = false
		elif current_hazard_type == 'hazard':
			row_3_tiles[hazard_idx].hazard = true
		row_3_tiles[hazard_idx].add_to_group("active_hazard_tile")
	if hazard_idx >= 0 and hazard_idx < len(row_2_tiles) and\
	   main.checkIfNodeDeleted(row_2_tiles[hazard_idx]) == false:
		row_2_tiles[hazard_idx].visible = false
		row_2_tiles[hazard_idx].texture_can_reset = false
		if current_hazard_type == 'movable':
			row_2_tiles[hazard_idx].movable = false
		elif current_hazard_type == 'hazard':
			row_2_tiles[hazard_idx].hazard = true
		row_2_tiles[hazard_idx].add_to_group("active_hazard_tile")
	else:
		set_hazard_idx = true
		set_hazard = false


func handle_background_anims(play=true):
	var foreground_1 = get_node("backgrounds/f3/ground")
	var foreground_2 = get_node("backgrounds/f3_2/ground")
	var player = get_node("/root/player")
	for child in get_node("backgrounds").get_children():
		if main.checkIfNodeDeleted(child) == false and 'anim' in child.name:
			if play:
				get_node("sun_imgs/sun_anim").playback_speed = sun_default_speed
				#player.get_node("body/anim_container1/smoke_imgs").modulate = Color(1, 1, 1, turn.step * .05)
				if main.checkIfNodeDeleted(player) == false:
					# shake changed in move next tile in player.gd
					#player.get_node("body/shake_anim").playback_speed = player_default_speed + (turn.step * .3)
					player.get_node("body/smoke_anim").playback_speed = smoke_default_speed
					player.get_node("body/smoke_shadow_anim").playback_speed = smoke_default_speed
				if 'b6' in child.name:
					child.playback_speed = b6_default_speed
				if 'b5' in child.name:
					child.playback_speed = b5_default_speed
				if 'b4' in child.name:
					child.playback_speed = b4_default_speed
				if 'b3' in child.name:
					child.playback_speed = b3_default_speed
				if 'b2' in child.name:
					child.playback_speed = b2_default_speed
				if 'b1' in child.name:
					child.playback_speed = b1_default_speed
				if 'f1' in child.name:
					child.playback_speed = f1_default_speed
				if 'f2' in child.name:
					child.playback_speed = f2_default_speed
				if 'f3' in child.name:
					child.playback_speed = f3_default_speed
			else:
				get_node("sun_imgs/sun_anim").playback_speed = sun_slow_speed
				if main.checkIfNodeDeleted(player) == false:
					# shake changed in move next tile in player.gd
					# player.get_node("body/shake_anim").playback_speed = player_slow_speed
					player.get_node("body/smoke_anim").playback_speed = smoke_slow_speed
					player.get_node("body/smoke_shadow_anim").playback_speed = smoke_slow_speed
				if 'b6' in child.name:
					child.playback_speed = b6_slow_speed
				if 'b5' in child.name:
					child.playback_speed = b5_slow_speed
				if 'b4' in child.name:
					child.playback_speed = b4_slow_speed
				if 'b3' in child.name:
					child.playback_speed = b3_slow_speed
				if 'b2' in child.name:
					child.playback_speed = b2_slow_speed
				if 'b1' in child.name:
					child.playback_speed = b1_slow_speed
				if 'f1' in child.name:
					child.playback_speed = f1_slow_speed
				if 'f2' in child.name:
					child.playback_speed = f2_slow_speed
				if 'f3' in child.name:
					child.playback_speed = f3_slow_speed

""" CAPTURE LOGIC, FUN IDEA BUT TOO HARDWARE INTENSIVE
var capture_count = .2
	capture_count -= delta
	if capture_count <= 0:
		capture_count = .2
		if turn.handling_turn:
			meta.get_capture()
"""

func _process(delta):
	level_delta = delta
	if not get_node("/root").has_node("player"):
		no_player_count += delta
		if no_player_count >= 2:
			game.end_level()
			return
	handle_round_timer()
	if get_node("text_container/steps").get_text() != "Speed: " + str(turn.step):
		get_node("text_container/steps").set_text("Speed: " + str(turn.step))
	if get_node("text_container/total steps").get_text() != "Steps: " + str(meta.round_stats.steps_taken_in_level) + '/' + str(overworld.level_step_target):
		get_node("text_container/total steps").set_text("Steps: " + str(meta.round_stats.steps_taken_in_level) + '/' + str(overworld.level_step_target))


func handle_round_timer():
	if game.in_tutorial or\
	   not turn.step_timer_can_change or\
	   game.level_over:
		return
	
	print('in tut ' + str(game.in_tutorial))
	turn.step_timer = stepify(turn.step_timer - level_delta, .01)
	if turn.step_timer <= 0:
		turn.step_timer = 0
		turn.step_timer_max -= turn.timer_missed_turn_change
		turn.play_card(true)
		turn.step_timer = turn.step_timer_max

	if turn.step_timer_max > turn.step_timer_max_default:
		turn.step_timer_max = turn.step_timer_max_default

	if get_node("text_container/turn_counter").get_text() != str(turn.step_timer) + ' / ' + str(turn.step_timer_max):
		get_node("text_container/turn_counter").set_text(str(turn.step_timer) + ' / ' + str(turn.step_timer_max))
	if get_node("text_container/stability").get_text() != 'Stability: ' + str(game.player_stability) + ' / ' + str(meta.savable.player.stability_max):
		get_node("text_container/stability").set_text('Stability: ' + str(game.player_stability) + ' / ' + str(meta.savable.player.stability_max))


func spawn_enemies():
	var available_tiles = []
	for t in first_column_tiles:
		if 'Node' in str(t) and main.checkIfNodeDeleted(t) == false:
			if not t.has_enemy and not t.hazard and not t.has_player and\
			   not t.has_projectile and not t.has_object and t.movable:
				available_tiles.append(t)
	if len(available_tiles) <= 0:
		return
	var e = main.instancer(main.ENEMY, null, false)
	e.current_tile = available_tiles[rand_range(0, len(available_tiles))]
	e.current_tile.add_to_group("active_tile")
	e.position = e.current_tile.global_position
	e.tile_index = e.current_tile.index
	e.previous_tile = e.current_tile
	e.current_tile.has_enemy = true
	e.preview_tile = e.current_tile
	find_enemy_move_tiles(turn.step, e)


func spawn_player():
	if not player_start_tile:
		#print('no player_start_tile to spawn player???')
		return
	var p = main.instancer(main.PLAYER)
	p.current_tile = player_start_tile
	p.current_tile.add_to_group("active_tile")
	p.position = p.current_tile.global_position
	p.previous_tile = p.current_tile
	p.tile_index = p.current_tile.index
	p.preview_tile = p.current_tile
	find_player_move_tiles(turn.step, p)
	p.get_neighbors()
	game.set_initial_deck()
	game.draw()
	#print('PLAYER spawned at pos ' + str(p.position))


func center_objects_to_tile(preview=false):
	var p = get_node("/root/player")
	var p_body_path = "body" if not game.in_preview else "preview_body"

	if main.checkIfNodeDeleted(p) == false and p.has_node("body"):
		if main.checkIfNodeDeleted(p.current_tile) == false and main.checkIfNodeDeleted(p.preview_tile) == false:
			var p_move_tile = p.current_tile if not preview else p.preview_tile
			if game.in_preview: # hold spot for base image
				if p.get_node("body").global_position != p.current_tile.global_position:
					p.get_node("body").global_position = p.current_tile.global_position
			if p.has_node(p_body_path) and main.checkIfNodeDeleted(p.get_node(p_body_path)) == false and\
			   p.get_node(p_body_path).global_position != p_move_tile.global_position:
				p.get_node(p_body_path).global_position = p_move_tile.global_position

	for o in get_tree().get_nodes_in_group("active_objects"):
		if main.checkIfNodeDeleted(o) == false and o.active and\
		   main.checkIfNodeDeleted(o.get_node("body")) == false and\
		   main.checkIfNodeDeleted(o.get_node("preview_body")) == false and\
		   main.checkIfNodeDeleted(o.current_tile) == false and\
		   main.checkIfNodeDeleted(o.preview_tile) == false:
			var move_tile = o.current_tile if not preview else o.preview_tile
			var body_path = "body" if not game.in_preview else "preview_body"
			if game.in_preview: # hold spot for base image
				if o.get_node("body").global_position != o.current_tile.global_position:
					o.get_node("body").global_position = o.current_tile.global_position
			if o.get_node(body_path).global_position != move_tile.global_position:
				o.get_node(body_path).global_position = move_tile.global_position
	for projectile in get_tree().get_nodes_in_group("projectile"):
		if main.checkIfNodeDeleted(projectile) == false and projectile.active and\
		   main.checkIfNodeDeleted(projectile.get_node("body")) == false and\
		   main.checkIfNodeDeleted(projectile.get_node("preview_body")) == false and\
		   main.checkIfNodeDeleted(projectile.current_tile) == false and\
		   main.checkIfNodeDeleted(projectile.preview_tile) == false:
			var move_tile = projectile.current_tile if not preview else projectile.preview_tile
			var body_path = "body" if not game.in_preview else "preview_body"
			if game.in_preview: # hold spot for base image
				if projectile.get_node("body").global_position != projectile.current_tile.global_position:
					projectile.get_node("body").global_position = projectile.current_tile.global_position
			if projectile.has_node(body_path) and projectile.get_node(body_path).global_position != move_tile.global_position:
				projectile.get_node(body_path).global_position = move_tile.global_position
	for e in get_tree().get_nodes_in_group("active_enemies"):
		if main.checkIfNodeDeleted(e) == false and e.active and\
		   main.checkIfNodeDeleted(e.get_node("body")) == false and\
		   main.checkIfNodeDeleted(e.get_node("preview_body")) == false and\
		   main.checkIfNodeDeleted(e.current_tile) == false and\
		   main.checkIfNodeDeleted(e.preview_tile) == false:
			var move_tile = e.current_tile if not preview else e.preview_tile
			var body_path = "body" if not game.in_preview else "preview_body"
			if game.in_preview: # hold spot for base image
				if e.get_node("body").global_position != e.current_tile.global_position:
					e.get_node("body").global_position = e.current_tile.global_position
			if e.has_node(body_path) and e.get_node(body_path).global_position != move_tile.global_position:
				e.get_node(body_path).global_position = move_tile.global_position


func clear_tile_vars():
	# for t in get_tree().get_nodes_in_group("active_tile"):
	for t in get_tree().get_nodes_in_group("tile"):
		if main.checkIfNodeDeleted(t) == false and main.checkIfNodeDeleted(t.get_node("Sprite")) == false and\
			main.checkIfNodeDeleted(t.get_node("occupied_sprite")) == false:
			# we clear has_object so we check if has obj and not movable 
			# (meaning new object going over previously clear space
			# and if true going_from_no_move_to_obj means to set texture back to normal
			if t.has_object and not t.movable:
				t.going_from_no_move_to_obj = false

			t.modulate = Color(1, 1, 1, 1)
			if t.movable:
				t.get_node("Sprite").modulate = Color(.2, .2, .2, .05)
			else:
				t.get_node("Sprite").modulate = Color(1, 1, 1, 1)
			if t.has_object:
				t.get_node("occupied_sprite").visible = true
				t.texture_can_reset = false
				t.get_node("occupied_sprite").set_texture(main.TAN_TILE)

			t.has_object = false
			t.has_projectile = false
			t.has_player = false
			t.has_enemy = false
			t.has_two_enms = false
			t.has_two_objs = false
			t.has_two_projs = false

			t.player_can_be_hurt = false
			t.player_invincible = false
			t.player_can_crash = false
			t.player_in_air = false
			t.player_can_be_shot = false
	
			t.previous_obstacle_dir = ''
			t.player_str = ''
			t.proj_str = ''
			t.enm_str = ''
			t.obj_str = ''
			
			if t.hazard and t.movable:
				t.get_node("Sprite").visible = true
				#t.get_node("Sprite").modulate = Color(1, 0, 0, 1)
				t.get_node("occupied_sprite").set_texture(main.WARNING_SYMBOL)
				t.get_node("occupied_sprite").visible = true
				t.get_node("occupied_sprite").set_scale(Vector2(.08, .08))
			else:
				if t.texture_can_reset and t.get_node("Sprite").get_texture() != main.GRID_TILE:
					t.get_node("Sprite").set_texture(main.GRID_TILE)
				t.get_node("occupied_sprite").set_texture(main.DARK_YELLOW_TILE)
				t.get_node("occupied_sprite").visible = false
				t.get_node("occupied_sprite").set_scale(Vector2(.13, .13))

			t.z_index = t.hold_z_idx
			t.get_node("occupied_sprite").modulate = Color(1, 1, 1, 1)
			t.can_collide = false
			if t.is_in_group("active_tile"):
				t.remove_from_group("active_tile")
			if game.set_finish_tiles:
				if t.row >= meta.savable.row - game.set_finish_col_idx:
					t.finish = true

	for t in get_tree().get_nodes_in_group("tile"):
		if main.checkIfNodeDeleted(t) == false and main.checkIfNodeDeleted(t.get_node("Sprite")) == false and\
			main.checkIfNodeDeleted(t.get_node("occupied_sprite")) == false:
			if t.movable:
				continue
			else:
				t.get_node("occupied_sprite").set_scale(Vector2(.13, .13))
				get_pit_sprite(t)
			if t.finish:
				t.get_node("Sprite").visible = true
				t.get_node("Sprite").set_texture(main.CHECKER)
				t.get_node("Sprite").modulate = game.finish_tile_color


func check_tiles_for_collisions():
	""" 
		To avoid checking nodes we remove instead check flags on tiles (which are not removed except at level end)
		and determine collisions from the flags
	"""
	# for t in get_tree().get_nodes_in_group("active_tile"):
	for t in get_tree().get_nodes_in_group("tile"):
		if main.checkIfNodeDeleted(t) == false:
			pass


func get_pit_sprite(t, return_texture=false, obj=false, obj_is_not_pit=false):
	var above_idx = 0
	var below_idx = 0
	var sprite_path = 'occupied_sprite'
	if obj:
		if obj_is_not_pit:
			sprite_path = 'body/pit_sprite'
		else:
			sprite_path = 'body/Sprite'
	if not obj:
		above_idx = t.index - meta.savable.row - 1
		below_idx = t.index + meta.savable.row - 1
		t.get_node("Sprite").visible = false
	else:
		if main.checkIfNodeDeleted(t.current_tile) == false:
			if not obj_is_not_pit: t.get_node(sprite_path).set_scale(OBJ_ROW_BLOCK_SCALE)
			above_idx = t.current_tile.index - meta.savable.row - 1
			below_idx = t.current_tile.index + meta.savable.row - 1
		else:
			return
	var pit_above = false
	var pit_below = false
	# TODO: reverse logic so surrounding unmovable tiles switch to have correct edging
	if above_idx >= 0 and above_idx < len(level_tiles) and\
	   not level_tiles[above_idx].movable:
		pit_above = true
		pass
	if below_idx >= 0 and below_idx < len(level_tiles) and\
	   not level_tiles[below_idx].movable:
		pit_below = true
	if pit_below and pit_above:
		if obj:
			t.get_node(sprite_path).set_texture(main.PIT_OBJ_OPEN)
		else:
			t.get_node(sprite_path).set_texture(main.PIT_OPEN_TILE)
		if return_texture: return main.PIT_OPEN_TILE
		# make connecting top and bottom tile
	else:
		if pit_below:
			if obj:
				t.get_node(sprite_path).set_texture(main.PIT_OBJ_BOTTOM_OPEN)
			else:
				t.get_node(sprite_path).set_texture(main.PIT_TOP_TILE)
			if return_texture: return main.PIT_TOP_TILE
			# make belowconnecting sprite
		elif pit_above:
			if obj:
				t.get_node(sprite_path).set_texture(main.PIT_OBJ_TOP_OPEN)
			else:
				t.get_node(sprite_path).set_texture(main.PIT_BOTTOM_TILE)
			if return_texture: return main.PIT_BOTTOM_TILE
		else:
			if obj:
				t.get_node(sprite_path).set_texture(main.PIT_OBJ_CLOSED)
			else:
				t.get_node(sprite_path).set_texture(main.PIT_TILE)
			if return_texture: return main.PIT_TILE
	if not obj:
		t.get_node(sprite_path).visible = true


func spawn_projectiles(parent, payload={'can_hurt_player': false,
										'aoe': 0, 'mine': false, 'floater': false}):
	if main.checkIfNodeDeleted(parent) == true and main.checkIfNodeDeleted(parent.current_tile) == false:
		return
	var p = main.instancer(main.PROJECTILE)
	var e = main.instancer(main.explosion_scene)
	e.get_node("AnimationPlayer").play("explosion small")
	p.current_tile = parent.current_tile
	p.can_hurt_player = payload['can_hurt_player']
	p.explode_aoe = payload['aoe']
	p.mine = payload['mine']
	p.floater = payload['floater']
	p.parent = str(parent)
	p.current_tile.can_collide = true
	p.current_tile.has_projectile = true
	p.previous_tile = p.current_tile
	p.preview_tile = p.current_tile
	p.position = parent.current_tile.global_position
	e.position = p.global_position
	p.tile_index = parent.current_tile.index
	p.speed = turn.step_timer

	if p.floater:
		p.set_scale(Vector2(.15, .15))
		p.get_node("AnimationPlayer").play("floater")
		p.dir = 'left'
	if p.mine:
		p.get_node("AnimationPlayer").play("mine")
		p.dir = 'left'
	find_projectile_move_tiles(p.speed, p)
	return p


func spawn_objects():
	if len(last_column_tiles) <= 0:
		#print('no last_column_tiles to spawn object???')
		return

	var available_tiles = []
	var is_row_block = false
	if rand_range(0, 100) <= game.obj_row_block_chance:
		is_row_block = true

	for t in last_column_tiles:
		if t != last_column_tiles[0]:
			if not t.has_enemy and not t.strict_hazard and not t.has_player and\
			   not t.has_object and not t.strict_immovable:
				if not is_row_block or is_row_block and t.movable:
					available_tiles.append(t)

	if len(available_tiles) <= 0:
		return
	var chosen_spawn_tile = available_tiles[rand_range(0, len(available_tiles))]
	if is_row_block and not chosen_spawn_tile.movable:
		return
	var o = main.instancer(main.OBJECT, null, false)
	var rand_obj = main.object_imgs[rand_range(0, len(main.object_imgs))]

	o.is_row_block = is_row_block
	if is_row_block:
		o.get_node("body/Sprite").set_texture(main.PIT_OBJ_CLOSED)
		o.get_node("body/Sprite").set_scale(OBJ_ROW_BLOCK_SCALE)
		o.get_node("body/Sprite").position.y += ROW_BLOCK_Y_BUFFER
		o.get_node("body/Sprite").position.x -= ROW_BLOCK_X_BUFFER
	else:
		if not chosen_spawn_tile.movable:
			o.get_node("body/pit_sprite").visible = true
		o.get_node("body/Sprite").set_texture(rand_obj['img'])
		o.get_node("body/Sprite").set_scale(rand_obj['size'])
	o.get_node("body/shadow").set_texture(rand_obj['img'])
	o.get_node("preview_body/Sprite").set_texture(rand_obj['img'])
	o.get_node("preview_body/shadow").set_texture(rand_obj['img'])
	o.get_node("body/shadow").set_scale(rand_obj['size'])
	o.get_node("preview_body/Sprite").set_scale(rand_obj['size'])
	o.get_node("preview_body/shadow").set_scale(rand_obj['size'])
	o.get_node("body/shadow").rotation = rand_obj['shadow_rotation']
	o.get_node("preview_body/shadow").rotation = rand_obj['shadow_rotation']
	o.current_tile = chosen_spawn_tile
	o.current_tile.add_to_group("active_tile")
	o.previous_tile = o.current_tile
	o.position = o.current_tile.global_position
	o.tile_index = o.current_tile.index
	o.preview_tile = o.current_tile
	o.current_tile.has_object = true
	find_object_move_tiles(turn.step, o)


func spawn_tiles():
	var col = meta.savable.col
	var row = meta.savable.row
	var tc = get_node("tile_container")
	if not starting_tile:
		starting_tile = get_node("starting_tile")
	var tile_count = 0
	for c in range(0, col):
		for r in range(0, row):
			tile_count += 1
			var t = main.TILE.instance()
			get_node("tile_container").add_child(t)
			t.row = r
			t.col = c
			level_tiles.append(t)
			t.z_index = tile_count
			t.hold_z_idx = tile_count
			t.index = tile_count
			if c == 4 and r == 10:
				player_start_tile = t
			if tile_count <= 1:
				t.position = starting_tile.global_position
			else:
				t.position = Vector2(starting_tile.global_position.x +\
									(r * t_buffer),\
									starting_tile.global_position.y +\
									(c * t_buffer))
			if r == row-1:
				last_column_tiles.append(t)
				#t.modulate = Color(0, 1, 0, 1)
			elif r == 0:
				first_column_tiles.append(t)
				#t.modulate = Color(1, 1, 0, 1)
			elif c == 0:
				top_row_tiles.append(t)
				#t.modulate = Color(1, 0, 1, 1)
				
			elif c == 1:
				row_2_tiles.append(t)
			elif c == 2:
				row_3_tiles.append(t)
			elif c == 3:
				row_4_tiles.append(t)
			elif c == 4:
				row_5_tiles.append(t)
			elif c == 5:
				row_6_tiles.append(t)
			elif c == col-1:
				bottom_row_tiles.append(t)
				#t.modulate = Color(1, 0, 0, 1)


func get_varied_movement(dir='right'):
	# move at an angle, not by choice
	# use case, in air trying to move
	var rand_num = rand_range(0, 1)
	if dir == 'right': return 'up_right' if rand_num < .5 else 'down_right'
	if dir == 'left': return 'up_left' if rand_num < .5 else 'down_left'
	if dir == 'up': return 'up_right' if rand_num < .5 else 'up_left'
	if dir == 'down': return 'down_right'  if rand_num < .5 else 'down_left'
	
	return dir


func find_player_move_tiles(steps, p, dir='right', mod=0):
	p.move_tiles = []
	p.preview_move_tiles = []
	var col = meta.savable.col
	var row = meta.savable.row
	var l_mod = 2
	var r_mod = 0
	var u_mod = 0
	var d_mod = 0
	var first_dir = ''
	var last_dir = ''
	if dir == 'none':
		return
	if p.player_in_air:
		dir = get_varied_movement(dir)
	#if '_' in dir:
	#	first_dir = dir.split('_')[0]
	#	last_dir = dir.split('_')[1]
	#	dir = first_dir
	for i in range(0, steps):
		#if last_dir != '' and i == steps-1:
		#	dir = last_dir
		if dir == 'right':
			var right_idx = p.current_tile.index + ((i + r_mod) + mod)
			if right_idx < len(level_tiles) and right_idx > 0 and\
				   main.checkIfNodeDeleted(level_tiles[right_idx]) == false:
				if not level_tiles[right_idx].movable and not p.player_in_air and not i == steps: return
				if p.current_tile.row < meta.savable.row-1:
					if game.in_preview:
						p.preview_move_tiles.append(level_tiles[right_idx])
					else:
						p.move_tiles.append(level_tiles[right_idx])
		elif dir == 'left':
			var left_idx = p.current_tile.index - ((i + l_mod) - mod)
			if left_idx < len(level_tiles) and left_idx > 0 and\
				   main.checkIfNodeDeleted(level_tiles[left_idx]) == false:
				if not level_tiles[left_idx].movable and not p.player_in_air and not i == steps: return
				if p.current_tile.row >= 1:
					if game.in_preview:
						p.preview_move_tiles.append(level_tiles[left_idx])
					else:
						p.move_tiles.append(level_tiles[left_idx])
		elif dir == 'up':
			if mod == 0: mod = 1
			var up_idx = p.current_tile.index - ((i+1) * (row * mod)) - 1
			if up_idx < len(level_tiles) and up_idx > 0 and\
				   main.checkIfNodeDeleted(level_tiles[up_idx]) == false:
				if not level_tiles[up_idx].movable and not p.player_in_air and not i == steps: return
				if p.current_tile.col != 0:
					if game.in_preview:
						p.preview_move_tiles.append(level_tiles[up_idx])
					else:
						p.move_tiles.append(level_tiles[up_idx])
		elif dir == 'down':  # down
			if mod == 0: mod = 1
			var down_idx = p.current_tile.index + ((i+1) * (row * mod)) - 1
			if down_idx < len(level_tiles) and down_idx > 0 and\
				   main.checkIfNodeDeleted(level_tiles[down_idx]) == false:
				if not level_tiles[down_idx].movable and not p.player_in_air and not i == steps: return
				if p.current_tile.col != meta.savable.col-1:
					if game.in_preview:
						p.preview_move_tiles.append(level_tiles[down_idx])
					else:
						p.move_tiles.append(level_tiles[down_idx])
		if dir == 'right_up':
			if mod == 0: mod = 1
			var right_idx = p.current_tile.index - ((i + 1) * (row * mod)) - 1
			if right_idx < len(level_tiles) and right_idx > 0 and\
				   main.checkIfNodeDeleted(level_tiles[right_idx]) == false:
				if not level_tiles[right_idx].movable and not p.player_in_air and not i == steps: return
				if p.current_tile.row < meta.savable.row-1 and p.current_tile.col != 0:
					if game.in_preview:
						p.preview_move_tiles.append(level_tiles[right_idx])
					else:
						p.move_tiles.append(level_tiles[right_idx])
		if dir == 'left_up':
			if mod == 0: mod = 1
			var right_idx = p.current_tile.index - ((i + 1) * (row * mod)) - 1
			if right_idx < len(level_tiles) and right_idx > 0 and\
				   main.checkIfNodeDeleted(level_tiles[right_idx]) == false:
				if not level_tiles[right_idx].movable and not p.player_in_air and not i == steps: return
				if p.current_tile.row >= 1 and p.current_tile.col != 0:
					if game.in_preview:
						p.preview_move_tiles.append(level_tiles[right_idx])
					else:
						p.move_tiles.append(level_tiles[right_idx])
		if dir == 'right_down':
			if mod == 0: mod = 1
			var right_idx = p.current_tile.index + ((i + 1) * (row * mod)) - 1
			if right_idx < len(level_tiles) and right_idx > 0 and\
				   main.checkIfNodeDeleted(level_tiles[right_idx]) == false:
				if not level_tiles[right_idx].movable and not p.player_in_air and not i == steps: return
				if p.current_tile.row < meta.savable.row-1 and  p.current_tile.col != meta.savable.col-1:
					if game.in_preview:
						p.preview_move_tiles.append(level_tiles[right_idx])
					else:
						p.move_tiles.append(level_tiles[right_idx])
		if dir == 'left_down':
			if mod == 0: mod = 1
			var right_idx = p.current_tile.index + ((i + 1) * (row * mod)) - 1
			if right_idx < len(level_tiles) and right_idx > 0 and\
				   main.checkIfNodeDeleted(level_tiles[right_idx]) == false:
				if not level_tiles[right_idx].movable and not p.player_in_air and not i == steps: return
				if p.current_tile.row >= 1 and p.current_tile.col != meta.savable.col-1:
					if game.in_preview:
						p.preview_move_tiles.append(level_tiles[right_idx])
					else:
						p.move_tiles.append(level_tiles[right_idx])
		elif dir == 'up_right':
			if mod == 0: mod = 1
			var up_idx = p.current_tile.index - ((i+1) * (row * mod))
			if up_idx < len(level_tiles) and up_idx > 0 and\
				   main.checkIfNodeDeleted(level_tiles[up_idx]) == false:
				if not level_tiles[up_idx].movable and not p.player_in_air and not i == steps: return
				if p.current_tile.col != 0 and p.current_tile.row < meta.savable.row-1:
					if game.in_preview:
						p.preview_move_tiles.append(level_tiles[up_idx])
					else:
						p.move_tiles.append(level_tiles[up_idx])
		if dir == 'up_left':
			if mod == 0: mod = 1
			var right_idx = p.current_tile.index - ((i + 1) * (row * mod)) - 2
			if right_idx < len(level_tiles) and right_idx > 0 and\
				   main.checkIfNodeDeleted(level_tiles[right_idx]) == false:
				if not level_tiles[right_idx].movable and not p.player_in_air and not i == steps: return
				if p.current_tile.row >= 1:
					if game.in_preview:
						p.preview_move_tiles.append(level_tiles[right_idx])
					else:
						p.move_tiles.append(level_tiles[right_idx])
		elif dir == 'down_right':
			if mod == 0: mod = 1
			var up_idx = p.current_tile.index + ((i+1) * (row * mod))
			if up_idx < len(level_tiles) and up_idx > 0 and\
				   main.checkIfNodeDeleted(level_tiles[up_idx]) == false:
				if not level_tiles[up_idx].movable and not p.player_in_air and not i == steps: return
				if p.current_tile.row < meta.savable.row-1 and p.current_tile.col != meta.savable.col-1:
					if game.in_preview:
						p.preview_move_tiles.append(level_tiles[up_idx])
					else:
						p.move_tiles.append(level_tiles[up_idx])
		if dir == 'down_left':
			if mod == 0: mod = 1
			var right_idx = p.current_tile.index + ((i + 1) * (row * mod)) - 2
			if right_idx < len(level_tiles) and right_idx > 0 and\
				   main.checkIfNodeDeleted(level_tiles[right_idx]) == false:
				if not level_tiles[right_idx].movable and not p.player_in_air and not i == steps: return
				if p.current_tile.row >= 1 and p.current_tile.col != meta.savable.col-1:
					if game.in_preview:
						p.preview_move_tiles.append(level_tiles[right_idx])
					else:
						p.move_tiles.append(level_tiles[right_idx])


func find_enemy_move_tiles(steps, e, dir='right', mod=0):
	e.move_tiles = []
	e.preview_move_tiles = []
	var col = meta.savable.col
	var row = meta.savable.row
	var l_mod = 2
	var r_mod = 0
	var u_mod = 0
	var d_mod = 0

	if dir == 'none':
		return
	for i in range(0, steps):
		if main.checkIfNodeDeleted(e) == false and\
		   main.checkIfNodeDeleted(e.current_tile) == false:
			if dir == 'right':
				var right_idx = e.current_tile.index + ((i + r_mod) + mod)
				if right_idx < len(level_tiles) and right_idx > 0 and\
				   main.checkIfNodeDeleted(level_tiles[right_idx]) == false:
					if not level_tiles[right_idx].movable and not i == steps: return
					if e.current_tile.row < meta.savable.row-1:
						if game.in_preview:
							e.preview_move_tiles.append(level_tiles[right_idx])
						else:
							e.move_tiles.append(level_tiles[right_idx])
			elif dir == 'left':
				var left_idx = e.current_tile.index - ((i + l_mod) - mod)
				if left_idx < len(level_tiles) and left_idx > 0 and\
				   main.checkIfNodeDeleted(level_tiles[left_idx]) == false:
					if not level_tiles[left_idx].movable and not i == steps: return
					if e.current_tile.row >= 1:
						if game.in_preview:
							e.preview_move_tiles.append(level_tiles[left_idx])
						else:
							e.move_tiles.append(level_tiles[left_idx])
			elif dir == 'up':
				if mod == 0: mod = 1
				var up_idx = e.current_tile.index - ((i+1) * (row * mod)) - 1
				if up_idx < len(level_tiles) and up_idx > 0 and\
				   main.checkIfNodeDeleted(level_tiles[up_idx]) == false:
					if not level_tiles[up_idx].movable and not i == steps: return
					if e.current_tile.col != 0:
						if game.in_preview:
							e.preview_move_tiles.append(level_tiles[up_idx])
						else:
							e.move_tiles.append(level_tiles[up_idx])
			elif dir == 'down':  # down
				if mod == 0: mod = 1
				var down_idx = e.current_tile.index + ((i+1) * (row * mod)) - 1
				if down_idx < len(level_tiles) and down_idx > 0 and\
				   main.checkIfNodeDeleted(level_tiles[down_idx]) == false:
					if not level_tiles[down_idx].movable and not i == steps: return
					if e.current_tile.col != meta.savable.col-1:
						if game.in_preview:
							e.preview_move_tiles.append(level_tiles[down_idx])
						else:
							e.move_tiles.append(level_tiles[down_idx])


func find_projectile_move_tiles(steps, p, mod=0):
	p.move_tiles = []
	p.preview_move_tiles = []
	steps = p.speed
	if p.dir == 'none':
		return
	var col = meta.savable.col
	var row = meta.savable.row
	var dir = p.dir

	var l_mod = 2
	var r_mod = 0
	var u_mod = 0
	var d_mod = 0
	for i in range(0, steps):
		if main.checkIfNodeDeleted(p) == false and\
		   main.checkIfNodeDeleted(p.current_tile) == false:
			if dir == 'right':
				var right_idx = p.current_tile.index + ((i + r_mod) + mod)
				if right_idx < len(level_tiles) and right_idx > 0 and\
				   main.checkIfNodeDeleted(level_tiles[right_idx]) == false:
					if p.current_tile.row < meta.savable.row-1 and level_tiles[right_idx].movable:
						if game.in_preview:
							p.preview_move_tiles.append(level_tiles[right_idx])
						else:
							p.move_tiles.append(level_tiles[right_idx])
			elif dir == 'left':
				var left_idx = p.current_tile.index - ((i + l_mod) - mod)
				if left_idx < len(level_tiles) and left_idx > 0 and\
				   main.checkIfNodeDeleted(level_tiles[left_idx]) == false:
					if p.current_tile.row >= 1 and level_tiles[left_idx].movable:
						if game.in_preview:
							p.preview_move_tiles.append(level_tiles[left_idx])
						else:
							p.move_tiles.append(level_tiles[left_idx])
			elif dir == 'up':
				if mod == 0: mod = 1
				var up_idx = p.current_tile.index - ((i+1) * (row * mod)) - 1
				if up_idx < len(level_tiles) and up_idx > 0 and\
				   main.checkIfNodeDeleted(level_tiles[up_idx]) == false:
					if p.current_tile.col != 0 and level_tiles[up_idx].movable:
						if game.in_preview:
							p.preview_move_tiles.append(level_tiles[up_idx])
						else:
							p.move_tiles.append(level_tiles[up_idx])
			elif dir == 'down':
				if mod == 0: mod = 1
				var down_idx = p.current_tile.index + ((i+1) * (row * mod)) - 1
				if down_idx < len(level_tiles) and down_idx > 0 and\
				   main.checkIfNodeDeleted(level_tiles[down_idx]) == false:
					if p.current_tile.col != meta.savable.col-1 and level_tiles[down_idx].movable:
						if game.in_preview:
							p.preview_move_tiles.append(level_tiles[down_idx])
						else:
							p.move_tiles.append(level_tiles[down_idx])


func find_object_move_tiles(steps, o):
	o.move_tiles = []
	o.preview_move_tiles = []
	var col = meta.savable.col
	var row = meta.savable.row
	for i in range(0, steps):
		if game.in_preview:
			o.preview_move_tiles.append(level_tiles[o.tile_index-(i+2)])
		else:
			o.move_tiles.append(level_tiles[o.tile_index-(i+2)])


func _on_global_sun_anim_animation_finished(anim_name):
	game.moving_sun = false
