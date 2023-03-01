extends GameGlobal

#class_name GlobalProgression

##############################################################################
#
# GlobalProgression is a singleton for the runtime scaffold that manages game
# data being tracked across play sessions.
# Additionally GlobalProgression handles calls to exit the game as this has
# to account for file closing.

#//TODO
# add write save method with optional arg to unload the save file if doing so
# move quit game behaviour to here, so files can be safely saved on exit
# add autosave timer and method to adjust interval (integrate w/globalConfig)
# enable/disable playtime tracker during runtime
# enable/disable save icon canvas during runtime

##############################################################################

#05. signals
# signal emitted whenever the all_game_files array is updated after a new
# globalProgressFile is recorded
signal new_game_file_recorded()

#06. enums
#
#07. constants
# for passing to error logging
const SCRIPT_NAME := "GlobalProgression"
# for developer use, enable if making changes
# verbose_logging exists in a parent class
#const VERBOSE_LOGGING := true

# optional flags for developer to change behaviour of the game file manager

# dev can flip this if they don't want to use the game file manager for some
# reason (for instance, it was automatically included in a different package
# they downloaded and it doesn't meet their needs). If set false the game
# file manager will ignore calls to key behaviour such as creating game files.
const OPTION_ENABLE_GAME_FILE_MANAGER := true

# if set shows an animated saving icon in corner of screen
const OPTION_SHOW_SAVE_ICON_CANVAS := true

# if set, and the GameProgressFile has the property 'total_playtime', the
# globalProgression singleton will auto-instantiate a timer node and use it
# to update the second count value of the total playtime property.
const OPTION_TRACK_TOTAL_PLAY_TIME := true

# The time (in minutes) between attempting a save regardless of what the game
# is doing. Can disable by setting to a nil or negative value.
const OPTION_AUTOSAVE_INTERVAL := 15.0

# the total number of save files that can be recorded in the user data folder
# acts as a break in iterator for create_game_file method
const OPTION_MAXIMUM_SAVE_FILES := 100

const SAVE_ICON_CANVAS_SCENE_PATH :=\
		"res://src/file_manager/save_canvas/canvas_save_notification.tscn"

# packed scene for instancing, and reference to the save canvas
var save_icon_canvas_scene := preload(SAVE_ICON_CANVAS_SCENE_PATH)
var save_in_progress_canvas_node: CanvasLayer

# reference to the play time tracker timer node
var total_play_time_tracker_node: Timer
# reference to the autosave timer node
var autosave_timer_node: Timer

#
#08. exported variables
#09. public variables

# used to create save file elements inside gameMeta.gameFileDialog
var all_game_files := []

# the active save file loaded
# should be unloaded when game meta transitions out
# warning-ignore:unused_class_variable
var loaded_save_file: GameProgressFile setget _set_loaded_save_file

#10. private variables
#11. onready variables

##############################################################################

# setget

# start the playtime tracker if it has been instantiated
func _set_loaded_save_file(arg_value):
	loaded_save_file = arg_value
	if total_play_time_tracker_node != null:
		total_play_time_tracker_node.stop()
		if loaded_save_file != null:
			total_play_time_tracker_node.start()


##############################################################################

# virt

func _ready():
	if OPTION_SHOW_SAVE_ICON_CANVAS:
		_initiate_save_icon_canvas()
	if OPTION_TRACK_TOTAL_PLAY_TIME:
		_initiate_playtime_tracking_timer()
	if OPTION_AUTOSAVE_INTERVAL >= 0:
		_initiate_autosave_timer()


##############################################################################

# public


# method that instantiates save files
# returns the created file on success or null on failure
func create_game_file():
	# called with incorrect dev option flag set
	if not OPTION_ENABLE_GAME_FILE_MANAGER:
		GlobalDebug.log_error(SCRIPT_NAME, "create_game_file",
				"create game file called whilst game file manager disabled")
		return
	
	var new_save_file = GameProgressFile.new()
	
	# get the save path
	var save_id := 1
	var does_save_id_exist := true
	var base_save_path =\
			GlobalData.DATA_PATHS[GlobalData.DATA_PATH_PREFIXES.GAME_SAVE]
	var save_file_name = "save"+str(save_id)+".tres"
	# save files are recorded as 'save' with an integer id, i.e. 'save1'
	# until an unused save id is found, iterate through potential save ids
	# will only iterate up to maximum save file value
	while does_save_id_exist == true\
	and save_id <= OPTION_MAXIMUM_SAVE_FILES:
		does_save_id_exist = GlobalData.validate_file(\
				base_save_path+save_file_name)
		# if already exists, increment the id and attempted path
		if does_save_id_exist == true:
			save_id += 1
			save_file_name = "save"+str(save_id)+".tres"
	
	# store the file path
	new_save_file.directory_path = base_save_path
	new_save_file.file_name = save_file_name
	
	# this statement==true (path will not exist) if the above loop exits
	# successfully; this catches exceptions such as maximum save id exceeded
	if does_save_id_exist == false:
		if GlobalData.save_resource(\
				base_save_path, save_file_name, new_save_file) == OK:
			# if save operation successful, update record of saves
			all_game_files.append(new_save_file)
			emit_signal("new_game_file_recorded")
#			print("save recorded at {p}".format({"p": save_file_name}))
			return new_save_file
	
	# catchall exit condition, assumes failure
	return null


# call this to save the player's game
func save_active_game_file():
	if loaded_save_file != null:
		show_save_in_progress_icon(true)
		# update the file modified timestamp
		loaded_save_file.timestamp_modified =\
				Time.get_datetime_dict_from_system()
		var active_game_file_directory = loaded_save_file.directory_path
		var active_game_file_name = loaded_save_file.file_name
		# write file to its own address
		# force write file/directory = true & true
		# increment backup = true
		if GlobalData.save_resource(\
				active_game_file_directory,
				active_game_file_name,
				loaded_save_file,
				true,
				true,
				true) == OK:
			GlobalDebug.log_success(verbose_logging, SCRIPT_NAME,
					"save_active_game_file",
					"succesfully wrote file at {p}".format({
						"p": active_game_file_directory+active_game_file_name
					}))
		show_save_in_progress_icon(false)


func show_save_in_progress_icon(arg_enable_icon: bool = true):
	if OPTION_SHOW_SAVE_ICON_CANVAS\
	and save_in_progress_canvas_node != null:
		if save_in_progress_canvas_node.has_method("show_icon"):
			save_in_progress_canvas_node.show_icon(arg_enable_icon)


##############################################################################

# private


func _initiate_save_icon_canvas():
	# called with incorrect dev option flag set
	if not OPTION_SHOW_SAVE_ICON_CANVAS:
		GlobalDebug.log_error(SCRIPT_NAME, "_initiate_save_icon_canvas",
				"_initiate_saving_canvas called whilst"+
				" option_show_save_in_progress_canvas isn't set")
		return
	# set up the save icon canvas
	save_in_progress_canvas_node = save_icon_canvas_scene.instance()
	self.call_deferred("add_child", save_in_progress_canvas_node)
	yield(save_in_progress_canvas_node, "ready")
	save_in_progress_canvas_node.show_icon(false)


# creates the playtime tracker if flag is enabled
func _initiate_playtime_tracking_timer():
	# called with incorrect dev option flag set
	if not OPTION_TRACK_TOTAL_PLAY_TIME:
		GlobalDebug.log_error(SCRIPT_NAME, "_initiate_playtime_tracking_timer",
				"_initiate_playtime_tracker called whilst"+
				" option_track_total_play_time isn't set")
		return
	# set up the playtime tracker
	total_play_time_tracker_node = Timer.new()
	self.call_deferred("add_child", total_play_time_tracker_node)
	total_play_time_tracker_node.autostart = false
	total_play_time_tracker_node.one_shot = false
	if total_play_time_tracker_node.connect(\
			"timeout", self, "_on_timeout_gain_playtime") != OK:
		GlobalDebug.log_error(SCRIPT_NAME, "_initiate_playtime_tracker",
				"total playtime tracker not setup correctly")


func _initiate_autosave_timer():
	# called with incorrect dev option flag set
	if not OPTION_AUTOSAVE_INTERVAL >= 0:
		GlobalDebug.log_error(SCRIPT_NAME, "_initiate_autosave_timer",
				"_initiate_autosave_timer called whilst"+
				" option_autosave_interval is nil or negative")
		return
	# set up the autosave timer
	autosave_timer_node = Timer.new()
	self.call_deferred("add_child", autosave_timer_node)
	autosave_timer_node.autostart = true
	autosave_timer_node.one_shot = false
	# convert minutes to seconds
	autosave_timer_node.wait_time = float(OPTION_AUTOSAVE_INTERVAL*60)
	if autosave_timer_node.connect(\
			"timeout", self, "save_active_game_file") != OK:
		GlobalDebug.log_error(SCRIPT_NAME, "_initiate_autosave_timer",
				"autosave timer not setup correctly")


# shadowing a parent class method
# this preload method loads from disk every save file it can find in the
# user://saves/ folder, looking for files named save1.tres, save2.tres, etc.
# successfully loaded files are added to the _all_game_files array to later
# be used by the gameFileDialog scene (part of the gameMeta state)
func _preload():
#	._preload()
	# path to save location
	var get_save_path: String =\
			GlobalData.DATA_PATHS[GlobalData.DATA_PATH_PREFIXES.GAME_SAVE]

	var game_saves = []
	# collect all the actual save files
	# args = file names must begin with 'save' and not include 'backup'
	game_saves = GlobalData.load_resources_in_directory(
		get_save_path,
		"save",
		"",
		["backup"]
	)
	all_game_files.append_array(game_saves)


##############################################################################

# on signal receipt


# called by the play time tracker on timeout signal
func _on_timeout_gain_playtime():
	if loaded_save_file != null:
		if "total_playtime" in loaded_save_file:
			loaded_save_file.total_playtime += 1


##############################################################################

