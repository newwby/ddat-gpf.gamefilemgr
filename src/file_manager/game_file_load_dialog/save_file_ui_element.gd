extends MarginContainer

class_name SaveFileElement

##############################################################################
#
# SaveFileElement is an interface container displaying the properties of a
# game progress file object.
#
#// TODO
#// add logging to error states
#// fix the label init called too early bug (workaround is the process loop
#	implementation currently in, not sure it is best practice)
#	(potential fix -- use an instanced scene instead of a default duplicate)
#// review whether file info element class is necessary
#
##############################################################################

signal save_file_chosen()
signal delete_button_pressed(ref_self)

const SAVE_BUTTON_NODE_LABEL := "SAVE FILE "

const SCRIPT_NAME := "SaveFileElement"
# for developer use, enable if making changes
const VERBOSE_LOGGING := true

# the progress file assigned to this save file element
# the save file element will do nothing if there is no progress file
# warning-ignore:unused_class_variable
var my_progress_file: GlobalProgression.GAME_SAVE_CLASS\
		setget _set_my_progress_file

# for save button label
var my_save_label_id := 0
var is_my_save_label_set := false

# temporary solution since label init in save file element setup being called
# too early and the default node ref is null when it is called
var labels_to_build := []

# node references
#onready var save_button_node = get_node_or_null("LoadSaveButton")

# node references for file info root and default (to duplicate from) node
onready var file_info_root_node: VBoxContainer =\
		$VBox/HBox/FileInfoContainer
onready var file_info_default_node: HBoxContainer =\
		$VBox/HBox/FileInfoContainer/FileInfo
#		get_node_or_null("FileInfoContainer/FileInfo")
# node references for buttons
onready var load_save_button_node: Button = $VBox/HBox/LoadSaveButton
onready var delete_save_button_node: Button = $VBox/HBox/DeleteSaveButton

##############################################################################

# standalone sub-class

# organising file info elements for simpler verificaiton
class FileInfoElement:
	var _intended_key_label_text: String = ""
	var _intended_value_label_text: String = ""
	
	func _init(key_text: String, value_text: String):
		self._intended_key_label_text = key_text
		self._intended_value_label_text = value_text
#		print(self, " key text = ", key_text)
	
	func get_key_label():
		return _intended_key_label_text+":"
	
	func get_value_label():
		return _intended_value_label_text


##############################################################################

# setters and getters


func _set_my_progress_file(value: GlobalProgression.GAME_SAVE_CLASS):
	my_progress_file = value
	if my_progress_file != null:
		_build_file_info_elements()


##############################################################################

# virtual methods


# Called when the node enters the scene tree for the first time.
func _ready():
	# only show this save file element if it is valid
	if my_progress_file == null:
		self.visible = false


# temp label building solution (see 'labels_to_build' commenting)
# instead of doing it on demand we wait until the default node is ready
# and call it in process
func _process(_delta):
	if not labels_to_build.empty()\
	and file_info_default_node != null:
		var new_file_info_element  = labels_to_build.pop_front()
		if new_file_info_element is FileInfoElement:
			_add_file_info_element(
					new_file_info_element.get_key_label(),
					new_file_info_element.get_value_label()
			)
	if is_my_save_label_set == false\
	and load_save_button_node != null:
		load_save_button_node.text = SAVE_BUTTON_NODE_LABEL+str(my_save_label_id)
		is_my_save_label_set = true



##############################################################################

# public


# try not to call this method until the save file ui element is in the tree
# when ready to use this save file element, initialise it with this method
##param1 is the save file to load
func init_save_file_element(
		arg_progfile: GlobalProgression.GAME_SAVE_CLASS,
		arg_save_id: int):
	my_save_label_id = arg_save_id
	self.my_progress_file = arg_progfile
	self.visible = true
#	if arg_progfile != null:
#		_build_file_info_elements()


func disable_buttons(is_disabled: bool = true):
	if load_save_button_node != null:
		load_save_button_node.disabled = is_disabled
	if delete_save_button_node != null:
		delete_save_button_node.disabled = is_disabled


##############################################################################

# priv


# this method creates and structures fileInfo label pairs based on the progress
# file property 'save_file_element_info'.
func _build_file_info_elements():
	# get the property from the progress file, validate that it's a dict then
	# pull the key/value pair from the dict to create a new file info element
	if "save_file_element_info" in my_progress_file:
		# get property
		var save_info = my_progress_file.save_file_element_info
		# validate property then loop through
		if typeof(save_info) == TYPE_DICTIONARY:
			for info_point in save_info:
				# whilst looping add file info elements as long as relevant
				# give dict key to key label, dict value to value label
				# due to temp label solution add to array
				# (see 'labels_to_build' var commenting)
				var new_file_info_element = FileInfoElement.new(
						str(info_point),
						str(save_info[info_point])
						)
				labels_to_build.append(new_file_info_element)
#				_add_file_info_element(
#					str(info_point),
#					str(save_info[info_point])
#				)


# file info labels will be set to param strings if valid
func _add_file_info_element(key_text: String, value_text: String):
	if file_info_default_node == null:
		print("error didn't find fiInDefault")
		return
	var new_file_info = file_info_default_node.duplicate()
	# validate successful
	if new_file_info is HBoxContainer:
		var key_label_node = new_file_info.get_node_or_null("Key")
		var val_label_node = new_file_info.get_node_or_null("Value")
		# set label texts
		if key_label_node is Label:
			key_label_node.text = key_text
		if val_label_node is Label:
			val_label_node.text = value_text
		# then add to the root holder node and show the new file info
		file_info_root_node.call_deferred("add_child", new_file_info)
		new_file_info.visible = true


# when confirmation button is clicked
func _on_load_save_button_pressed():
	if my_progress_file != null:
		GlobalProgression.loaded_save_file = my_progress_file
		emit_signal("save_file_chosen")
	else:
		GlobalDebug.log_error(SCRIPT_NAME, "_on_load_save_button_pressed",
				"null progress file attached to clicked save file ui element")


# method to delete a game save
# is actually handled by gameMeta.FileLoadDialog, the expected parent
func _on_delete_save_button_pressed():
	# pass a reference to self back
	emit_signal("delete_button_pressed", self)
