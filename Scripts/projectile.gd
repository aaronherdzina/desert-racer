extends Node2D

var can_collide = true
var move_tiles = []
var preview_move_tiles = []
var affected_neighbors = ['left', 'right', 'up', 'down']
var dir = 'right'
var parent = null
var neighbors = []
var previous_tile = null
var current_tile = null
var preview_tile = null
var should_move = false
var can_hurt_player = false
var move_to_pos = null
var mine = false
var floater = false
var tile_index = 0
var active = true
var crashing = false
var velocity = Vector2(0, 0)
var remove_timer = 0
var remove_limit = 5
var explode_aoe = 0 # additional tiles dmg in 'circle' of tile, i.e. 1 is each surrounding, 2 is another circle
var explode_column_range = 0 # additional tiles dmg on explode on left and right of tile
var explode_row_range = 0 # additional tiles dmg on explode on top and bottom of tile
var speed = 2
var removing = false

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass


func set_next_move_tile_group():
	get_node("/root/level").find_projectile_move_tiles(speed, self)



func get_neighbors():
	var l = get_node("/root/level")
	var t_len = len(l.level_tiles)
	var tile_index_2 = current_tile.index
	var mod = 1
	neighbors = []
	for n in affected_neighbors:
		if 'left' == n:
			if current_tile.row > 0 and tile_index_2 - 1 - mod > 0 and tile_index_2 - 1 - mod< t_len:
				neighbors.append(l.level_tiles[tile_index_2 - 1 - mod])
		elif 'left_up' == n:
			if current_tile.row > 0 and current_tile.col > 0 and\
			   tile_index_2 - meta.savable.row - 1 - mod > 0 and tile_index_2 - meta.savable.row - 1 - mod < t_len:
				neighbors.append(l.level_tiles[tile_index_2 - 1 - meta.savable.row - mod])
		elif 'up' == n:
			if current_tile.col > 0 and tile_index_2 - meta.savable.row - mod > 0 and tile_index_2 - meta.savable.row - mod< t_len:
				neighbors.append(l.level_tiles[tile_index_2 - meta.savable.row - mod])
		elif 'right_up' == n:
			if current_tile.col > 0 and current_tile.row < meta.savable.row-1 - mod and tile_index_2 - meta.savable.row + 1 - mod > 0 and tile_index_2 - meta.savable.row + 1 - mod< t_len:
				neighbors.append(l.level_tiles[tile_index_2 + 1 - meta.savable.row - mod])
		elif 'right' == n:
			if current_tile.row < meta.savable.row-1 and tile_index_2 + 1 > 0 and tile_index_2 + 1 < t_len:
				neighbors.append(l.level_tiles[tile_index_2 + 1 - mod])
		elif 'right_down' == n:
			if current_tile.row < meta.savable.row + 1 - mod and current_tile.col < meta.savable.col + 1 - mod and tile_index_2 + meta.savable.row + 1 - mod > 0 and tile_index_2 + meta.savable.row + 1 - mod < t_len:
				neighbors.append(l.level_tiles[tile_index_2 + 1 + meta.savable.row - mod])
		elif 'down' == n:
			if current_tile.col < meta.savable.col-1 and tile_index_2 + meta.savable.row > 0 and tile_index_2 + meta.savable.row < t_len:
				neighbors.append(l.level_tiles[tile_index_2 + meta.savable.row - mod])
		elif 'left_down' == n:
			if current_tile.row > 0 and current_tile.col < meta.savable.col-1 - mod and tile_index_2 + meta.savable.row - 1 - mod> 0 and tile_index_2 + meta.savable.row - 1 - mod < t_len:
				neighbors.append(l.level_tiles[tile_index_2 + meta.savable.row - 1 - mod])


func handle_projectile_crash():
	if crashing: return
	active = false
	crashing = true
	if main.master_sound:
		main.master_sound.get_node("impact").play()
	#remove_timer = remove_limit
	if explode_aoe > 0:
		var enemies = get_tree().get_nodes_in_group("active_enemies")
		var objects = get_tree().get_nodes_in_group("active_objects")
		var projectiles = get_tree().get_nodes_in_group("projectile")
		var player = null
		if get_node("/root").has_node("player"):
			player = get_node("/root/player")
		print('in proj handle pre explosion')
		for n in neighbors:
			if main.checkIfNodeDeleted(n) == false:
				if main.checkIfNodeDeleted(player) == false:
					if game.compare_obj_tile_index(player, player, n.index):
						player.call_deferred("handle_crash")
				for enm in enemies:
					if main.checkIfNodeDeleted(enm) == false:
						if game.compare_obj_tile_index(enm, enm, n.index):
							enm.call_deferred("handle_crash")
				for o in objects:
					if main.checkIfNodeDeleted(o) == false:
						if game.compare_obj_tile_index(o, o, n.index):
							o.call_deferred("destroy_self")
				for p in projectiles:
					if main.checkIfNodeDeleted(p) == false:
						if p != self and game.compare_obj_tile_index(p, p, n.index):
							p.call_deferred("destroy_self")

	var e = main.instancer(main.explosion_scene)
	e.position = self.current_tile.global_position
	e.get_node("AnimationPlayer").play("explosion small")
	print('in proj handle post explosion')
	destroy_self()
	#$AnimationPlayer.play('explosion')

func destroy_self():
	if removing: return
	active = false
	removing = true
	print('proj remove')
	queue_free()


func set_next_move_tile(s):
	previous_tile = current_tile 
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
		preview_tile.add_to_group("active_tile")
	#set_tile_values(preview_tile)
	handle_current_step()


func handle_current_step():
	""" Set tile stuff and allow movement"""
	should_move = true
	if current_tile.row <= 1:
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
	if explode_aoe > 0:
		get_neighbors()


func check_tile_based_collision():
	# Check if has_two_objs in validate collision then we can remove all objs that share this
	var should_destroy = false
	if main.checkIfNodeDeleted(current_tile) == false:
		# first check immediate collisions
		if current_tile.has_two_projs or\
		   current_tile.has_enemy and not parent or\
		   current_tile.has_enemy and parent and parent != current_tile.enm_str or\
		   current_tile.has_player and not parent or\
		   current_tile.has_player and parent and parent != current_tile.player_str or\
		   current_tile.has_object:
			# we are here because we possibly collided with a something on a previous tile 
			should_destroy = true
			if current_tile.has_player and not current_tile.has_enemy and\
			   not current_tile.has_two_projs and not current_tile.has_object:
				if not current_tile.player_can_crash and current_tile.player_in_air:
					# we are here because the player also is, but is above us
					should_destroy = false

			# some redundant logic for stats
			if current_tile.has_enemy and not parent or\
			   current_tile.has_enemy and parent and parent != current_tile.enm_str:
				meta.round_stats.enemies_shot += 1
			if current_tile.has_player and not parent or\
			   current_tile.has_player and parent and parent != current_tile.player_str:
				meta.round_stats.projectiles_hit += 1
			if current_tile.has_object and not can_hurt_player:
				meta.round_stats.objects_shot += 1

			if should_destroy: handle_projectile_crash()

	should_destroy = false
	if not removing and main.checkIfNodeDeleted(previous_tile) == false:
		# next check collisions from passover conditions
		if previous_tile.has_two_projs or\
		   previous_tile.has_enemy and not parent or\
		   previous_tile.has_enemy and parent and parent != current_tile.enm_str or\
		   previous_tile.has_player and not parent or\
		   previous_tile.has_player and parent and parent != current_tile.player_str or\
		   previous_tile.has_object:
			if dir == 'left' and previous_tile.previous_obstacle_dir == 'right' or\
			   dir == 'up' and previous_tile.previous_obstacle_dir == 'down' or\
			   dir == 'right' and previous_tile.previous_obstacle_dir == 'left' or\
			   dir == 'down' and previous_tile.previous_obstacle_dir == 'up':
				# we are here because we possibly collided with a something on a previous tile 
				should_destroy = true
				if previous_tile.has_player and not previous_tile.has_enemy and\
				   not previous_tile.has_two_projs and not previous_tile.has_object:
					if main.checkIfNodeDeleted(current_tile) == false and current_tile.player_in_air or\
					   previous_tile.player_in_air or  main.checkIfNodeDeleted(current_tile) == false  and\
					   not current_tile.player_can_crash or not previous_tile.player_can_crash:
						# we are here because the player also is, but is above us
						should_destroy = false

				# some redundant logic for stats
				if previous_tile.has_enemy and not parent or\
				   previous_tile.has_enemy and parent and parent != previous_tile.enm_str:
					meta.round_stats.enemies_shot += 1
				if previous_tile.has_player and not parent or\
				   previous_tile.has_player and parent and parent != previous_tile.player_str:
					meta.round_stats.projectiles_hit += 1
				if previous_tile.has_object and not can_hurt_player:
					meta.round_stats.objects_shot += 1

				if should_destroy: handle_projectile_crash()

	else:
		print('can\' destroy ' + str(self.name) + '\'s current_tile is + ' + str(current_tile))


func set_tile_values(t):
	tile_index = t.index
	if t.has_projectile:
		t.has_two_projs = true
	else:
		t.has_projectile = true
	t.proj_str = str(self)
	t.previous_obstacle_dir = dir


func move_projectile(delta):
	var move_to_tile = current_tile if not game.in_preview else preview_tile
	var body_path = "body" if not game.in_preview else "preview_body"
	if game.in_preview: # hold spot for base image
		if main.checkIfNodeDeleted(current_tile) == false:
			if get_node("body").global_position != current_tile.global_position:
				get_node("body").global_position = current_tile.global_position
	if move_to_tile and main.checkIfNodeDeleted(move_to_tile) == false and main.checkIfNodeDeleted(get_node(body_path)) == false and\
	   (move_to_tile.global_position - get_node(body_path).global_position).length() > 5:
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
		move_projectile(delta)
	if remove_timer > 0:
		remove_timer -= delta
		if remove_timer <= 0:
			if main.checkIfNodeDeleted(self) == false:
				destroy_self()


func _on_AnimationPlayer_animation_finished(anim_name):
	pass
