extends Resource

class_name GameProgressFile

##############################################################################
#
# Template game file for saving game progress.
# Developers should extend this class to include information about their
# game that needs to be recorded so that in the next game instance it can
# be loaded again.
#
# DEPENDENCIES:
# DDAT_Prototyping_Framework.DDAT_Core
# DDAT_Prototyping_Framework.DDAT_Runtime
#
# DEV WARNING: Do not change the file path address of this class file after
# saving resources to disk under this class, else you will incur a
# referenced nonexistent resource error (unless you wish to manually edit the
# [ext_resource=] path on each .tres file.
#
##############################################################################

# warning-ignore:unused_class_variable
#var game_file_creation_date

export var total_playtime := 0 setget _set_total_playtime

#//TODO, store the timezone when creating file and reference it whenever
# changing the modified date so created date/modified date can be adjusted
#export var file_timezone: Dictionary

# track of date and time file was created on
export var timestamp_created: Dictionary setget _set_timestamp_created
# when file was last opened or saved
export var timestamp_modified: Dictionary setget _set_timestamp_modified

# directory path of where the progress file is saved on disk
export var directory_path: String
# file name the progress file is saved under
export var file_name: String
# //DEPRECATED, can be gotten with the above two variables instead
## full path of where the progress file is saved on disk
#export var file_path: String

# the key/value pairs of this dict are shown on the save file element when
# loading/saving the game. Both the key and value are displayed on the file
# info, so use readable strings when adding new key/value pairs.
# You can use setters on other properties to automatically update this db.
# warning-ignore:unused_class_variable
export var save_file_element_info = {
	"Total Playtime" : "0 hours, 0 minutes, 0 seconds",
	"File Created On" : "14th January 2023",
	"Last Played" : "14th January 2023",
}

##############################################################################

# setters and getters


# when updating total playtime value, set the corresponding dict value
func _set_total_playtime(arg_value: int):
	total_playtime = arg_value
	save_file_element_info["Total Playtime"] =\
			_convert_seconds_to_time_string(total_playtime)


func _set_timestamp_created(arg_value: Dictionary):
	timestamp_created = arg_value
	save_file_element_info["File Created On"] =\
			_convert_datetime_dict_to_save_info(timestamp_created)


func _set_timestamp_modified(arg_value: Dictionary):
	timestamp_modified = arg_value
	save_file_element_info["Last Played"] =\
			_convert_datetime_dict_to_save_info(timestamp_modified)


# when reading the total playtime value it returns a formatted string instead
func _convert_seconds_to_time_string(arg_seconds: int):
	var playtime_seconds: int = arg_seconds
	var playtime_minutes: int = 0
	var playtime_hours: int = 0
	
	while playtime_seconds >= 60:
		playtime_seconds -= 60
		playtime_minutes += 1
	
	while playtime_minutes >= 60:
		playtime_minutes -= 60
		playtime_hours += 1
	
	var time_string: String = "{h} hours, {m} minutes, {s} seconds".format({
		"h": playtime_hours,
		"m": playtime_minutes,
		"s": playtime_seconds
	})
	return time_string


func _convert_datetime_dict_to_save_info(datetime_dict: Dictionary) -> String:
	# full string to write
	var file_datetime_info = ""
	# pieces to build full string from
	var file_date_day = ""
	var file_date_month = ""
	var file_date_year = ""
	var file_time_hour := ""
	var file_time_minute := ""
	var file_time_second := ""
	
	if "day" in datetime_dict.keys():
		file_date_day = str(datetime_dict["day"])
		# get last digit to determine the suffix
		var day_suffix = ""
		var last_digit = str(file_date_day)[-1]
		if last_digit == "3":
			day_suffix = "rd"
		elif last_digit == "2":
			day_suffix = "nd"
		elif last_digit == "1":
			day_suffix = "st"
		else:
			day_suffix = "th"
		file_date_day += day_suffix
	
	if "month" in datetime_dict.keys():
		file_date_month = datetime_dict["month"]
		if typeof(file_date_month) == TYPE_INT:
			if file_date_month in range(1, 12):
				match file_date_month:
					1:
						file_date_month = "January"
					2:
						file_date_month = "February"
					3:
						file_date_month = "March"
					4:
						file_date_month = "April"
					5:
						file_date_month = "May"
					6:
						file_date_month = "June"
					7:
						file_date_month = "July"
					8:
						file_date_month = "August"
					9:
						file_date_month = "September"
					10:
						file_date_month = "October"
					11:
						file_date_month = "November"
					12:
						file_date_month = "December"
	
	if "year" in datetime_dict.keys():
		file_date_year = str(datetime_dict["year"])
	
#	//TODO convert to 24 hour?
	if "hour" in datetime_dict.keys():
		file_time_hour = str(datetime_dict["hour"])
		if file_time_hour.length() == 1:
			file_time_hour = "0"+file_time_hour
	
	if "minute" in datetime_dict.keys():
		file_time_minute = str(datetime_dict["minute"])
		if file_time_minute.length() == 1:
			file_time_minute = "0"+file_time_minute
	
	if "second" in datetime_dict.keys():
		file_time_second = str(datetime_dict["second"])
		if file_time_second.length() == 1:
			file_time_second = "0"+file_time_second
	
	# type convert to catch exceptions (may now be redundant)
	file_datetime_info =\
			str(file_date_day)+" "+\
			str(file_date_month)+" "+\
			str(file_date_year)+", "+\
			str(file_time_hour)+":"+\
			str(file_time_minute)+":"+\
			str(file_time_second)
	
	return file_datetime_info


##############################################################################

# virt


func _init():
#	file_timezone = Time.get_time_zone_from_system()
#	Time.get_offset_string_from_offset_minutes()
	self.timestamp_created = Time.get_datetime_dict_from_system()
	self.timestamp_modified = timestamp_created


##############################################################################

# public

#//REMOVED
## because the getter interferes with setting it externally
#func increment_playtime(arg_increment: int):
#	total_playtime += arg_increment
#	print(total_playtime)
#	print(save_file_element_info["Total Playtime"])


# method to recieve data
#func load_game():
#	pass


# method to commit data
#func save_game():
#	pass


##############################################################################

##

