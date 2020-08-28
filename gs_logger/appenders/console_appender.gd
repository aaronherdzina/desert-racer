
"""
Class: ConsoleAppender
	Logs an Event to the Console Window.
"""

extends Appender
class_name ConsoleAppender

func append(message: Message):
	print(layout.build(message, logger_format))


func append_raw(text: String):
	print(text)


func _init():
	name = "console appender"
	print("** Console Appender Initialized **")
	print(" ")
