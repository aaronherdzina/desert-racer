
"""
Class: Message
	Simple representation of a Message to Append to a Logger

Remarks:
	A Layout will Format a message before it is sent to
	its assigned Appender.

"""
extends Reference
class_name Message

var level: int
var text: String
var category: String
var line: int
var data


func _init(level=000, text="", category="general", line=0, data={}):
	self.level = level
	self.text = text
	self.category = category
	self.line = line
	self.data = data
