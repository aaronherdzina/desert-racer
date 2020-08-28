extends Area2D
var velocity = Vector2()

var currentSpeed = 3.8
var playSpeed = 3.8
var menuSpeed = 10
var slowDownSpeed = 1

var pressing = false
var moveLeft = false
var moveRight = false
var moveUp = false
var moveDown = false
var defaultClampDist = 75
var currentClampDist = 75
var canPress = true
var dynamicCursorFollow = true
var nodeToClampAround = null
var lockToMouse = true

func _ready():
	set_process(true)

func clamp_vector(vector, clamp_origin, clamp_length):
    var offset = vector - clamp_origin
    var offset_length = offset.length()
    if offset_length <= clamp_length:
        return vector
    return clamp_origin + offset * (clamp_length / offset_length)

func _process(delta):
	translate(velocity * delta)
	#if main.canClick(["confirmMenuOption", "Options"]):
	#	pass
	lockCursor()
	moveCursor()
	if main.useController and not visible:
		visible = true

func lockCursor():
	# check for node to pivot around, ensure it exists use mouse. Keep the check light unless desired
	if nodeToClampAround == null or dynamicCursorFollow and checkIfNodeDeleted(nodeToClampAround):
		if lockToMouse and currentClampDist != 0:
			currentClampDist = 0
		elif not lockToMouse and currentClampDist != defaultClampDist:
			currentClampDist = defaultClampDist
		position = clamp_vector(position, Vector2(get_global_mouse_position().x, get_global_mouse_position().y), currentClampDist) #position.y = clamp(self.position.y,  main.plane.position.y - 50,  main.plane.position.y + 250)
	else:
		position = clamp_vector(position, Vector2(nodeToClampAround.position.x, nodeToClampAround.position.y), currentClampDist) #position.y = clamp(self.position.y,  main.plane.position.y - 50,  main.plane.position.y + 250)


func moveCursor():
	# change cursor move speed based on playing, in menu and if we want to slowdown
	if slowDownOverBtn(currentSpeed):
		if slowDownOverBtn(slowDownSpeed) and currentSpeed != slowDownSpeed:
			currentSpeed = slowDownSpeed
		elif currentSpeed != playSpeed:
			currentSpeed = playSpeed
	elif currentSpeed != menuSpeed:
			currentSpeed = menuSpeed
	if moveUp:
		position.y -= currentSpeed
	elif moveDown:
		position.y += currentSpeed
	
	if moveLeft:
		position.x -= currentSpeed
	elif moveRight:
		position.x += currentSpeed

func _input(event):
	if Input.is_action_pressed("analog_cursor_up"):
		moveUp = true
		moveDown = false
	elif Input.is_action_pressed("analog_cursor_down"):
		moveUp = false
		moveDown = true
	else:
		moveDown = false
		moveUp = false

	if Input.is_action_pressed("analog_cursor_left"):
		moveLeft = true
		moveRight = false
	elif Input.is_action_pressed("analog_cursor_right"):
		moveLeft = false
		moveRight = true
	else:
		moveLeft = false
		moveRight = false
	
	if event.is_action_released("ui_controller_focus_press") and canPress:
		pauseClicking()
		findAndPressButtonOfNode()

func findAndPressButtonOfNode():
	for nodes in get_overlapping_areas():
		if nodes is Button or nodes is MenuButton:
			nodes.emit_signal("pressed")
			return
		else:
			var nodeParent = nodes.get_parent()
			if nodeParent is Button or nodeParent is MenuButton:
				nodeParent.emit_signal("pressed")
				return
			else:
				var nodeGrandParent = nodes.get_parent().get_parent()
				if nodeGrandParent is Button or nodeGrandParent is MenuButton:
					nodeGrandParent.emit_signal("pressed")
					return

func slowDownOverBtn(desiredSpeed):
	if len(get_overlapping_areas()) > 0 and currentSpeed != desiredSpeed:
		return true
	return false

func pauseClicking():
	canPress = false
	var timer = Timer.new()
	timer.set_wait_time(.4)
	timer.set_one_shot(true)
	if not timer.get_parent():
		add_child(timer)
	timer.start()
	yield(timer, "timeout")
	timer.queue_free()
	canPress = true
	

func _on_controllerCursor_area_entered(other):
	var checkSelf = other
	if checkSelf is Button or checkSelf is MenuButton:
		checkSelf.grab_focus()
		checkSelf.set_focus_mode(1)
		checkSelf.grab_focus()
	else:
		if checkSelf.get_parent():
			var checkParent = checkSelf.get_parent()
			if checkParent is Button or checkParent is MenuButton:
				checkParent.grab_focus()
				checkParent.set_focus_mode(1)
				checkParent.grab_focus()
		
