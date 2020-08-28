extends Node2D

var can_collide = true
var move_tiles = []
var preview_move_tiles = []
var current_tile = null
var preview_tile = null
var should_move = false
var previous_tile = null
var affected_neighbors = []
var move_to_pos = null
var tile_index = 0
var velocity = Vector2(0, 0)
var active = true
var active_neighbors = []
var crashing = false
var crash_counter = 0
var crash_limit = 3
var move_speed = 2
var move_dir = 'right'
var dirs = ['left', 'right', 'up', 'down', 'right_down', 'left_down',
				'right_up', 'left_up']

func _ready():
	var r = rand_range(.7, 1)
	var g = rand_range(.7, 1)
	var b = rand_range(.7, 1)
	get_node("body/anim_container1").modulate = Color(r, g, b, 1)


func set_next_move_tile_group():
	get_node("/root/level").find_object_move_tiles(turn.step, self)


func get_enemy_direction():
	var p = get_node("/root/player")
	move_dir = 'none'
	if p.current_tile.row != current_tile.row:
		if move_dir != 'none' or rand_range(0, 1) >= .7:
			if p.current_tile.col > current_tile.col:
				move_dir = 'down'
			else:
				move_dir = 'up'
		else:
			if p.current_tile.row > current_tile.row:
				move_dir = 'right'
			elif p.current_tile.row < current_tile.row:
				move_dir = 'left'
	else:
		if p.current_tile.col > current_tile.col:
			move_dir = 'down'
		else:
			move_dir = 'up'
	


func set_next_move_tile(s):
	previous_tile = current_tile
	current_tile = move_tiles[s]
	
	var move_len = len(move_tiles)
	if move_dir != 'right':
		previous_tile = current_tile
	if move_dir == 'up' and s == 0:
		get_node("turn_anim_enm").play("cart_turn_up_enm")
	elif move_dir == 'down' and s == 0:
		get_node("turn_anim_enm").play("cart_turn_down_enm")

	if move_dir != 'right':
		previous_tile = current_tile
	#current_tile.get_node("Sprite").modulate = meta.tile_occupied_color
	current_tile.z_index = 300
	#current_tile.get_node("Sprite").set_texture(main.DARK_BLUE_TILE)
	current_tile.add_to_group("active_tile")
	set_tile_values(current_tile)
	# this should be callable just with setting the turn.turn_timer to 0, and all object process should pick it up, otherwise turn.turn_timer should = turn.turn_timer_max to pause
	handle_current_step()

func set_next_preview_move_tile():
	preview_tile = preview_move_tiles[len(preview_move_tiles)-1]
	if main.checkIfNodeDeleted(preview_tile) == false:
		preview_tile.get_node("occupied_sprite").modulate = Color(1, .4, .4, 1)
	#preview_tile.add_to_group("active_tile")
	#set_tile_values(preview_tile)
	handle_current_step()


func handle_current_step():
	""" Set tile stuff and allow movement"""
	should_move = true
	var new_shadow_mod = 1.25 - (current_tile.row * .04)
	var x_mod = (current_tile.row * meta.shadow_pos_x_global_mode)
	var y_mod = (current_tile.row * meta.shadow_pos_y_global_mode)
	if new_shadow_mod < meta.global_shadow_modulate_min:
		new_shadow_mod = meta.global_shadow_modulate_min
	if new_shadow_mod > meta.global_shadow_modulate_max:
		new_shadow_mod = meta.global_shadow_modulate_max


func check_tile_based_collision():
	# Check if has_two_objs in validate collision then we can remove all objs that share this
	var should_destroy = false
	if main.checkIfNodeDeleted(current_tile) == false:
		# first check immediate collisions
		if current_tile.has_two_enms or\
		   current_tile.has_projectile or\
		   current_tile.has_object or\
		   current_tile.has_player:
			# we are here because we possibly collided with a something on a previous tile 
			should_destroy = true
			if current_tile.has_player and not current_tile.has_two_enms and\
			   not current_tile.has_projectile and not current_tile.has_object:
				if not current_tile.player_can_crash or current_tile.player_in_air:
					# we are here because the player also is, but is above us
					should_destroy = false
			if current_tile.has_two_enms:
				if game.regen_on_enm:
					game.player_stability += game.regen_val * 2

			if should_destroy: handle_crash()

	should_destroy = false
	if not removing and main.checkIfNodeDeleted(previous_tile) == false:
		# next check collisions from passover conditions
		if previous_tile.has_two_enms or\
		   previous_tile.has_projectile and str(self) != current_tile.enm_str or\
		   previous_tile.has_object or\
		   previous_tile.has_player:
			if move_dir == 'left' and previous_tile.previous_obstacle_dir == 'right' or\
			   move_dir == 'up' and previous_tile.previous_obstacle_dir == 'down' or\
			   move_dir == 'right' and previous_tile.previous_obstacle_dir == 'left' or\
			   move_dir == 'down' and previous_tile.previous_obstacle_dir == 'up':
				# we are here because we possibly collided with a something on a previous tile 
				should_destroy = true
				if previous_tile.has_player and not previous_tile.has_two_enms and\
				   not previous_tile.has_projectile and not previous_tile.has_object:
					if main.checkIfNodeDeleted(current_tile) == false and current_tile.player_in_air or\
					   previous_tile.player_in_air or main.checkIfNodeDeleted(current_tile) == false and\
					   not current_tile.player_can_crash or not previous_tile.player_can_crash:
						# we are here because the player also is, but is above us
						should_destroy = false

				if previous_tile.has_two_enms:
					if game.regen_on_enm:
						game.player_stability += game.regen_val * 2

				if should_destroy: handle_crash()

	else:
		print('can\' destroy ' + str(self.name) + '\'s current_tile is + ' + str(current_tile))



func set_tile_values(t, set_neighbors=true):
	var l = get_node("/root/level")
	var t_len = len(l.level_tiles)
	if set_neighbors: tile_index = t.index
	t.can_collide = can_collide
	t.can_collide = can_collide
	if t.has_enemy:
		t.has_two_enms = true
	else:
		t.has_enemy = true
	t.enm_str = str(self)
	t.previous_obstacle_dir = move_dir
	if t.hazard:
		meta.round_stats.enemy_hazard_hit += 1
		if main.master_sound:
			main.master_sound.get_node("fire_ignite").volume_db = -15
			main.master_sound.get_node("fire_ignite").play()
		handle_crash()
		return
	if set_neighbors and len(affected_neighbors) > 0:
		for n in affected_neighbors:
			if 'left' == n:
				if tile_index - 1 > 0 and tile_index - 1 < t_len:
					set_tile_values(l.level_tiles[tile_index - 1], false)
					active_neighbors.append(l.level_tiles[tile_index - 1])
			elif 'left_up' == n:
				if tile_index - meta.savable.row - 1 > 0 and tile_index - meta.savable.row - 1 < t_len:
					set_tile_values(l.level_tiles[tile_index - 1 - meta.savable.row], false)
					active_neighbors.append(l.level_tiles[tile_index - 1 - meta.savable.row])
			elif 'up' == n:
				if tile_index - meta.savable.row > 0 and tile_index - meta.savable.row < t_len:
					set_tile_values(l.level_tiles[tile_index - meta.savable.row], false)
					active_neighbors.append(l.level_tiles[tile_index - meta.savable.row])
			elif 'right_up' == n:
				if tile_index - meta.savable.row + 1 > 0 and tile_index - meta.savable.row + 1 < t_len:
					set_tile_values(l.level_tiles[tile_index + 1 - meta.savable.row], false)
					active_neighbors.append(l.level_tiles[tile_index + 1 - meta.savable.row])
			elif 'right' == n:
				if tile_index + 1 > 0 and tile_index + 1 < t_len:
					set_tile_values(l.level_tiles[tile_index + 1], false)
					active_neighbors.append(l.level_tiles[tile_index + 1])
			elif 'right_down' == n:
				if tile_index + meta.savable.row + 1> 0 and tile_index + meta.savable.row + 1< t_len:
					set_tile_values(l.level_tiles[tile_index + 1 + meta.savable.row], false)
					active_neighbors.append(l.level_tiles[tile_index + 1 + meta.savable.row])
			elif 'down' == n:
				if tile_index + meta.savable.row > 0 and tile_index + meta.savable.row < t_len:
					set_tile_values(l.level_tiles[tile_index + meta.savable.row], false)
					active_neighbors.append(l.level_tiles[tile_index + meta.savable.row])
			elif 'left_down' == n:
				if tile_index + meta.savable.row - 1 > 0 and tile_index + meta.savable.row - 1 < t_len:
					set_tile_values(l.level_tiles[tile_index + meta.savable.row - 1], false)
					active_neighbors.append(l.level_tiles[tile_index + meta.savable.row - 1])


func move_enemy(delta):
	var move_to_tile = current_tile if not game.in_preview else preview_tile
	var body_path = "body" if not game.in_preview else "preview_body"
	if main.checkIfNodeDeleted(move_to_tile) == false and not crashing and\
	   main.checkIfNodeDeleted(current_tile) == false:
		if game.in_preview: # hold spot for base image
			if get_node("body").global_position != current_tile.global_position:
				get_node("body").global_position = current_tile.global_position
			
		if move_to_tile and main.checkIfNodeDeleted(move_to_tile) == false and\
		   (move_to_tile.global_position - get_node(body_path).global_position).length() > 5:
			var speed = turn.object_move_speed * 1.45 if not game.in_preview else turn.object_move_speed * 3
			velocity = (move_to_tile.global_position -\
						get_node(body_path).global_position).normalized() *\
						speed
			get_node(body_path).move_and_collide(velocity * delta)
		else:
			if main.checkIfNodeDeleted(move_to_tile) == false:
				if get_node(body_path).global_position != move_to_tile.global_position:
					get_node(body_path).global_position = move_to_tile.global_position
			if velocity != Vector2(0, 0):
				velocity = Vector2(0, 0)


var removing = false
func destroy_self():
	if removing: return
	removing = true
	queue_free()


func _process(delta):
	if crashing:
		crash_counter += delta
	if crash_counter >= crash_limit:
		queue_free()
	if should_move:
		move_enemy(delta)
	if not active and modulate != Color(0, 0, 0, 0):
		modulate = Color(0, 0, 0, 0)


func handle_crash():
	modulate = Color(1, 1, 1, 1)
	if not crashing:
		if game.regen_on_enm:
			game.player_stability += game.regen_val
		#$body/anim_container1/smoke_anim.stop()
		#$body/anim_container1/smoke_shadow_anim.stop()
		#$body/anim_container1/shake_anim.stop()
		active = false
		if main.master_sound:
			main.master_sound.get_node("firey_crash").play()
			main.master_sound.get_node("large explosion").play()
		var e = main.instancer(main.explosion_scene)
		e.position = current_tile.global_position
		e.get_node("AnimationPlayer").play("explosion small")
		crashing = true
		$turn_anim_enm.stop()
		$turn_anim_enm.play("enm_crash1")


func _on_turn_anim_animation_finished(anim_name):
	if 'crash' in anim_name:
		if main.checkIfNodeDeleted(self) == false:
			queue_free()
	else:
		$turn_anim_enm.play("enm_cart_idle") # replace with function body
