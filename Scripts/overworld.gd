extends Node2D

var overworld_position = ''
var next_available_pos = []
var all_level_details = []
var level_step_target = 1
var world_generated = false

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass


func set_node_imgs():
	var levels = get_node("/root/overworld_scene/level_nodes").get_children()
	for l in levels:
		for l_deets in all_level_details:
			if l.name == l_deets['name_index']:
				if '>' in l.name:
					l.get_node("Sprite").set_texture(main.cross_pos)
				elif l_deets['is_pass_through'] != 0:
					# is passthrough
					l.get_node("Sprite").set_texture(main.level_pos)
				else:
					l.get_node("Sprite").set_texture(main.blank_pos)


func set_level_details(level_node):
	for lvl in all_level_details:
		if level_node.name in lvl['name_index']:
			if lvl['is_pass_through'] != 0:
				# is passthrough
				level_step_target = lvl['step_target']
				game.spawn_enm_chance = lvl['enemy_chance']
				game.enms_per_turn = lvl['enms_per_turn']
				game.enm_projectile_chance = lvl['enm_projectile_chance']
				game.enm_bomb_projectile_chance = lvl['enm_bomb_chance']
				game.object_chance = lvl['object_chance']
				game.objs_per_turn = lvl['objects_per_turn']
				return true
			else:
				level_step_target = lvl['step_target']
				game.spawn_enm_chance = lvl['enemy_chance']
				game.enms_per_turn = lvl['enms_per_turn']
				game.enm_projectile_chance = lvl['enm_projectile_chance']
				game.enm_bomb_projectile_chance = lvl['enm_bomb_chance']
				game.object_chance = lvl['object_chance']
				game.objs_per_turn = lvl['objects_per_turn']
				return false
	return false


func set_overworld_level_details():
	""" we don't save the node because we remove the scene and this is called
		1 per game """
	randomize()
	var levels = get_node("/root/overworld_scene/level_nodes").get_children()
	world_generated = true
	for l in levels:
		var l_name = l.name
		var deets = get_level_details(l_name) # set everything based on deets
		var focuses = deets[2]
		var enm_deets = get_level_enemy_chance(focuses, l_name)
		var enm_projectile_deets = get_level_enemy_projectile_chance(focuses, l_name)
		var obj_deets = get_level_object_chance(focuses, l_name)
		var is_pass_through = 0
		var steps = get_level_step_target(focuses, l_name)
		var level_deets = {
			'name_index': l_name,
			'detail': 'Passthrough' if is_pass_through == 1 else deets[0], # for example, steps focused, enemy focused, use to get img for node
			'img': deets[1],
			'step_target': steps,
			'enemy_chance': enm_deets[0],
			'enms_per_turn': enm_deets[1],
			'enm_projectile_chance': enm_projectile_deets[0],
			'enm_bomb_chance': enm_projectile_deets[1],
			'object_chance': obj_deets[0],
			'objects_per_turn': obj_deets[1],
			'is_pass_through': 0
		}
		# TODO? DICT MIGHT BE COPYING, TRY SETTTING DEFAULTS ABOVE THEN OVERWRITE BELOW

		#print('lvl ' + str(l_name) + ' deets ' + str(level_deets))
		all_level_details.append(level_deets)


func get_level_enemy_projectile_chance(focuses, lvl):
	var focus = false
	var base_enm_amount = 3
	var base_bomb_amount = 1
	var lvl_num = get_level_num(lvl) 
	var bomb_chance = base_bomb_amount * (lvl_num * .25) if lvl_num > 0 else 1
	var val = base_enm_amount * (lvl_num * .25) if lvl_num > 0 else 1
	for f in focuses:
		if f == 'enm_projectiles':
			focus = true
			break
	if focus:
		bomb_chance *= rand_range(2, 3)
		val *= rand_range(1.25, 1.5)
	if val > 90: val = 90
	return [val, bomb_chance]


func get_level_enemy_chance(focuses, lvl):
	var focus = false
	var base_enm_amount = 25
	var lvl_num = get_level_num(lvl) 
	var val = base_enm_amount * (lvl_num * .5) if lvl_num > 0 else 1
	for f in focuses:
		if f == 'enemies':
			focus = true
			break
	var enms_per_turn = 1
	if enms_per_turn > 2: enms_per_turn = 2
	if focus:
		enms_per_turn += rand_range(1, 3)
		val *= rand_range(1.05, 1.5)
	if val > 80: val = 80
	return [val, enms_per_turn]


func get_level_object_chance(focuses, lvl):
	var focus = false
	var base_obj_amount = game.default_object_chance
	var lvl_num = get_level_num(lvl) 
	var val = base_obj_amount * (lvl_num * .2) if lvl_num > 0 else 1
	for f in focuses:
		if f == 'objects':
			focus = true
			break
	var objs_per_turn = rand_range(3, 5)
	if focus:
		objs_per_turn = rand_range(5, 10)
		val *= rand_range(1.25, 1.5)
	if val > 90: val = 90
	if objs_per_turn < 1: objs_per_turn = 1
	return [val, objs_per_turn]


func get_level_step_target(focuses, lvl):
	var focus = false
	var base_val = 35
	for f in focuses:
		if f == 'steps':
			focus = true
			break
	var lvl_num = get_level_num(lvl) 
	var val = base_val * lvl_num if lvl_num > 0 else 1
	if focus: val *= rand_range(1.5, 2)
	return round(val)


func get_level_num(lvl):
	var val = 1
	if '1' in lvl: val = 1
	elif '2' in lvl: val = 2
	elif '3' in lvl: val = 3
	elif '4' in lvl: val = 4
	elif '5' in lvl: val = 5
	elif '6' in lvl: val = 6
	elif '7' in lvl: val = 7
	elif '8' in lvl: val = 8
	return val


func get_level_details(lvl):
	"""Set level focus randomly, and high chance for more based on level number"""
	var focuses = ['steps', 'objects', 'enemies', 'enm_projectiles']
	var current_focuses = []
	var deets = []
	var img = null
	var focus_text = ''
	var lvl_num = get_level_num(lvl)

	var focus1_idx = rand_range(0, len(focuses))
	var focus1 = focuses[focus1_idx]
	focuses.remove(focus1_idx)

	var focus2_idx = rand_range(0, len(focuses))
	var focus2 = focuses[focus2_idx]
	focuses.remove(focus2_idx)

	var focus3_idx = rand_range(0, len(focuses))
	var focus3 = focuses[focus3_idx]
	focuses.remove(focus3_idx)

	current_focuses.append(focus1)
	if rand_range(2, 10) < lvl_num:
		current_focuses.append(focus2)
	if rand_range(2, 10) < lvl_num:
		current_focuses.append(focus3)

	for f in current_focuses:
		if f == 'steps': 
			focus_text += "Far Evacuation Zone " 
			img = null
		if f == 'objects':
			focus_text += "Dangerous Terrain "
			img = null
		if f == 'enemies':
			focus_text += "Heavy Enemy Presence "
			img = null
		if f == 'enm_projectiles':
			focus_text += "Heavy Elite Enemy Presence "
			img = null

	deets.append(focus_text)
	deets.append(img)
	deets.append(current_focuses)

	return deets


func set_node_details(pos):
	var o_scene = get_node("/root/overworld_scene")
	var n = pos.name.replace('+', '').replace('-', '').replace('>', '') if '+' in pos.name else pos.name.replace('-', '').replace('>', '')
	var levels = get_node("/root/overworld_scene/level_nodes").get_children()
	for n in levels:
		if n.name == overworld_position:
			n.modulate = Color(.7, .7, 1, 1)
		
		else:
			n.modulate = Color(1, 1, 1, 1)
	for n in next_available_pos: n.modulate = Color(1, 1, .6, 1)
	
	main.menu_list[main.menu_idx].modulate = Color(.2, .2, 1, 1)
	o_scene.get_node('position').set_text(n)
	
	for lvl in all_level_details:
		if lvl['name_index'] == main.menu_list[main.menu_idx].name:
			get_node("/root/overworld_scene/lvl_deets").set_text(str(lvl['detail']))


func get_next_move_node():
	""" each number goes to the next list of numbers with matching letters 
		if we see a '+' it is a 'bridge' and can be accessed from any letter as long
		as the number is 1 before, i.e. level [1a, 2a, 3a+, 3b+, 4b, 4a, 5a+] 
		2a can go to 3a and 3b, but 1a can only go to 2a. also 4b and 4a can go to 5a"""
	var pos = overworld_position
	var all_pos = get_node("/root/overworld_scene/level_nodes").get_children()
	next_available_pos = []
	if overworld_position == '':
		next_available_pos.append(get_node("/root/overworld_scene/level_nodes/1-a"))
	else:
		for all_position in all_pos:
			all_position.modulate = Color(.7, .7, .7, .7)
			var all_p = all_position.name
			if '1' in pos:
					if '2' in all_p:
						if '+' in all_p:
							next_available_pos.append(all_position)
						else:
							if get_matching_letters(pos, all_p):
								next_available_pos.append(all_position)
			elif '2' in pos:
				if '3' in all_p:
					if '+' in all_p:
						next_available_pos.append(all_position)
					else:
						if get_matching_letters(pos, all_p):
							next_available_pos.append(all_position)
			elif '3' in pos:
				if '4' in all_p:
					if '+' in all_p:
						next_available_pos.append(all_position)
					else:
						if get_matching_letters(pos, all_p):
							next_available_pos.append(all_position)
			elif '4' in pos:
				if '5' in all_p:
					if '+' in all_p:
						next_available_pos.append(all_position)
					else:
						if get_matching_letters(pos, all_p):
							next_available_pos.append(all_position)
			elif '5' in pos:
				if '6' in all_p:
					if '+' in all_p:
						next_available_pos.append(all_position)
					else:
						if get_matching_letters(pos, all_p):
							next_available_pos.append(all_position)
			elif '6' in pos:
				if '7' in all_p:
					if '+' in all_p:
						next_available_pos.append(all_position)
					else:
						if get_matching_letters(pos, all_p):
							next_available_pos.append(all_position)
			elif '7' in pos:
				if '8' in all_p:
					if '+' in all_p:
						next_available_pos.append(all_position)
					else:
						if get_matching_letters(pos, all_p):
							next_available_pos.append(all_position)
			elif '8' in pos:
				next_available_pos.append(get_node("/root/overworld_scene/level_nodes/1-a"))
	for node in next_available_pos:
		node.modulate = Color(1, 1, 1, 1)


func get_matching_letters(pos1, pos2):
	if 'a' in pos1 and 'a' in pos2:
		return true
	elif 'b' in pos1 and 'b' in pos2:
		return true
	elif 'c' in pos1 and 'c' in pos2:
		return true
	elif 'd' in pos1 and 'd' in pos2:
		return true
	
	return false
