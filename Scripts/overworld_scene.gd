extends Node2D

var velocity = Vector2(0, 0)
var speed = 500
func _ready():
	set_process(true)


func _process(delta):
	move_scene_node(delta)


func move_scene_node(delta):
	if 'overworld' in main.current_menu and 'Node' in str(main.menu_list[main.menu_idx]):
		var move_to_tile = main.menu_list[main.menu_idx]
		if (move_to_tile.global_position - get_node("player_body").global_position).length() > 5:
			velocity = (move_to_tile.global_position -\
						get_node("player_body").global_position).normalized() * speed
			get_node("player_body").move_and_collide(velocity * delta)
	
	#	get_node("player_body/Sprite").look_at(move_to_tile.global_position.normalized())
