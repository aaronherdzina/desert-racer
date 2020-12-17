extends Node

#const cursor = preload("res://Scenes/controllerCursor.tscn")

func _ready():
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass


func _on_start_pressed():
	if main.can_click_start and main.current_menu == 'main':
		if main.master_sound: main.master_sound.get_node("sci fi select").play()
		main.call_start_new_game()


func _on_create_pressed():
	if main.can_click_start and main.current_menu == 'main':
		if main.master_sound: main.master_sound.get_node("sci fi select").play()
		main.call_create_scene()


func _on_options_pressed():
	if main.can_click_start and main.current_menu == 'main':
		if main.master_sound: main.master_sound.get_node("sci fi select").play()
		main.holdMenu = main.instancer(main.POPUP_MENU, null, true, "btnsToRemove")


func _on_quit_pressed():
	if main.can_click_start and main.current_menu == 'main':
		if main.master_sound: main.master_sound.get_node("sci fi select").play()
		get_tree().quit()


func process_matching_node_with_mouse(mouse_node):
	if main.can_click_start and main.current_menu == 'main':
		if main.master_sound: main.master_sound.get_node("card swipe").play()
		for i in range(0, len(main.main_menu_buttons)):
			if mouse_node == main.main_menu_buttons[i]:
				main.menu_idx = i
				main.main_menu_buttons[i].modulate = globalUiDetails.focusEnterColor
			else:
				main.main_menu_buttons[i].modulate = globalUiDetails.focusExitColor

func _on_Button_mouse_entered():
	process_matching_node_with_mouse(self)

func _on_start_mouse_entered():
	process_matching_node_with_mouse($buttons/start)


func _on_start_mouse_exited():
	pass


func _on_create_mouse_entered():
	process_matching_node_with_mouse(get_node("buttons/create deck"))


func _on_create_mouse_exited():
	pass # Replace with function body.


func _on_options_mouse_entered():
	process_matching_node_with_mouse($buttons/options)


func _on_options_mouse_exited():
	pass # Replace with function body.


func _on_quit_mouse_entered():
	process_matching_node_with_mouse($buttons/quit)


func _on_quit_mouse_exited():
	pass # Replace with function body.
