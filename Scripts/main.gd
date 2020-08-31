extends Node

#### PRELOADS
const PROJECTILE = preload("res://Scenes/projectile.tscn")
const POPUP_MENU = preload("res://Scenes/popupMenu.tscn")
const LEVEL = preload("res://Scenes/level.tscn")
const TILE = preload("res://Scenes/tile.tscn")
const OBJECT = preload("res://Scenes/object.tscn")
const PLAYER = preload("res://Scenes/player.tscn")
const CREATE_DECK_SCENE = preload("res://Scenes/create_deck_scene.tscn")
const CHARACTER_SELECT_SCENE = preload("res://Scenes/new_game_screen.tscn")
const ENEMY = preload("res://Scenes/enemy.tscn")
const LEVEL_OVER_SCENE = preload("res://Scenes/level_over_scene.tscn")
const sound_container = preload("res://Scenes/sound_container.tscn")
const explosion_scene = preload("res://Scenes/explosion_scene.tscn")
const OVERWORLD_SCENE = preload("res://Scenes/overworld_scene.tscn")
const DECK_SELECT_SCENE = preload("res://Scenes/choose_deck_scene.tscn")
const text_popup = preload("res://Scenes/text_popup.tscn")
const options = preload("res://Scenes/Options.tscn")
const confirmMenuBtn = preload("res://Scenes/confirmMenuOption.tscn")
const credits = preload("res://Scenes/credits.tscn")
## IMGS
const rock1 = preload("res://Sprites/objects/minimalist/New rock 2 shadow.png")
const rock2 = preload("res://Sprites/objects/minimalist/New rock shadow.png")
const rock3 = preload("res://Sprites/objects/large rock 100px.png")
const rock4 = preload("res://Sprites/objects/2-2 5.png")
const rock5 = preload("res://Sprites/objects/2-3 4.png")
const small_barricade = preload("res://Sprites/General/small barricaxe.png")
const cactus = preload("res://Sprites/General/new cactus small.png")

const WARNING_SYMBOL = preload("res://Sprites/objects/warning icon.png")

var object_imgs = [{'img': rock1, 'size': Vector2(1, 1), 'shadow_rotation': (0)},
					{'img': rock2, 'size': Vector2(1, 1), 'shadow_rotation': (0)}]

const TAN_TILE = preload("res://Sprites/General/tan tile.png")
const DARK_BLUE_TILE = preload("res://Sprites/General/dark blue tile.png")
const DARK_YELLOW_TILE = preload("res://Sprites/General/dark yellow tile.png")
const GRID_TILE = preload("res://Sprites/General/small grid tile.png")
const GRID_WATER = preload("res://Sprites/General/desert race water.png")
const PIT_TILE = preload("res://Sprites/tile/Pit.png")
const PIT_TOP_TILE = preload("res://Sprites/tile/Pit open bottom.png")
const PIT_BOTTOM_TILE = preload("res://Sprites/tile/Pit open top.png")
const PIT_OPEN_TILE = preload("res://Sprites/tile/Pit open completely.png")

# pit object img
const PIT_OBJ_OPEN = preload("res://Sprites/objects/minimalist/Side pit completely open.png")
const PIT_OBJ_CLOSED = preload("res://Sprites/objects/minimalist/Side pit closed.png")
const PIT_OBJ_TOP_OPEN = preload("res://Sprites/objects/minimalist/Side pit top open.png")
const PIT_OBJ_BOTTOM_OPEN = preload("res://Sprites/objects/minimalist/Side pit open bottom.png")

const BLACK_CHECKER = preload("res://Sprites/tile/Black checker.png")
const WHITE_CHECKER = preload("res://Sprites/tile/White checker.png")
const CHECKER = preload("res://Sprites/tile/Checker.png")

const smoke_puff = preload("res://Scenes/smoke puff.tscn")

# overworld node
const cross_pos = preload("res://Sprites/General/cross pos.png")
const level_pos = preload("res://Sprites/General/blank pos.png")
const blank_pos = preload("res://Sprites/General/level pos.png")

####


#### SAVE LOAD VARS
var game_name = 'Desert_Racer'
var playerFilepath = "user://Desert_Racer_playerData_.data"
var dataFilepath = "user://Desert_Racer_gameData_.data"

#### END OF SAVE LOAD VARS

#### MENU VARS
var in_menu = true
var current_menu = 'main'
var menu_idx = 0
var menu_list = []

var game_started = false
var holdMenu = null
var waitToProcessMenuClick = false
var optionsMenu = null
var confirmOptionMenu = null
var goToMainMenu = false
var shouldQuit = false

var shaking = false

var master_sound = null
#### END OF MENU VARS

#### CONTROLLER
var useController = true
var controllerCursorObj = false
#### END OF CONTROLLER


#### MAIN READY/PROCESS
func _ready():
	randomize()
	test_all_cards()
	master_sound = instancer(sound_container, null, true)
	master_sound.get_node("chords").play()
	menu_idx = 0
	get_node("/root/startingScene/buttons/start").modulate = globalUiDetails.focusEnterColor


#func _process(delta):
#	pass
#### END OF MAIN READY/PROCESS



#### SAVE LOAD FUNCS
var debug_remove_save_file = false

func loadGameData(onlyGameData=false):
	print("loading...")
	var file = File.new()
	if file.file_exists(dataFilepath) and not debug_remove_save_file:
		file.open(dataFilepath, File.READ)
		meta.savable.had_tutorial = file.get_var()
		file.close()
		print("loaded " + str(dataFilepath))
	elif debug_remove_save_file and game_name in dataFilepath:
		var dir = Directory.new()
		dir.remove(dataFilepath)
		print('removed save dataFilepath, does it exist? ' + str(file.file_exists(dataFilepath)))
	else:
		print(str(dataFilepath) + " not found.")

func saveGameData():
	print("Saving... " + str(dataFilepath))
	var file = File.new()
	file.open(dataFilepath, File.WRITE)
	file.store_var(meta.savable.had_tutorial)
	file.close()
	print("saved " + str(dataFilepath))

#### END OF SAVE LOAD FUNCS


#### INPUT FUNCS #MOVE TO INPUT ONLY NODE/SCRIPT
var can_click_any = true
var can_click_start = true
var can_click_quit = true

func _input(event):
   # Mouse in viewport coordinates
	if not can_click_any:
		return
	if Input.is_action_pressed("ui_quit") and can_click_quit: 
		can_click_quit = false
		if master_sound: master_sound.get_node("sci fi select").play()
		if in_menu:
			handle_menus('quit')
		else:
			if not waitToProcessMenuClick:
				waitToProcessMenuClick = true
				for btns in get_tree().get_nodes_in_group("btnsToRemove"):
					btns.queue_free()
				holdMenu = main.instancer(POPUP_MENU, null, true, "btnsToRemove")
				# Adding wait to avoid multi clicks
				var timer = Timer.new()
				timer.set_wait_time(.5)
				timer.set_one_shot(true)
				get_node("/root").add_child(timer)
				timer.start()
				yield(timer, "timeout")
				timer.queue_free()
				# end of wait
				waitToProcessMenuClick = false
		handle_input_delay('quit')
	elif Input.is_action_just_pressed("start") and can_click_start:
		can_click_start = false
		if in_menu:
			handle_menus("start")
		else:
			turn.play_card(true, true)
		handle_input_delay('start')
	elif Input.is_action_just_pressed("click"):
		pass
		#turn.handle_turn()
	elif Input.is_action_just_pressed("spacebar"):
		var l = get_node("/root/level")
		if l:
			l.spawn_objects()
			handle_input_delay()
	elif Input.is_action_just_pressed("up"):
		if in_menu:
			handle_menus("up")
		else:
			game.hand_idx = validate_menu_idx(game.hand_idx, game.hand, 'right')
			game.highlight_card()
		handle_input_delay()
	elif Input.is_action_just_pressed("down"):
		if in_menu:
			handle_menus("down")
		else:
			game.hand_idx = validate_menu_idx(game.hand_idx, game.hand, 'left')
			game.highlight_card()
		handle_input_delay()
	elif Input.is_action_just_pressed("right"):
		if in_menu:
			handle_menus("right")
		else:
			game.hand_idx = validate_menu_idx(game.hand_idx, game.hand, 'right')
			game.highlight_card()
		handle_input_delay()
	elif Input.is_action_just_pressed("left"):
		if in_menu:
			handle_menus("left")
		else:
			game.hand_idx = validate_menu_idx(game.hand_idx, game.hand, 'left')
			game.highlight_card()
		handle_input_delay()


func handle_input_delay(type='any'):
	var delay = .01
	if type == 'start' or type == 'quit':
		delay = .2
	var timer = Timer.new()
	timer.set_wait_time(delay)
	timer.set_one_shot(true)
	get_node("/root").add_child(timer)
	timer.start()
	yield(timer, "timeout")
	timer.queue_free()
	if type == 'any': can_click_any = true
	if type == 'start': can_click_start = true
	if type == 'quit': can_click_quit = true


func handle_menus(dir):
	var main_menu_buttons = null
	var c_scene = null
	if current_menu == 'main':
		main_menu_buttons = get_node("/root/startingScene/buttons").get_children()
		for b in main_menu_buttons:
			b.modulate = globalUiDetails.focusExitColor
	elif 'create' in current_menu:
		c_scene = get_node('/root/create_deck_scene')
	elif current_menu == 'credits':
		current_menu = 'main'
		menu_idx = 0
		main_menu_buttons = get_node("/root/startingScene/buttons").get_children()
		menu_idx = validate_menu_idx(menu_idx, main_menu_buttons, 'left')
		if get_node("/root").has_node("credits") and checkIfNodeDeleted(get_node("/root/credits")) == false:
			get_node("/root/credits").queue_free()
		return

	if dir == 'left':
		if main.master_sound: main.master_sound.get_node("card swipe").play()
		if current_menu == 'main':
			menu_idx = validate_menu_idx(menu_idx, main_menu_buttons, 'left')
		elif 'deck_select' in current_menu:
			if menu_list != meta.savable.player.decks: menu_list = meta.savable.player.decks
			menu_idx = validate_menu_idx(menu_idx, menu_list, 'left')
			get_node("/root/choose_deck_scene").show_next_deck()
		elif current_menu == 'overworld':
			menu_idx = validate_menu_idx(menu_idx, menu_list, 'left')
			overworld.set_node_details(menu_list[menu_idx])
		elif 'create' in current_menu:
			menu_idx = validate_menu_idx(menu_idx, menu_list, dir)
			c_scene.adjust_focus(menu_list, menu_idx)
			meta.animate_cycle_card(menu_list[menu_idx], false)
			for c in menu_list:
				c.set_scale(c_scene.unfocused_size)
			menu_list[menu_idx].modulate = c_scene.HIGHLIGHT_COLOR
			menu_list[menu_idx].set_scale(c_scene.focused_size)
		elif 'character_select' in current_menu:
			if menu_list != meta.char_list: menu_list = meta.char_list
			var new_game_scene = get_node("/root/new_game_screen")
			meta.char_idx = validate_menu_idx(meta.char_idx, menu_list, 'left')
			new_game_scene.show_char_details()
			new_game_scene.get_node("arrow anim").stop()
			new_game_scene.get_node("arrow anim").play("arrow left")
			main.master_sound.get_node("engine noise 1").stop()
			main.master_sound.get_node("engine noise 2").stop()
			if meta.char_list[meta.char_idx].character == 'TECH':
				main.master_sound.get_node("engine noise 2").volume_db = -10
				main.master_sound.get_node("tech_passby").play()
				main.master_sound.get_node("engine noise 2").play()
			if meta.char_list[meta.char_idx].character == 'SLICK':
				main.master_sound.get_node("engine noise 1").volume_db = -10
				main.master_sound.get_node("engine_passby").play()
				main.master_sound.get_node("engine noise 1").play()
	if dir == 'right':
		if main.master_sound: main.master_sound.get_node("card swipe").play()
		if current_menu == 'main':
			menu_idx = validate_menu_idx(menu_idx, main_menu_buttons, 'right')
		elif 'deck_select' in current_menu:
			if menu_list != meta.savable.player.decks: menu_list = meta.savable.player.decks
			menu_idx = validate_menu_idx(menu_idx, menu_list, 'right')
			get_node("/root/choose_deck_scene").show_next_deck()
		elif current_menu == 'overworld':
			menu_idx = validate_menu_idx(menu_idx, menu_list, 'right')
			overworld.set_node_details(menu_list[menu_idx])
		elif 'create' in current_menu:
			menu_idx = validate_menu_idx(menu_idx, menu_list, dir)
			c_scene.adjust_focus(menu_list, menu_idx)
			meta.animate_cycle_card(menu_list[menu_idx], true)
			for c in menu_list:
				c.set_scale(c_scene.unfocused_size)
			menu_list[menu_idx].modulate = c_scene.HIGHLIGHT_COLOR
			menu_list[menu_idx].set_scale(c_scene.focused_size)
		elif 'character_select' in current_menu:
			if menu_list != meta.char_list: menu_list = meta.char_list
			var new_game_scene = get_node("/root/new_game_screen")
			meta.char_idx = validate_menu_idx(meta.char_idx, menu_list, 'right')
			new_game_scene.show_char_details()
			new_game_scene.get_node("arrow anim").stop()
			new_game_scene.get_node("arrow anim").play("arrow right")
			main.master_sound.get_node("engine noise 1").stop()
			main.master_sound.get_node("engine noise 2").stop()
			if meta.char_list[meta.char_idx].character == 'TECH':
				main.master_sound.get_node("engine noise 2").volume_db = -10
				main.master_sound.get_node("tech_passby").play()
				main.master_sound.get_node("engine noise 2").play()
			if meta.char_list[meta.char_idx].character == 'SLICK':
				main.master_sound.get_node("engine noise 1").volume_db = -10
				main.master_sound.get_node("engine_passby").play()
				main.master_sound.get_node("engine noise 1").play()
	if dir == 'up':
		if main.master_sound: main.master_sound.get_node("card swipe").play()
		if current_menu == 'main':
			menu_idx = validate_menu_idx(menu_idx, main_menu_buttons, 'left')
		elif 'create' in current_menu:
			c_scene.get_node('card_container/arrow').visible = false
			c_scene.get_node('card_container/AnimationPlayer').stop()
			c_scene.get_node('deck_container/arrow').visible = false
			c_scene.get_node('deck_container/AnimationPlayer').stop()
			if menu_list != c_scene.current_deck_display and len(c_scene.current_deck_display) > 0:
				#print('current?')
				c_scene.in_deck = true
				menu_list = c_scene.current_deck_display
				menu_idx = 0
				menu_idx = validate_menu_idx(menu_idx, menu_list, 'left')
				c_scene.adjust_focus(menu_list, menu_idx)
			elif menu_list != c_scene.all_instanced_cards:
				#print('all_instanced_cards?')
				c_scene.in_deck = false
				menu_list = c_scene.all_instanced_cards
				menu_idx = 0
				c_scene.adjust_focus(menu_list, menu_idx)
			for c in menu_list:
				c.set_scale(c_scene.unfocused_size)
			menu_list[menu_idx].modulate = c_scene.HIGHLIGHT_COLOR
			menu_list[menu_idx].set_scale(c_scene.focused_size)
	if dir == 'down':
		if main.master_sound: main.master_sound.get_node("card swipe").play()
		if current_menu == 'main':
			menu_idx = validate_menu_idx(menu_idx, main_menu_buttons, 'right')
		elif 'create' in current_menu:
			c_scene.get_node('card_container/arrow').visible = false
			c_scene.get_node('card_container/AnimationPlayer').stop()
			c_scene.get_node('deck_container/arrow').visible = false
			c_scene.get_node('deck_container/AnimationPlayer').stop()
			if menu_list != c_scene.current_deck_display and len(c_scene.current_deck_display) > 0:
				c_scene.in_deck = true
				menu_list = c_scene.current_deck_display
				menu_idx = 0
				c_scene.adjust_focus(menu_list, menu_idx)
			elif menu_list != c_scene.all_instanced_cards:
				c_scene.in_deck = false
				menu_list = c_scene.all_instanced_cards
				menu_idx = 0
				c_scene.adjust_focus(menu_list, menu_idx)
			for c in menu_list:
				c.set_scale(c_scene.unfocused_size)
			menu_list[menu_idx].modulate = c_scene.HIGHLIGHT_COLOR
			menu_list[menu_idx].set_scale(c_scene.focused_size)
	if dir == 'start':
		if main.master_sound: main.master_sound.get_node("sci fi select").play()
		if current_menu == 'main':
			if main_menu_buttons and menu_idx > 0 or menu_idx < len(main_menu_buttons):
				if main_menu_buttons[menu_idx].name == 'start':
					in_menu = true
					current_menu = 'overworld'
					var o = instancer(OVERWORLD_SCENE)
					if not overworld.world_generated:
						overworld.set_overworld_level_details()
					if overworld.overworld_position == '' or overworld.overworld_position == '1-a':
						o.get_node("char").visible = false
					else:
						o.get_node("char").visible = true
						o.get_node("char").set_text(str(meta.savable.player.character))
					overworld.set_node_imgs()
					menu_idx = 0
					overworld.get_next_move_node()
					menu_list = overworld.next_available_pos
					overworld.set_node_details(menu_list[menu_idx])
				elif main_menu_buttons[menu_idx].name == 'create deck':
					current_menu = 'create'
					var create_scene = instancer(CREATE_DECK_SCENE)
					create_scene.spawn_cards()
					create_scene.adjust_focus(menu_list, menu_idx)
				elif main_menu_buttons[menu_idx].name == 'options':
					holdMenu = main.instancer(POPUP_MENU, null, true, "btnsToRemove")
				elif main_menu_buttons[menu_idx].name == 'quit':
					get_tree().quit()
				elif main_menu_buttons[menu_idx].name == 'credits':
					var c = main.instancer(credits, null, true)
					current_menu = 'credits'
		elif 'create' in current_menu:
			var limit_hit = c_scene.move_card_to_deck(menu_list, menu_idx)
			c_scene.adjust_focus(c_scene.current_deck_display, menu_idx)
			if not limit_hit:
				c_scene.adjust_focus(menu_list, menu_idx)
			for c in menu_list:
				c.set_scale(c_scene.unfocused_size)
			menu_list[menu_idx].modulate = c_scene.HIGHLIGHT_COLOR
			menu_list[menu_idx].set_scale(c_scene.focused_size)
		elif 'character_select' in current_menu:
			for n in get_tree().get_nodes_in_group("remove_on_game_start"):
				if checkIfNodeDeleted(n) == false:
					n.queue_free()
			game.set_character_and_cart()
			game_started = true
			in_menu = false
			var l = instancer(LEVEL)
			l.spawn_tiles()
			l.spawn_player()
		elif 'overworld' in current_menu:
			if not overworld.set_level_details(menu_list[menu_idx]):
				# start level
				overworld.overworld_position = menu_list[menu_idx].name
				current_menu = 'deck_select'
				var dss = main.instancer(DECK_SELECT_SCENE)
				main.menu_idx = 0
				main.menu_list = meta.savable.player.decks
				dss.show_next_deck()
			else:
				# level is a 'passthrough' (skipable) see overworld.gd
				overworld.overworld_position = menu_list[menu_idx].name
				overworld.get_next_move_node()
				menu_list = overworld.next_available_pos
				menu_idx = validate_menu_idx(menu_idx, menu_list, 'right')
				overworld.set_node_details(menu_list[menu_idx])
		elif 'deck_select' in current_menu:
			for n in get_tree().get_nodes_in_group("shown_deck_card"):
				if checkIfNodeDeleted(n) == false:
					n.queue_free()
			if get_node("/root").has_node("choose_deck_scene"):
				 get_node("/root/choose_deck_scene").queue_free()
			if len(meta.savable.player.game_deck) > 0:
				meta.savable.player.game_deck = []
			meta.savable.player.game_deck = meta.savable.player.decks[main.menu_idx].duplicate()
			current_menu = 'overworld'
			if overworld.overworld_position == '' or overworld.overworld_position == '1-a':
				current_menu = 'character_select'
				var cs = instancer(CHARACTER_SELECT_SCENE)
				menu_list = meta.char_list
				meta.char_idx = 0
				main.master_sound.get_node("engine noise 1").stop()
				main.master_sound.get_node("engine noise 2").stop()
				if meta.char_list[meta.char_idx].character == 'SLICK':
					main.master_sound.get_node("tech_passby").play()
					main.master_sound.get_node("engine noise 2").play()
				if meta.char_list[meta.char_idx].character == 'TECH':
					main.master_sound.get_node("engine_passby").play()
					main.master_sound.get_node("engine noise 1").play()
			else:
				for n in get_tree().get_nodes_in_group("remove_on_game_start"):
					if checkIfNodeDeleted(n) == false:
						n.queue_free()
				game_started = true
				in_menu = false
				current_menu = 'game'
				var l = instancer(LEVEL)
				l.spawn_tiles()
				l.spawn_player()
		elif 'level_over' in current_menu:
			meta.clear_captures()
			meta.playing_screen_cap = false
			
			if game.level_won:
				if '8' in overworld.overworld_position:
					overworld.world_generated = false
				in_menu = true
				current_menu = 'overworld'
				var o = instancer(OVERWORLD_SCENE)
				if not overworld.world_generated:
					overworld.set_overworld_level_details()
				o.get_node("char").set_text(str(meta.savable.player.character))
				overworld.set_node_imgs()
				menu_idx = 0
				overworld.get_next_move_node()
				menu_list = overworld.next_available_pos
				overworld.set_node_details(menu_list[menu_idx])
			else:
				overworld.world_generated = false
				current_menu = 'main'
			if get_node("/root").has_node("level_over_scene"):
				var los = get_node("/root/level_over_scene")
				if checkIfNodeDeleted(los) == false:
					los.queue_free()

	if dir == 'quit':
		if current_menu == 'main':
			pass
		elif current_menu == 'create':
			if get_node("/root").has_node("create_deck_scene"):
				var create_scene =  get_node("/root/create_deck_scene")
				create_scene.return_to_menu()
			current_menu = 'main'
			menu_idx = 0
		elif 'character_select' in current_menu:
			for n in get_tree().get_nodes_in_group("remove_on_game_start"):
				if checkIfNodeDeleted(n) == false:
					n.queue_free()
			current_menu = 'main'
			menu_idx = 0

	if current_menu == 'main':
		if not main_menu_buttons: main_menu_buttons = get_node("/root/startingScene/buttons").get_children()
		if menu_idx >= 0 and menu_idx < len(main_menu_buttons) and len(main_menu_buttons) > 0:
			main_menu_buttons[menu_idx].modulate = globalUiDetails.focusEnterColor

#### END OF INPUT FUNCS


#### HELPER FUNCS
func checkIfNodeDeleted(nodeToCheck, eraseNode=false):
	if not nodeToCheck or 'Deleted' in str(nodeToCheck) or 'Object:0' in str(nodeToCheck) or not nodeToCheck.get_parent(): # nodeToCheck.is_queued_for_deletion()
		if eraseNode:
			print('should erase?')
		return true
	return false

# add nodes to check wether we should allowing clicking
func canClick(nodesAsStrIfDefinedClickIsFalse=[], parentToCheck=get_node("/root")):
	for node in nodesAsStrIfDefinedClickIsFalse:
		if parentToCheck.has_node(node):
			return false
	return true

func saveAndQuit(shouldSave=true):
	if shouldSave:
		pass
	get_tree().quit()


func end_all_sound():
	for s in master_sound.get_children():
		s.stop()

func handle_card_noises(card):
	if 'move' in str(card.details.type):
		main.get_char_move_noises()
	if 'projectile' in str(card.details.type):
		main.master_sound.get_node("impact_quick").play()
	if 'buff' in str(card.details.type):
		main.master_sound.get_node("sci_fi_effect 2").play()


func get_char_move_noises():
	if meta.char_list[meta.char_idx].character == 'SLICK':
		main.master_sound.get_node("tech_passby").play()
	if meta.char_list[meta.char_idx].character == 'TECH':
		main.master_sound.get_node("engine_passby").play()


func cameraShake(mag, length):
	randomize()
	if not get_node("/root").has_node("cam"):
		return
	var cam = get_node("/root/cam")
	var magnitude = mag if mag <= 10 else 10
	var timeToShake = length if length <= 4 else 4
	if shaking:
		return
	while timeToShake > 0:
		shaking = true
		var pos = Vector2()
		pos.x = rand_range(-magnitude, magnitude)
		pos.y = rand_range(-magnitude, magnitude)
		cam.position = pos
		timeToShake -= get_process_delta_time()

		var timer = Timer.new()
		timer.set_wait_time(.015)
		timer.set_one_shot(true)
		get_node("/root").add_child(timer)
		timer.start()
		yield(timer, "timeout")
		timer.queue_free()

	magnitude = 0
	shaking = false


func instancer(objToInstance=null, parent=null, addDeferred=false, addToThisGroup=null, returnObj=true):
	# Check for accurate data
	if objToInstance != null:
		var newObj = objToInstance.instance()

		## add Specific parent or swap to root
		addToParent(newObj, parent, addDeferred)
		
		## add this obj to group if we wanted to
		if addToThisGroup != null:
			newObj.add_to_group(addToThisGroup)
		
		# Return Object back
		if returnObj:
			return newObj

	# Give feedback for issues
	else:
		print("Failed object is: " + str(objToInstance))


func addToParent(objRecievingParent=null, parent=null, addDeferred=false, hard_set=true):
	var root = get_tree().get_root()
	# Check for accurate data
	if objRecievingParent != null:

		## If no parent given use root node
		if parent == null:
			parent = root

			### check if it already has  parent
			if not objRecievingParent.get_parent() or hard_set:

				#### Check if calling deferred or not
				if addDeferred:
					parent.call_deferred("add_child", objRecievingParent)
				else:
					parent.add_child(objRecievingParent)

	# Give feedback for issues
	else:
		print("Failed attempting to add a parent to: " + str(objRecievingParent))


func validate_menu_idx(idx, current_menu_list, dir):
	var i = idx
	var menu = current_menu_list
	var go_up = dir == 'right'

	if go_up:
		i += 1
	else:
		i -= 1

	if i < 0:
		i = len(menu) - 1
	if i >= len(menu):
		i = 0
	return i


func clean_array_as_string(array):
	return str(array).replace('[', '').replace(']', '').replace(',', '')


# used to return statuses for easy debug info atm
func return_stringed_key_vals(dict):
	var p = meta.savable.player_details
	var s = []
	for key in dict.keys():
		var new_val = '\n' + str(key) + ':  '
		if typeof(dict[key]) == 18:
			for key2 in dict[key].keys():
				new_val += '\n --' + str(key2) + ':  ' + str(dict[key][key2])
		else:
			new_val += str(dict[key])
		s.append(new_val)
	return clean_array_as_string(s)


func test_all_cards():
	""" UNIT TEST REMOVE CALL FOR PRODUCTION """
	var should_err = false
	var test_cards = []
	var card_count = 0
	print('\n\n')
	print('validating all cards keys against card_preload template')
	
	for card in card_preload.total_deck:
		var c = instancer(card, null, true)
		card_count += 1
		test_cards.append(c)
		var test_failed = validate_card_against_template(c)
		
		# Check once so we don't overwrite on success, i.e...
		# even if only 1 error should still run and log all and quit
		if test_failed and not should_err:
			should_err = true
	for c in test_cards:
		if not c.remote_set:
			pass # will error if not set
	# remove cards and remove from array for performance 
	clear_array(test_cards)
	print('test_cards left ' + str(test_cards) + ' ' + str(len(test_cards)))
	print('cards tested ' + str(card_count))
	if should_err:
		get_tree().quit()
	else:
		print('success!')
	print('\n\n')


func clear_array(array):
	for i in range(0, len(array)):
		if checkIfNodeDeleted(array[len(array)-1]) == false:
			array[len(array)-1].queue_free()
			array.erase(array[len(array)-1])


func validate_card_against_template(card):
	var expected_keys = []
	var found_keys = []
	var missing_keys = []
	var matched = false
	var expected = 0
	var count = 0
	for key in card_preload.card_detail_template.keys():
		expected += 1
		expected_keys.append(str(key))
		if typeof(card_preload.card_detail_template[key]) == 18:
			for key2 in card_preload.card_detail_template[key].keys():
				expected_keys.append(str(key2))
				expected += 1
	for key in card.details.keys():
		for expected_key in card_preload.card_detail_template.keys():
			if key == expected_key:
				count += 1
				found_keys.append(str(key))
				if typeof(card_preload.card_detail_template[expected_key]) == 18 and\
				   typeof(card.details[key]) == 18:
					for expected2 in card_preload.card_detail_template[expected_key].keys():
						for key2 in card.details[key].keys():
							if expected2 == key2:
								found_keys.append(str(key2))
								count += 1

	for expected_key in expected_keys:
		matched = false
		for key in found_keys:
			if key == expected_key:
				matched = true
		if not matched:
			missing_keys.append(str(expected_key))
	if count != expected:
		print(' ')
		print('ERROR: Check keys in ' + str(card.name) + ' missing: ' + str(missing_keys))
		return true
	print('keys in card details dict for ' + str(card.name) + ' expected ' + str(expected) + ' got ' + str(count))
	print(' ')
	return false
#### END OF HELPER FUNCS
