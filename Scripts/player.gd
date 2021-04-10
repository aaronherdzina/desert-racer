extends Node2D

var move_tiles = []
var preview_move_tiles = []
var current_tile = null
var previous_tile = null
var preview_tile = null
var can_collide = true
var should_move = false
var move_to_pos = null
var crash_counter = 0
var crash_time = .2
var crash_counter2 = 0
var crash_time2 = 5
var crashing = false
var tile_index = 0
var velocity = Vector2(0, 0)
var slick_scale = Vector2(1, 1)
var tech_scale = Vector2(.8, .8)
var tile_buffer = 25
var player_in_air = false
var player_can_crash = true
var player_can_be_shot = true
var player_can_be_hurt = true
var invincible = false
var air_time = 0
var max_air_time = 0 # from a card
var half_air_time = 0
var starting_scale = Vector2(0, 0)
var starting_scale_x = 1
var neighbors = []

var max_height_jump_scale = 1.75
var scale_change_increment = .02
var min_height_fall_scale = .25

var max_height_jump_rotation = (0.145398) # 45 degrees to radians: 0.785398
var rotation_change_increment = (.032)
var min_height_fall_rotation = (0)
var starting_sprite_pos_y = 32.401
var starting_sprite4_pos_y = 37.08
var jump_sprite_increment = 12
var max_jump_sprite_height = -200
var max_jump_sprite4_height = -205
var starting_rotation = (0.558505) # 32 degrees to radians: 0.558505

var affected_neighbors = ['left', 'right', 'up', 'down', 'right_down', 'left_down',
						  'right_up', 'left_up']

func _ready():
	var char_ref = meta.savable.player.character
	if char_ref == 'TECH':
		$body/Sprite.modulate = Color(.8, .8, 1, 1)
		#get_node("body/anim_container1/cart_imgs/cart anim").play("tech anim")
		get_node("body/anim_container1/cart_imgs").set_scale(tech_scale)
	elif char_ref == 'SLICK':
		#$body/Sprite.modulate = Color(.75, 1, .75, 1)
		#get_node("body/anim_container1/cart_imgs/cart anim").play("slick")
		get_node("body/anim_container1/cart_imgs").set_scale(slick_scale)
	elif char_ref == 'RAVEN':
		$body/Sprite.modulate = Color(.55, .55, .65, 1)
	elif char_ref == 'DOZER':
		$body/Sprite.modulate = Color(.75, 1, .75, 1)
	starting_scale = $body.scale
	starting_scale_x = $body.scale.x
	starting_rotation = rotation
	starting_sprite_pos_y = $body/Sprite.position.y
	starting_sprite4_pos_y = $body/Sprite4.position.y


func handle_jumping(current_step):
	# we check if we are still in air before this func is called
	# TODO: Add rotation

	var scale_x = $body.scale.x
	var scale_y = $body.scale.y
	var sprite_height = $body/Sprite.position.y
	var sprite4_height = $body/Sprite4.position.y
	var rot = rotation
	var half_steps = round(turn.step * .50)
	var change_sprite4 = true

	if max_air_time == 1:
		if current_step >= half_steps: # going back down
			scale_x -= scale_change_increment
			scale_y -= scale_change_increment
			rot += rotation_change_increment
			sprite_height += jump_sprite_increment
			sprite4_height += jump_sprite_increment
		elif current_step < half_steps: # goin up
			scale_x += scale_change_increment
			scale_y += scale_change_increment
			rot -= rotation_change_increment
			sprite_height -= jump_sprite_increment
			sprite4_height -= jump_sprite_increment
	else:
		if air_time >= half_air_time: # going back down
			scale_x -= scale_change_increment
			scale_y -= scale_change_increment
			rot += rotation_change_increment
			sprite_height += jump_sprite_increment
			sprite4_height += jump_sprite_increment
		elif air_time < half_air_time: # goin up
			scale_x += scale_change_increment
			scale_y += scale_change_increment
			rot -= rotation_change_increment
			sprite_height -= jump_sprite_increment
			sprite4_height -= jump_sprite_increment

	if sprite_height > starting_sprite_pos_y:
		sprite_height = starting_sprite_pos_y
		$body/Sprite4.position.y = starting_sprite4_pos_y
		change_sprite4 = false
	if sprite_height < max_jump_sprite_height: sprite_height = max_jump_sprite_height
	if sprite_height < max_jump_sprite_height: sprite_height = max_jump_sprite_height
	if sprite4_height < max_jump_sprite4_height: sprite4_height = max_jump_sprite4_height

	if rot < max_height_jump_rotation: rot = max_height_jump_rotation
	if rot > starting_rotation: rot = starting_rotation

	if scale_x > max_height_jump_scale: scale_x = max_height_jump_scale
	if scale_y > max_height_jump_scale: scale_y = max_height_jump_scale

	if scale_x < min_height_fall_scale: scale_x = starting_scale_x
	if scale_y < min_height_fall_scale: scale_y = starting_scale_x

	$body.set_scale(Vector2(scale_x, scale_y))
	$body/Sprite.position.y = sprite_height
	if change_sprite4: $body/Sprite4.position.y = sprite4_height # the shadowy outline
	rotation = rot


func get_neighbors():
	var l = get_node("/root/level")
	var t_len = len(l.level_tiles)
	neighbors = []
	for n in affected_neighbors:
		if 'left' == n:
			if current_tile.row > 0 and tile_index - 1 > 0 and tile_index - 1 < t_len:
				neighbors.append(l.level_tiles[tile_index - 1])
		elif 'left_up' == n:
			if current_tile.row > 0 and current_tile.col > 0 and\
			   tile_index - meta.savable.row - 1 > 0 and tile_index - meta.savable.row - 1 < t_len:
				neighbors.append(l.level_tiles[tile_index - 1 - meta.savable.row])
		elif 'up' == n:
			if current_tile.col > 0 and tile_index - meta.savable.row > 0 and tile_index - meta.savable.row < t_len:
				neighbors.append(l.level_tiles[tile_index - meta.savable.row])
		elif 'right_up' == n:
			if current_tile.col > 0 and current_tile.row < meta.savable.row-1 and tile_index - meta.savable.row + 1 > 0 and tile_index - meta.savable.row + 1 < t_len:
				neighbors.append(l.level_tiles[tile_index + 1 - meta.savable.row])
		elif 'right' == n:
			if current_tile.row < meta.savable.row-1 and tile_index + 1 > 0 and tile_index + 1 < t_len:
				neighbors.append(l.level_tiles[tile_index + 1])
		elif 'right_down' == n:
			if current_tile.row < meta.savable.row-1 and current_tile.col < meta.savable.col-1 and tile_index + meta.savable.row + 1> 0 and tile_index + meta.savable.row + 1< t_len:
				neighbors.append(l.level_tiles[tile_index + 1 + meta.savable.row])
		elif 'down' == n:
			if current_tile.col < meta.savable.col-1 and tile_index + meta.savable.row > 0 and tile_index + meta.savable.row < t_len:
				neighbors.append(l.level_tiles[tile_index + meta.savable.row])
		elif 'left_down' == n:
			if current_tile.row > 0 and current_tile.col < meta.savable.col-1 and tile_index + meta.savable.row - 1 > 0 and tile_index + meta.savable.row - 1 < t_len:
				neighbors.append(l.level_tiles[tile_index + meta.savable.row - 1])
	for n in neighbors:
		n.modulate = Color(0, 0, 1, 1)


func set_next_move_tile_group():
	get_node("/root/level").find_player_move_tiles(turn.step, self, game.player_move_dir)


func set_next_move_tile(s):
	previous_tile = current_tile
	current_tile = move_tiles[s]
	z_index = game.get_z_index_off_row(current_tile)
	var move_len = len(move_tiles)
	var anim_speed = 1
	
	if len(move_tiles) > 0:
		if game.player_move_dir == 'up' or game.player_move_dir == 'down':
			# we have rigid totals moving up and down to match up better with animations
			if move_len <= 2:
				anim_speed = 2
			elif move_len <= 4:
				anim_speed = 1.25
			elif move_len >= 5:
				anim_speed = 1
		else:
			# if we move left or right change anim speed on distance moved
			anim_speed = 1.25 * move_len
			
	if game.player_move_dir != 'right':
		previous_tile = current_tile
	if game.player_move_dir == 'up' and s == 0:
		self.get_node("turn_anim_player").play("turn_up_player")
	elif game.player_move_dir == 'down' and s == 0:
		self.get_node("turn_anim_player").play("turn_down_player")
	else:
		self.get_node("turn_anim_player").play("idle")
	
	self.get_node("turn_anim_player").playback_speed = anim_speed
	current_tile.add_to_group("active_tile")
	set_tile_values(current_tile)
	handle_current_step()

func set_next_preview_move_tile():
	preview_tile = preview_move_tiles[len(preview_move_tiles)-1]
	if main.checkIfNodeDeleted(preview_tile) == false:
		preview_tile.get_node("occupied_sprite").modulate = Color(.4, .4, 1, 1)
	#set_tile_values(preview_tile)
	handle_current_step()


func get_player_preview_action(current_card):
	var total_speed = turn.step + game.global_speed_buff + meta.savable.player.speed_mod
	var total_move = current_card.details.move_distance +\
					 game.global_move_buff + meta.savable.player.move_distance_mod
	for t in current_card.details.type:
		if t == 'move':
			game.preview_player_move_speed = total_move
			game.preview_player_move_dir = current_card.details.move_dir
			get_node("preview_body").visible = true
		elif t == 'speed':
			turn.preview_step = total_speed + current_card.details.speed_change

		if not 'move' in str(current_card.details.type):
			game.preview_player_move_speed = 0
			get_node("preview_body").visible = false
		if not 'speed' in str(current_card.details.type):
			turn.preview_step = total_speed
	if game.preview_player_move_speed > turn.preview_step:
		game.preview_player_move_speed = turn.preview_step


func handle_current_step():
	""" Set tile stuff and allow movement"""
	should_move = true
	var new_shadow_mod = 1.25 - (current_tile.row * .06)
	var x_mod = (current_tile.row * meta.shadow_pos_x_global_mode)
	var y_mod = (current_tile.row * meta.shadow_pos_y_global_mode)
	if new_shadow_mod < meta.global_shadow_modulate_min:
		new_shadow_mod = meta.global_shadow_modulate_min
	if new_shadow_mod > meta.global_shadow_modulate_max:
		new_shadow_mod = meta.global_shadow_modulate_max
	get_node("body/anim_container1/shadow").position.x -= x_mod
	get_node("body/anim_container1/shadow").position.y += y_mod
	get_node("body/anim_container1/shadow").modulate = Color(0, 0, 0, new_shadow_mod)


func check_tile_based_collision():
	# Check if has_two_objs in validate collision then we can remove all objs that share this
	if main.checkIfNodeDeleted(current_tile) == false:
		# first check immediate collisions
		if current_tile.has_projectile and str(self) != current_tile.player_str or\
		   current_tile.has_enemy or\
		   current_tile.has_object:
			if player_can_crash and not invincible:
				if current_tile.has_enemy:
					meta.round_stats.enemies_hit += 1
					game.get_cards_from_collision(rand_range(1, meta.savable.player.hand_limit + 1), current_tile.previous_obstacle_dir)
					game.player_move_speed += 1
					if game.player_move_speed > turn.step:
						game.player_move_speed = turn.step

				handle_crash()
			else:
				if player_in_air:
					meta.savable.stats.obstacles_jumped += 1
					meta.round_stats.obstacles_jumped += 1

	if not removing and main.checkIfNodeDeleted(previous_tile) == false:
		# next check collisions from passover conditions
		if previous_tile.has_projectile and str(self) != previous_tile.player_str  or\
		   previous_tile.has_enemy or\
		   previous_tile.has_object:
			if not previous_tile.has_projectile and game.player_move_dir == 'left' and previous_tile.previous_obstacle_dir == 'right' or\
			   not previous_tile.has_projectile and game.player_move_dir == 'up' and previous_tile.previous_obstacle_dir == 'down' or\
			   not previous_tile.has_projectile and game.player_move_dir == 'right' and previous_tile.previous_obstacle_dir == 'left' or\
			   not previous_tile.has_projectile and game.player_move_dir == 'down' and previous_tile.previous_obstacle_dir == 'up':

				if player_can_crash and not invincible:
					if previous_tile.has_enemy:
						meta.round_stats.enemies_hit += 1
						game.get_cards_from_collision(rand_range(1, meta.savable.player.hand_limit + 1), previous_tile.previous_obstacle_dir)
						game.player_move_speed += 1
						if game.player_move_speed > turn.step:
							game.player_move_speed = turn.step
	
					# some redundant logic for stats
					if previous_tile.has_object:
						meta.round_stats.objects_hit += 1
	
					handle_crash()
			else:
				if player_in_air:
					meta.savable.stats.obstacles_jumped += 1
					meta.round_stats.obstacles_jumped += 1

	else:
		print('can\' destroy ' + str(self.name) + '\'s current_tile is + ' + str(current_tile))


func set_tile_values(t):
	tile_index = t.index
	t.has_player = true

	t.player_can_be_hurt = player_can_be_hurt
	t.player_invincible = invincible
	t.player_can_crash = player_can_crash
	t.player_in_air = player_in_air
	t.player_can_be_shot = player_can_be_shot

	t.player_str = str(self)
	
	t.previous_obstacle_dir = game.player_move_dir
	if player_can_be_hurt and not invincible:
		if t.hazard:
			meta.round_stats.hazard_hit += 1
			if main.master_sound:
				main.master_sound.get_node("fire_ignite").play()
			handle_crash()


func handle_crash():
	if not crashing:
		$turn_anim_player.playback_speed = 1
		var e = main.instancer(main.explosion_scene)
		e.position = current_tile.global_position
		e.get_node("AnimationPlayer").play("explosion large")
		if main.master_sound:
			main.master_sound.get_node("firey_crash").play()
			main.master_sound.get_node("large explosion").play()
			main.master_sound.get_node("sci-fi-crash").play()
		crash_counter = crash_time
		$turn_anim_player.playback_speed = .03
		$turn_anim_player.play("crash1")


var removing = false
func destroy_self():
	if removing: return
	removing = true
	call_deferred("free")


func move_object(delta):
	var move_to_tile = current_tile if not game.in_preview else preview_tile
	var body_path = "body" if not game.in_preview else "preview_body"
	if game.in_preview: # hold spot for base image
		if get_node("body").global_position != current_tile.global_position:
			get_node("body").global_position = current_tile.global_position

	if move_to_tile and main.checkIfNodeDeleted(move_to_tile) == false and\
	   (move_to_tile.global_position - get_node(body_path).global_position).length() > 5:
		var speed = turn.object_move_speed * 1.45 if not game.in_preview else turn.object_move_speed * 3
		velocity = (move_to_tile.global_position -\
					get_node(body_path).global_position).normalized() * speed
		get_node(body_path).move_and_collide(velocity * delta)
	else:
		if main.checkIfNodeDeleted(move_to_tile) == false:
			if main.checkIfNodeDeleted(get_node(body_path)) == false:
				if get_node(body_path).global_position != move_to_tile.global_position:
					get_node(body_path).global_position = move_to_tile.global_position
		if velocity != Vector2(0, 0):
			velocity = Vector2(0, 0)
		var tiles = meta.get_neighboring_tiles(current_tile, ['left', 'up', 'right', 'down', 'right_up', 'left_up', 'right_down', 'left_down'])
		current_tile.get_node("Sprite").modulate = Color(0, 0, 1, .4)


func _process(delta):
	if main.checkIfNodeDeleted(self) == false:
		if should_move:
			move_object(delta)
			if crash_counter > 0:
				crash_counter -= delta
				if crash_counter <= 0:
					crash_counter2 = crash_time2
					if not game.level_over:
						game.level_over = true
						if main.master_sound:
							main.master_sound.get_node("slow_burn").play()
			if crash_counter2 > 0:
				crash_counter2 -= delta
				if crash_counter2 >= crash_time2 * .5:
					$turn_anim_player.playback_speed = .5
				if crash_counter2 <= 0:
					$turn_anim_player.playback_speed = 1
					game.end_level()


func _on_turn_anim_player_animation_finished(anim_name):
	if 'turn' in anim_name:
		$turn_anim_player.play("idle")
