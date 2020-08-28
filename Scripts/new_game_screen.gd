extends Node2D

var hold_unique_cards = []
var card_idx = 0
var card_x_buff = 220
var card_scale = Vector2(.3, .3)

func _ready():
	show_char_details()

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass


func load_unique_cards():
	main.clear_array(hold_unique_cards)
	var count = 0
	for c in meta.char_list[meta.char_idx].unique_cards:
		count += 1
		var uc = main.instancer(c)
		hold_unique_cards.append(uc)
		uc.position = get_node("card po 0").global_position
		uc.position.x += count * card_x_buff
		uc.add_to_group("remove_on_game_start")
		uc.set_scale(card_scale)
		uc.z_index = 500


func show_char_details():
	var char_ref = meta.char_list[meta.char_idx]
	var text_ref = $text/Control
	if char_ref.character == 'SLICK':
		$cart_sprites/AnimationPlayer.play("slick")
	elif char_ref.character == 'TECH':
		$cart_sprites/AnimationPlayer.play("tech anim")
	elif char_ref.character == 'RAVEN':
		$cart_sprites/AnimationPlayer.play("raven")
	elif char_ref.character == 'DOZEN':
		$cart_sprites/AnimationPlayer.play("dozer")
	text_ref.get_node("char name").set_text(char_ref.character)
	text_ref.get_node("Hand_size").set_text('Card Hand Size: ' + str(char_ref.hand_limit + 1))
	text_ref.get_node("min_speed").set_text('Minimum Speed: ' + str(char_ref.step_min))
	text_ref.get_node("stability").set_text('Stability: ' + str(char_ref.stability_max))
	var bonus_text = ''
	if char_ref.move_distance_mod > 0:
		bonus_text += 'Move Cards +' + str(char_ref.move_distance_mod) + ' distance'
	if char_ref.speed_mod > 0:
		bonus_text += '\nSpeed Cards +' + str(char_ref.speed_mod) + ' speed change'
	elif char_ref.air_time_bonus > 0:
		bonus_text += '\nJump Cards +' + str(char_ref.air_time_bonus) + ' round air time'
	elif char_ref.invincible_time_bonus > 0: # additional steps for invincible cards
		bonus_text += '\nInvincible Cards +' + str(char_ref.invincible_time_bonus) + ' length'
	elif char_ref.dig_bonus > 0:
		bonus_text += '\nDig Cards +' + str(char_ref.dig_bonus) + ' dig distance'
	if bonus_text != '':
		text_ref.get_node("bonus 1").visible = true
		text_ref.get_node("bonus 1").set_text(bonus_text)
	else:
		text_ref.get_node("bonus 1").visible = false
	load_unique_cards()

