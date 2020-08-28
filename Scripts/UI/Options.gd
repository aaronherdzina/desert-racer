extends Node

var keepChanges = false
var holdX
var holdY
var waiting = false
var muted = false
var setVolume = 0
var menuReady = true
var useController = "Off"
var btnvol = 0

func _process(delta):
	if get_node("cont1/Control/useController").text != "Keyboard & Mouse" and not main.useController:
		get_node("cont1/Control/useController").text = "Keyboard & Mouse"
	elif get_node("cont1/Control/useController").text != "Gamepad" and main.useController:
		get_node("cont1/Control/useController").text = "Gamepad"

func _ready():
	menuReady = false
	fullBtnCanPress = false
	muteBtnCanPress = false
	contBtnCanPress = false
	holdY = main.get_viewport().size.y
	holdX = main.get_viewport().size.x
	get_node("cont1/Control/Container/width").text = str(holdX)
	get_node("cont1/Control/Container/height").text = str(holdY)
	
	if get_node("cont1/Control/useController").text != "Keyboard & Mouse" and not main.useController:
		get_node("cont1/Control/useController").text = "Keyboard & Mouse"
	elif get_node("cont1/Control/useController").text != "Gamepad" and main.useController:
		get_node("cont1/Control/useController").text = "Gamepad" 
	set_process(true)
	pauseClicking()
	#btnvol = saveLoadData.globalOptions.soundLevel if saveLoadData.globalOptions.soundLevel != 0 else setVolume
	btnvol = 0
	get_node("cont1/Control/Container/audio/label2").set_text(str(btnvol))

func changeMasterVolume(value):
	# set 
	var displayValue = 100 if value >= 99 else value
	if value < -100:
		displayValue = -100
	get_node("cont1/Control/Container/audio/label2").set_text(str(displayValue))
	if value >= 100:
		value = 94
	elif value <= -95:
		muted = true
		value = -1000
	elif value > 0 or value < 0:
		value *= .20
	else:
		value = 0
	if value > -2 and value < 2:
		value = 0
	if value > -100:
		setVolume = value
		muted = false
		get_node("cont1/Control/Container/audio/CheckBox").pressed = false
	else:
		get_node("cont1/Control/Container/audio/CheckBox").pressed = true
		muted = true
	#saveLoadData.globalOptions.soundLevel = value
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), value)

func _on_CheckBox_pressed():
	if fullBtnCanPress:
		globalUiDetails.clickNoise()
		globalUiDetails.focusEnterNoise()
		updateFullscreen()

func updateFullscreen():
	if OS.window_fullscreen:
		#saveLoadData.globalOptions.fullscreen = false
		get_node("cont1/Control/Container/Fullscreen/CheckBox").pressed = false
	else:
		#saveLoadData.globalOptions.fullscreen = true
		get_node("cont1/Control/Container/Fullscreen/CheckBox").pressed = true
	OS.window_fullscreen = !OS.window_fullscreen

var fullBtnCanPress = true
func _on_Fullscreen_pressed():
	if fullBtnCanPress:
		globalUiDetails.clickNoise()
		globalUiDetails.focusEnterNoise()
		updateFullscreen()

func _on_height_text_entered(new_text):
	if not waiting:
		globalUiDetails.focusEnterNoise()
		keepChanges = false
		get_node("cont1/Control/Container/keepResolutionChanges").visible = true
		main.get_viewport().size = Vector2(float(get_node("cont1/Control/Container/width").text), float(get_node("cont1/Control/Container/height").text))
		waitForChange()

func _on_width_text_entered(new_text):
	if not waiting:
		globalUiDetails.focusEnterNoise()
		keepChanges = false
		get_node("cont1/Control/Container/keepResolutionChanges").visible = true
		main.get_viewport().size = Vector2(float(get_node("cont1/Control/Container/width").text), float(get_node("cont1/Control/Container/height").text))
		waitForChange()

func waitForChange():
	get_node("cont1/Control/Container/width").text = str(main.get_viewport().size.x)
	get_node("cont1/Control/Container/height").text = str(main.get_viewport().size.y)
	waiting = true
	print("waiting")
	var timer = Timer.new()
	timer.set_wait_time(5)
	timer.set_one_shot(true)
	if not timer.get_parent():
		add_child(timer)
	timer.start()
	yield(timer, "timeout")
	if not keepChanges:
		print("reverting to " + str(holdX) + " x " + str(holdY))
		main.get_viewport().size = Vector2(holdX, holdY)
	waiting = false
	

func _on_keepResolutionChanges_pressed():
	globalUiDetails.clickNoise()
	globalUiDetails.focusEnterNoise()
	keepChanges = true
	get_node("cont1/Control/Container/width").text = str(main.get_viewport().size.x)
	get_node("cont1/Control/Container/height").text = str(main.get_viewport().size.y)
	#saveLoadData.globalOptions.resolutionX = main.get_viewport().size.x
	#saveLoadData.globalOptions.resolutionY = main.get_viewport().size.y
	get_node("cont1/Control/Container/keepResolutionChanges").visible = false



func _on_Back_Button_pressed():
	globalUiDetails.clickNoise()
	globalUiDetails.focusEnterNoise()
	#saveLoadData.saveOptionData()
	if get_node("/root/main").has_node("mainMenu"):
		get_node("/root/main/mainMenu").canClick = true
		get_node("/root/main/mainMenu").pauseClicking()
		main.controllerBtns = []
		main.controllerBtns.append(get_node("/root/main/mainMenu/NewGame"))
		main.controllerBtns.append(get_node("/root/main/mainMenu/Options"))
		main.controllerBtns.append(get_node("/root/main/mainMenu/Quit"))
		
	if get_node("/root").has_node("menu"):
		get_node("/root/menu").canClick = true
		get_node("/root/menu").pauseClicking()
		main.controllerBtns = []
		main.delayedRemoveMenu()
		get_node("/root/menu").removePopUpMenu()
	
	queue_free()


func _on_HSlider_value_changed(value):
	changeMasterVolume(value)

var muteBtnCanPress = true
func _on_Button_pressed():
	if muteBtnCanPress:
		globalUiDetails.clickNoise()
		globalUiDetails.focusEnterNoise()
		if muted:
			changeMasterVolume(setVolume)
		else:
			changeMasterVolume(-1000)


func _on_AudioCheckBox_pressed():
	if muteBtnCanPress:
		globalUiDetails.clickNoise()
		globalUiDetails.focusEnterNoise()
		if muted:
			changeMasterVolume(setVolume)
		else:
			changeMasterVolume(-1000)

func pauseClicking():
	menuReady = false
	fullBtnCanPress = false
	muteBtnCanPress = false
	contBtnCanPress = false
	var timer = Timer.new()
	timer.set_wait_time(.05)
	timer.set_one_shot(true)
	if not timer.get_parent():
		add_child(timer)
	timer.start()
	yield(timer, "timeout")
	timer.queue_free()
	menuReady = true
	contBtnCanPress = true
	muteBtnCanPress = true
	fullBtnCanPress = true


func _input(event):
	pass


var contBtnCanPress = true
func _on_useController_pressed():
	if contBtnCanPress:
		print("use controller? " + str(main.useController))
		if main.useController:
			main.useController = false
		else:
			main.useController = true
		if get_node("cont1/Control/useController").text != "Keyboard & Mouse" and not main.useController:
			get_node("cont1/Control/useController").text = "Keyboard & Mouse"
		elif get_node("cont1/Control/useController").text != "Gamepad" and main.useController:
			get_node("cont1/Control/useController").text = "Gamepad" 
		else:
			get_node("cont1/Control/useController").text = "Set Controls"
		if main.controllerCursorObj:
			if not main.useController:
				main.controllerCursorObj.visible = false
			else:
				main.controllerCursorObj.visible = true


func _on_vol_down_pressed():
	print("volume is " + str(btnvol))
	if btnvol < -100:
		btnvol = -100
	else:
		btnvol -= 2
	changeMasterVolume(btnvol)


func _on_vol_up_pressed():
	print("volume is " + str(btnvol))
	if btnvol > 94:
		btnvol = 94
	else:
		btnvol += 2
	changeMasterVolume(btnvol)


func _on_Fullscreen_mouse_entered():
	pass # replace with function body


func _on_Fullscreen_focus_entered():
	pass # replace with function body


func _on_Fullscreen_focus_exited():
	pass # replace with function body


func _on_Fullscreen_mouse_exited():
	pass # replace with function body


func _on_keepResolutionChanges_focus_entered():
	pass # replace with function body


func _on_keepResolutionChanges_focus_exited():
	pass # replace with function body


func _on_keepResolutionChanges_mouse_entered():
	pass # replace with function body


func _on_keepResolutionChanges_mouse_exited():
	pass # replace with function body


func _on_MuteButton_focus_entered():
	pass # replace with function body


func _on_MuteButton_focus_exited():
	pass # replace with function body


func _on_MuteButton_mouse_entered():
	pass # replace with function body


func _on_MuteButton_mouse_exited():
	pass # replace with function body


func _on_vol_down_focus_entered():
	pass # replace with function body


func _on_vol_down_focus_exited():
	pass # replace with function body


func _on_vol_down_mouse_entered():
	pass # replace with function body


func _on_vol_down_mouse_exited():
	pass # replace with function body


func _on_vol_up_focus_entered():
	pass # replace with function body


func _on_vol_up_focus_exited():
	pass # replace with function body


func _on_vol_up_mouse_entered():
	pass # replace with function body


func _on_vol_up_mouse_exited():
	pass # replace with function body


func _on_Button_focus_entered():
	pass # replace with function body


func _on_Button_focus_exited():
	pass # replace with function body


func _on_Button_mouse_entered():
	pass # replace with function body


func _on_Button_mouse_exited():
	pass # replace with function body


func _on_useController_focus_entered():
	pass # replace with function body


func _on_useController_focus_exited():
	pass # replace with function body


func _on_useController_mouse_entered():
	pass # replace with function body


func _on_useController_mouse_exited():
	pass # replace with function body
