extends Node2D


func _ready():
	get_tree().paused = true
	Physics2DServer.set_active(true)

func _input(event):
	if main.canClick(["confirmMenuOption", "Options"]):
		if Input.is_action_pressed("quit") or Input.is_action_pressed("ui_cancel"):
			removePopUpMenu()

func removePopUpMenu():
	get_tree().paused = false
	for btns in get_tree().get_nodes_in_group("btnsToRemove"):
		btns.queue_free()
	for btns in get_tree().get_nodes_in_group("optionBtn"):
		btns.queue_free()
	queue_free()

# handle button pressing
func _on_continue_pressed():
	if main.canClick(["confirmMenuOption", "Options"]):
		removePopUpMenu()

func _on_Options_pressed():
	if main.canClick(["confirmMenuOption", "Options"]):
		if len(get_tree().get_nodes_in_group("optionBtn")) <= 0:
			var btn = main.instancer(main.options)
			btn.add_to_group("optionBtn")
		else:
			for btns in get_tree().get_nodes_in_group("optionBtn"):
				btns.queue_free()

func _on_controls_pressed():
	if main.canClick(["confirmMenuOption", "Options"]):
		pass

func _on_mainMenu_pressed():
	if main.canClick(["confirmMenuOption", "Options"]):
		main.goToMainMenu = true
		main.shouldQuit = false
		var confirmBtn = main.instancer(main.confirmMenuBtn)
		confirmBtn.add_to_group("btnsToRemove")
		confirmBtn.get_node("Label").set_text("Main Menu?")

func _on_quit_pressed():
	if main.canClick(["confirmMenuOption", "Options"]):
		main.shouldQuit = true
		main.goToMainMenu = false
		var confirmBtn = main.instancer(main.confirmMenuBtn)
		confirmBtn.add_to_group("btnsToRemove")
		confirmBtn.get_node("Label").set_text("Quit Game?")

# continue
## focus enter
func _on_continue_focus_entered():
	if main.canClick(["confirmMenuOption", "Options"]):
		globalUiDetails.focusEnterNoise()
		get_node("continue/btnBackground").modulate = globalUiDetails.focusEnterColor

func _on_continue_mouse_entered():
	if main.canClick(["confirmMenuOption", "Options"]):
		globalUiDetails.focusEnterNoise()
		get_node("continue/btnBackground").modulate = globalUiDetails.focusEnterColor

## focus exit
func _on_continue_focus_exited():
	get_node("continue/btnBackground").modulate = globalUiDetails.focusExitColor

func _on_continue_mouse_exited():
	get_node("continue/btnBackground").modulate = globalUiDetails.focusExitColor

# quit
## focus enter
func _on_quit_focus_entered():
	if main.canClick(["confirmMenuOption", "Options"]):
		globalUiDetails.focusEnterNoise()
		get_node("quit/btnBackground").modulate = globalUiDetails.focusEnterColor

func _on_quit_mouse_entered():
	if main.canClick(["confirmMenuOption", "Options"]):
		globalUiDetails.focusEnterNoise()
		get_node("quit/btnBackground").modulate = globalUiDetails.focusEnterColor

## focus exit
func _on_quit_focus_exited():
	get_node("quit/btnBackground").modulate = globalUiDetails.focusExitColor

func _on_quit_mouse_exited():
	get_node("quit/btnBackground").modulate = globalUiDetails.focusExitColor



# options
## focus enter
func _on_Options_focus_entered():
	if main.canClick(["confirmMenuOption", "Options"]):
		globalUiDetails.focusEnterNoise()
		get_node("Options/btnBackground").modulate = globalUiDetails.focusEnterColor

func _on_Options_mouse_entered():
	if main.canClick(["confirmMenuOption", "Options"]):
		globalUiDetails.focusEnterNoise()
		get_node("Options/btnBackground").modulate = globalUiDetails.focusEnterColor

## focus exit
func _on_Options_focus_exited():
	get_node("Options/btnBackground").modulate = globalUiDetails.focusExitColor

func _on_Options_mouse_exited():
	get_node("Options/btnBackground").modulate = globalUiDetails.focusExitColor


# controls
## focus enter
func _on_controls_focus_entered():
	if main.canClick(["confirmMenuOption", "Options"]):
		globalUiDetails.focusEnterNoise()
		get_node("controls/btnBackground").modulate = globalUiDetails.focusEnterColor

func _on_controls_mouse_entered():
	if main.canClick(["confirmMenuOption", "Options"]):
		globalUiDetails.focusEnterNoise()
		get_node("controls/btnBackground").modulate = globalUiDetails.focusEnterColor

## focus exit
func _on_controls_focus_exited():
	get_node("controls/btnBackground").modulate = globalUiDetails.focusExitColor

func _on_controls_mouse_exited():
	get_node("controls/btnBackground").modulate = globalUiDetails.focusExitColor


# main menu
## focus enter
func _on_mainMenu_focus_entered():
	if main.canClick(["confirmMenuOption", "Options"]):
		globalUiDetails.focusEnterNoise()
		get_node("mainMenu/btnBackground").modulate = globalUiDetails.focusEnterColor

func _on_mainMenu_mouse_entered():
	if main.canClick(["confirmMenuOption", "Options"]):
		globalUiDetails.focusEnterNoise()
		get_node("mainMenu/btnBackground").modulate = globalUiDetails.focusEnterColor

## focus exit
func _on_mainMenu_focus_exited():
	get_node("mainMenu/btnBackground").modulate = globalUiDetails.focusExitColor

func _on_mainMenu_mouse_exited():
	get_node("mainMenu/btnBackground").modulate = globalUiDetails.focusExitColor

