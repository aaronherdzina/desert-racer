extends Node2D

var can_collide = false
var has_object = false
var has_player = false
var has_projectile = false
var hazard = false
var strict_immovable = false
var strict_hazard = false
var movable = true
var has_enemy = false
var index = 0
var col = 0
var row = 0
var hold_z_idx = 0
var texture_can_reset = true
var going_from_no_move_to_obj = false

var has_two_enms = false
var has_two_objs = false
var has_two_projs = false

var had_obj = false
var had_proj = false
var had_enm = false
var had_player = false
var player_in_air = false
var player_can_crash = true
var player_can_be_shot = true
var player_can_be_hurt = true
var player_invincible = false
var previous_obstacle_dir = ''

var player_str = ''
var proj_str = ''
var enm_str = ''
var obj_str = ''


var finish = false # if player is here level over

func _ready():
	set_process(false)

func _process(delta):
	pass

# 13 67 93
