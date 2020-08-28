tool
extends Sprite

func findAspectRatio():
	material.set_shader_param("aspect_ratio", scale.y / scale.x)