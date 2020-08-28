# confirmMenuOption.gd
# Confirm choice to avoid accidental clicks on menu
# potentially ending game and losing progress
extends Node2D

#const mainMenu = preload("res://Scenes/mainMenu.tscn")

var fauxParent = false
var countDown = 9 # auto countdown to select menu option

func _ready():
	if get_node("/root").has_node("popupMenu"):
		fauxParent = true

	showCountDown()

func showCountDown():
	# auto click "yes" after time passed
	while countDown > -1:
		get_node("countDownLabel").set_text(str(countDown))
		countDown -= 1
		var timer = Timer.new()
		if not timer.get_parent():
			if fauxParent:
				get_node("/root/popupMenu").add_child(timer)
			else:
				get_node("/root").add_child(timer)
		timer.set_wait_time(1)
		timer.set_one_shot(true)
		timer.start()
		yield(timer, "timeout")
		timer.queue_free()
	if main.shouldQuit or main.goToMainMenu:
		yes()


func _input(event):
	if Input.is_action_pressed("quit") or Input.is_action_pressed("ui_cancel"):
		main.shouldQuit = false
		main.goToMainMenu = false
		queue_free()

func _on_yes_pressed():
	yes()

func _on_no_pressed():
	no()

func no():
	main.shouldQuit = false
	main.goToMainMenu = false
	queue_free()

func yes():
	if main.shouldQuit: # quit out of application
		main.shouldQuit = false
		main.saveAndQuit()
	if main.goToMainMenu: # return to main menu
		main.goToMainMenu = false
		main.current_menu = 'main'
		main.game_started = false
		main.in_menu = true
		game.end_level()
		#main.endGame()
		if fauxParent: get_node("/root/popupMenu").removePopUpMenu()


# Yes button
## focus enter
func _on_yes_mouse_entered():
	get_node("yes/Sprite").modulate = globalUiDetails.focusEnterColor

func _on_yes_focus_entered():
	get_node("yes/Sprite").modulate = globalUiDetails.focusEnterColor

## focus leave
func _on_yes_focus_exited():
	get_node("yes/Sprite").modulate = globalUiDetails.focusExitColor

func _on_yes_mouse_exited():
	get_node("yes/Sprite").modulate = globalUiDetails.focusExitColor


# No button
## focus enter
func _on_no_focus_entered():
	get_node("no/Sprite").modulate = globalUiDetails.focusEnterColor

func _on_no_mouse_entered():
	get_node("no/Sprite").modulate = globalUiDetails.focusEnterColor

## focus leave
func _on_no_focus_exited():
	get_node("no/Sprite").modulate = globalUiDetails.focusExitColor

func _on_no_mouse_exited():
	get_node("no/Sprite").modulate = globalUiDetails.focusExitColor
