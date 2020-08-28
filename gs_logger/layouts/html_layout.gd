"""
Class: HtmlLayout
	Generates an HTML Page and adds each Log Event
	to a Row in a Table.
"""

extends Layout
class_name HtmlLayout

var contextual_classes = \
	{
		Logger.LOG_LEVEL_ALL: 	"",
		Logger.LOG_LEVEL_FINE: 	"",
		Logger.LOG_LEVEL_TRACE: "",
		Logger.LOG_LEVEL_INFO: 	"info",
		Logger.LOG_LEVEL_FATAL: "danger",
		Logger.LOG_LEVEL_WARN: 	"warning",
		Logger.LOG_LEVEL_ERROR: "danger",
		Logger.LOG_LEVEL_DEBUG: "",
		Logger.LOG_LEVEL_NONE: 	"",
	}

var header = \
"""
<html>
<head>
<title>Message Log</title>
<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css">
<script src="https://ajax.googleapis.com/ajax/libs/jquery/3.3.1/jquery.min.js"></script>
<script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js"></script>
</head>
<body>
<div class="container">
<h2>Godot Logger</h2>
<table class="table table-condensed table-hover">
<thead>
<th>Number</th>
<th>Message</th>
</thead>
"""


var footer = \
"""
</table>
</body>
</html>
"""

func getHeader():
	return header


func getFooter():
	return "</body>"


func build(message: Message, format: int):
	return '<tr class="%s"><td style="width:100px"><span class="glyphicon glyphicon-edit" style="padding-right:10px"></span><span>%d</span></td><td>%s</td></tr>' % [contextual_classes[message.level], message.line, message.text]


