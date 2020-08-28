"""
Class: Layout
	Formats a Log Event for an Appender.
"""
extends Reference
class_name Layout

func getHeader():
	return ""


func getFooter():
	return ""


func build(message: Message, format: int):
	return message


func _init():
	pass
