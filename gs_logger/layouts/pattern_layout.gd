
"""
Class: PatternLayout
	A Flexible Layout with a Pattern String.
"""
extends Layout
class_name PatternLayout

func build(message: Message, format: int):

	match format:

		Logger.LOG_FORMAT_DEFAULT:
			return "%-10s %-8d %s" % [Logger.get_level_name(message.level), message.line, message.text]
		Logger.LOG_FORMAT_FULL:
			return "%s %-8s %-8s %-8d %s" % [Logger.get_formatted_date(OS.get_datetime()), message.category.to_upper(), Logger.get_level_name(message.level), message.line, message.text]
		Logger.LOG_FORMAT_MORE:
			return "%s %-8s %-8d %s" % [Logger.get_formatted_date(OS.get_datetime()), Logger.get_level_name(message.level), message.line, message.text]
		Logger.LOG_FORMAT_NONE:
			return message.text
		Logger.LOG_FORMAT_SIMPLE:
			return "%-8d %s" % [message.line, message.text]
		_:
			return "%-8s %s" % [Logger.get_formatted_date(OS.get_datetime()), message.text]


	"""
	var msg = ""

	match format:
		LogFormats.FULL:
			msg = "%s %-8s %-8s %-8d %s" % [_get_formatted_date(OS.get_datetime()), category.to_upper(), _get_level_name(level), logger_line, message]
		LogFormats.MORE:
			msg = "%-8s %-8s %-8d %s" % [_get_formatted_date(OS.get_datetime()), category.to_upper(), _get_level_name(level), logger_line, message]
		LogFormats.DEFAULT:
			msg = "%-10s %-8d %s" % [_get_level_name(level), logger_line, message]
		LogFormats.SIMPLE:
			msg = "%-8d %s" % [logger_line, message]
		_:
			msg = "%s" % [message]
	"""



