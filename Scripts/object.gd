extends Node2D

var can_collide = true
var move_tiles = []
var preview_move_tiles = []
var current_tile = null
var previous_tile = null
var preview_tile = null
var should_move = false
var affected_neighbors = []
var is_hazard = false # if hazard add to group to easily set tiles based on each hazard
var is_row_block = false
var move_to_pos = null
var tile_index = 0
var velocity = Vector2(0, 0)
var active = true
var active_neighbors = []
var dirs = ['left', 'right', 'up', 'down', 'right_down', 'left_down',
				'right_up', 'left_up']


func _ready():
	pass


func set_next_move_tile_group():
	get_node("/root/level").find_object_move_tiles(turn.step, self)


func set_next_move_tile(s):
	previous_tile = current_tile
	if is_hazard: 
		current_tile.hazard = true
		current_tile.add_to_group("active_hazard_tile")
		current_tile.texture_can_reset = true
	if not current_tile.movable:
		current_tile.movable = true
		if current_tile.is_in_group("active_hazard_tile"):
			current_tile.remove_from_group("active_hazard_tile")
		current_tile.texture_can_reset = true
	if is_row_block:
		current_tile.movable = false
		current_tile.add_to_group("active_hazard_tile")
		current_tile.texture_can_reset = false

	current_tile = move_tiles[s]
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
	if current_tile.row <= 1:\
		if main.checkIfNodeDeleted(self) == false:
			self.destroy_self()
	var new_shadow_mod = 1.25 - (current_tile.row * .04)
	var x_mod = (current_tile.row * meta.shadow_pos_x_global_mode)
	var y_mod = (current_tile.row * meta.shadow_pos_y_global_mode)
	if new_shadow_mod < meta.global_shadow_modulate_min:
		new_shadow_mod = meta.global_shadow_modulate_min
	if new_shadow_mod > meta.global_shadow_modulate_max:
		new_shadow_mod = meta.global_shadow_modulate_max
	get_node("body/shadow").position.x -= x_mod
	get_node("body/shadow").position.y += y_mod
	get_node("body/shadow").modulate = Color(0, 0, 0, new_shadow_mod)


func check_tile_based_collision():
	# Check if has_two_objs in validate collision then we can remove all objs that share this
	var should_destroy = false
	if main.checkIfNodeDeleted(current_tile) == false:
		# first check immediate collisions
		if current_tile.has_two_objs or\
		   current_tile.has_projectile or\
		   current_tile.has_enemy or\
		   current_tile.has_player:
				# we are here because we possibly collided with a something on a our tile 
			should_destroy = true
			if current_tile.has_player and not current_tile.has_enemy and\
			   not current_tile.has_projectile and not current_tile.has_two_objs:
				if not current_tile.player_can_crash or current_tile.player_in_air:
					print(' player over obj dont destroy')
					# we are here because we the player also is, but is above us
					should_destroy = false
			# some redundant logic for stats
			if current_tile.has_enemy:
				meta.round_stats.enemy_objects_hit += 1

			if should_destroy: destroy_self()

	should_destroy = false
	if not removing and main.checkIfNodeDeleted(previous_tile) == false:
		# next check collisions from passover conditions
		if previous_tile.previous_obstacle_dir == 'right':
			if previous_tile.has_two_objs or\
			   previous_tile.has_projectile or\
			   previous_tile.has_enemy or\
			   previous_tile.has_player:
				# we are here because we possibly collided with a something on a previous tile 
				should_destroy = true
				if previous_tile.has_player and not previous_tile.has_enemy and\
				   not previous_tile.has_projectile and not previous_tile.has_two_objs:
					print('1 player over obj')
					if main.checkIfNodeDeleted(current_tile) == false and current_tile.player_in_air or\
					   previous_tile.player_in_air or main.checkIfNodeDeleted(current_tile) == false and\
					   not current_tile.player_can_crash or not previous_tile.player_can_crash:
						print('1 player over obj dont destroy')
						# we are here because we the player also is, but is above us
						should_destroy = false

				# some redundant logic for stats
				if previous_tile.has_enemy:
					meta.round_stats.enemy_objects_hit += 1

			if should_destroy: destroy_self()

	else:
		print('can\' destroy ' + str(self.name) + '\'s current_tile is + ' + str(current_tile))


func set_tile_values(t, set_neighbors=true):
	var l = get_node("/root/level")
	var t_len = len(l.level_tiles)
	if set_neighbors: tile_index = t.index
	t.can_collide = can_collide
	if t.has_object:
		t.has_two_objs = true
	else:
		t.has_object = true
	t.obj_str = str(self)
	t.previous_obstacle_dir = 'left' # objects only go left

	if t.hazard and not is_row_block:
		main.master_sound.get_node("fire_ignite").play()
		main.master_sound.get_node("sci-fi-crash").play()
		var e = main.instancer(main.explosion_scene)
		e.position = current_tile.global_position
		e.get_node("AnimationPlayer").play("explosion small")
		if main.checkIfNodeDeleted(self) == false:
			queue_free()
	if set_neighbors:
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

var removing = false
func destroy_self():
	if removing: return
	if game.regen_on_obj:
		game.player_stability += game.regen_val
	removing = true
	queue_free()


func move_object(delta):
	var move_to_tile = current_tile if not game.in_preview else preview_tile
	var body_path = "body" if not game.in_preview else "preview_body"
	if game.in_preview and main.checkIfNodeDeleted(get_node("body")) == false: # hold spot for base image
		if get_node("body").global_position != current_tile.global_position:
			get_node("body").global_position = current_tile.global_position
		
	if move_to_tile and main.checkIfNodeDeleted(move_to_tile) == false and\
	   main.checkIfNodeDeleted(get_node(body_path)) == false and\
	   (move_to_tile.global_position - get_node(body_path).global_position).length() > 2:
		var speed = turn.object_move_speed * 1.45 if not game.in_preview else turn.object_move_speed * 3.5
		velocity = (move_to_tile.global_position -\
					get_node(body_path).global_position).normalized() *\
					speed
		get_node(body_path).move_and_collide(velocity * delta)
	else:
		if main.checkIfNodeDeleted(move_to_tile) == false and main.checkIfNodeDeleted(get_node(body_path)) == false:
			if get_node(body_path).global_position != move_to_tile.global_position:
				get_node(body_path).global_position = move_to_tile.global_position
		if velocity != Vector2(0, 0):
			velocity = Vector2(0, 0)


func _process(delta):
	if should_move:
		move_object(delta)
	if not active and modulate != Color(0, 0, 0, 1):
		modulate = Color(0, 0, 0, 0)
