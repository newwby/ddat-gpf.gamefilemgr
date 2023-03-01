extends Control

#class_name DevDebugOverlay

##############################################################################

# DevDebugOverlay.gd is a script for the scene/node of the same name,
# which manages the presentation of debug information during gameplay.

# DEPENDENCY: GlobalDebug

# 
# HOW TO USE
# Call public method to add or update a debug value
# If the key for the update is found, DevDebugOverlay will push an update to
# the matching debug item container, changing the value as appropriate.
# If the key is not found, DevDebugOverlay will create a new debug item
# container and add its value.

# TODO
#// finish test scene/project
#// add an open source font to ddat core, preferably a KenneyNL font
#// add Public Function to update debug values
#// hide default item container on init
#// default show on debugBuild
#// add button to show/hide on press
#// add secondary confirmation on release builds, or toggle to disable (rw style)
#// add support for debug values that hide over time after no updates
#// add support for renaming debug keys
#// add developer support for setting margin
#// add support for text colour

# POTENTIAL BUGS
#// what happens if multiple sources try to update a new key? will more than
# one debugItemContainer be created? what happens to the reference of the last?

##############################################################################

# for passing to error logging
const SCRIPT_NAME := "dev_debug_overlay"
# for developer use, enable if making changes
const VERBOSE_LOGGING := true

# for standardising the an item container's key or value label name
# useful for validating and/or fetching the correct node
const NODE_NAME_DEBUG_ITEM_LABEL_KEY := "Key"
const NODE_NAME_DEBUG_ITEM_LABEL_VALUE := "Value"
# for assigning the value label from newly duplicated item containers to a
# group, so that minimum size can be dynamically adjusted with viewport changes
const GROUP_STRING_DEBUG_ITEM_LABEL_VALUE :=\
		"group_ddat_debug_manager_info_overlay_value_labels"

# proportion of the viewport to set item label minimum size to
# if adjusting make sure to set this to a fractional value (default 0.04)
const DEBUG_ITEM_VALUE_MIN_SIZE_FRACTIONAL = 0.04

# this dict stores debug values passed to the info overlay (via globalDebug)
# when the update_debug_info method is called, this dict is updated
# when this dict is updated the setter for this dict calls 
var debug_item_container_node_refs = {}

# these are node paths to the major nodes in the debug info overlay scene
onready var debug_edge_margin_node: MarginContainer =\
		$Margin
onready var debug_info_column_node: VBoxContainer =\
		$Margin/InfoColumn
onready var debug_item_container_default_node: HBoxContainer =\
		$Margin/InfoColumn/ItemContainer

##############################################################################


# Called when the node enters the scene tree for the first time.
func _ready():
	# any failed success setup step will unset this
	var setup_success_state = true
	
	# set initial size based on current viewport, then prepare for
	# any future occurence of the viewport size changing and moving elements
	_on_viewport_resized_resize_info_overlay()
	if get_viewport().connect("size_changed",
			self, "_on_viewport_resized_resize_info_overlay") != OK:
		# report error on failure to get signal
		GlobalDebug.log_error(SCRIPT_NAME, "_ready", "view.connect")
		setup_success_state = false
	else:
		GlobalDebug.log_success(VERBOSE_LOGGING,\
				SCRIPT_NAME, "_ready", "view.connect")
	
	# configure the default/template item container
	# passed arg is default container (is child, should be readied) node ref
	if _setup_info_item_container(
				debug_item_container_default_node) != OK:
		# report error on failure to initially configure debug item container
		GlobalDebug.log_error(SCRIPT_NAME, "_ready", "itemcon.setup")
		setup_success_state = false
	else:
		GlobalDebug.log_success(VERBOSE_LOGGING,\
				SCRIPT_NAME, "_ready", "itemcon.setup")
	
	# before connecting next signal, verify previous setups happened as planned
	if not setup_success_state:
		return
	
	# set the connection to globalDebug so when globalDebug.update_debug_info
	# method is called, it redirects to _update_debug_item_container method
	if GlobalDebug.connect("update_debug_overlay_item",
			self, "_on_update_debug_overlay_item_notify_container") != OK:
		# report error on failure to link debug info voerlay to globalDebug
		GlobalDebug.log_error(SCRIPT_NAME, "_ready", "gdbg.connect")
	else:
		GlobalDebug.log_success(VERBOSE_LOGGING,\
				SCRIPT_NAME, "_ready", "itemcon.setup")


##############################################################################


# called whenever an item container for a specific key can't be found
# this method duplicates the default item container node,
# adds the duplicate as a child to the info column,
# and then calls _update_existing_debug_item_value with the value
func create_debug_item_container(
			debug_item_key: String,
			debug_item_new_value: String) -> HBoxContainer:
	var new_debug_item_container_node
	# check valid before duplicating
	if debug_item_container_default_node == null:
		# this should not happen
		GlobalDebug.log_error(SCRIPT_NAME, "_create_debug_item_container",
				"default_item_container.not_found")
	else:
		# add to scene tree beneath info column node
		# verify there's a valid debug info column then add the new container
		if debug_info_column_node != null:
			# log progress if verbose logging
			GlobalDebug.log_success(VERBOSE_LOGGING,\
					SCRIPT_NAME, "_ready", "newitemcon.setup.step1")
			# we wait to duplicate until we confirm there's a valid parent node
			# else we'll potentially end up with a memory leak
			new_debug_item_container_node =\
					debug_item_container_default_node.duplicate()
			# wait until the info column node has an idle frame
			debug_info_column_node.call_deferred("add_child",
					new_debug_item_container_node)
			# wait until new container is in the scene tree before continuing
			yield(new_debug_item_container_node, "ready")
			
			# after new container is readied, must configure its children
			# this sets up the value label group for viewport resizing calls
			# this also doublechecks the tree structure of the duplicate node
			if _setup_info_item_container(new_debug_item_container_node)!= OK:
				# report error on failure to configure new item container
				GlobalDebug.log_error(SCRIPT_NAME, "_ready", "newitemcon.setup")
			else:
				# log progress if verbose logging
				GlobalDebug.log_success(VERBOSE_LOGGING,\
						SCRIPT_NAME, "_ready", "newitemcon.setup.step2")
				# new item container is ready, we can now allow it to update
				# register the new item container in the node ref dictionary
				debug_item_container_node_refs[debug_item_key] =\
						new_debug_item_container_node
				# update the initial key string (done once here)
				update_debug_item_key_label(
					new_debug_item_container_node,
					debug_item_key
				)
				# call the normal update debug item value method
				update_existing_debug_item_value(
						new_debug_item_container_node,
						debug_item_new_value)
				# default item container is set invisible so last step is
				# to render the new (duplicated) item container visible
				new_debug_item_container_node.visible = true
		# if debug item column node was not readied properly (is null)
		# then there's no parent to add the new item container to
		else:
			GlobalDebug.log_error(SCRIPT_NAME, "_create_debug_item_container",
				"debug_info_column_node.not_found")
	
	return debug_item_container_default_node


func update_debug_item_key_label(
		passed_item_container: HBoxContainer,
		debug_item_key: String):
	# get label by node path
	var key_label_node = passed_item_container.get_node_or_null(
			NODE_NAME_DEBUG_ITEM_LABEL_KEY)
	if key_label_node is Label:
		key_label_node.text = debug_item_key


func update_existing_debug_item_value(
			passed_item_container: HBoxContainer,
			debug_item_new_value: String):
	# container should be inside tree before attempting to update
	if passed_item_container.is_inside_tree():
		# get label by node path
		var value_label_node = passed_item_container.get_node_or_null(
				NODE_NAME_DEBUG_ITEM_LABEL_VALUE)
		if value_label_node is Label:
			value_label_node.text = debug_item_new_value
		else:
			GlobalDebug.log_error(SCRIPT_NAME,
					"_update_existing_debug_item_value",
					"itemcon_value_is_not_label")
	else:
		GlobalDebug.log_error(SCRIPT_NAME, "_update_existing_debug_item_value",
				"passed_item_container.not_in_tree")
		return


##############################################################################


func _setup_info_item_container(passed_item_container: HBoxContainer):
	# you can pass any hbox container child of the info column,
	# as long as it has two labels,
	# and the two labels have the correct names
	var label_node_key = passed_item_container.get_node_or_null(
			NODE_NAME_DEBUG_ITEM_LABEL_KEY)
	var label_node_value = passed_item_container.get_node_or_null(
			NODE_NAME_DEBUG_ITEM_LABEL_VALUE)
	
	# check if parent is correct
	var validation_check := true
	validation_check =\
			(passed_item_container.get_parent() == debug_info_column_node)\
			and (label_node_key is Label)\
			and (label_node_value is Label)
	if not validation_check:
		GlobalDebug.log_error(SCRIPT_NAME, "_setup_info_item_container", "val")
		return ERR_UNCONFIGURED
	else:
		GlobalDebug.log_success(VERBOSE_LOGGING,\
				SCRIPT_NAME, "_setup_info_item_container", "val")
	
	# assign grouping
	if not label_node_value.is_in_group(GROUP_STRING_DEBUG_ITEM_LABEL_VALUE):
		label_node_value.add_to_group(GROUP_STRING_DEBUG_ITEM_LABEL_VALUE)
	
	# if all is good
	return OK


##############################################################################
#
# signal receipt methods


# if not found duplicate a new item container & call _setup_info_item_container
func _on_update_debug_overlay_item_notify_container(\
		item_container_key: String,
		new_value):
	
	var debug_item_value = str(new_value)
	var get_debug_item_container
	if debug_item_container_node_refs.has(item_container_key):
		get_debug_item_container =\
				debug_item_container_node_refs[item_container_key]
		update_existing_debug_item_value(
				get_debug_item_container,
				debug_item_value)
	else:
		# if container not found, create a new container and assign it
		if get_debug_item_container == null:
			var new_debug_item_container = create_debug_item_container(
						item_container_key,
						debug_item_value
			)
			# if there's a problem with the previous method it will return nil
			if new_debug_item_container != null:
				get_debug_item_container = new_debug_item_container
			else:
				GlobalDebug.log_error(SCRIPT_NAME,
					"_on_update_debug_overlay_item_notify_container",
					"new_debug_item_container.not_found")
				return
		else:
			pass


# call on ready and whenever viewport size changes
func _on_viewport_resized_resize_info_overlay():
	var new_viewport_size = get_viewport().size
	# set default sizes based on the viweport
	debug_edge_margin_node.rect_size = new_viewport_size
	
	if false:
		# set minimum bounds for item container value labels
		var item_container_value_label_nodes =\
				get_tree().get_nodes_in_group(GROUP_STRING_DEBUG_ITEM_LABEL_VALUE)
		if not item_container_value_label_nodes.empty():
			for value_label_node in item_container_value_label_nodes:
				if value_label_node is Label:
					# value labels for debug item containers have a minimum size
					# set to prevent them from jumping all over the place as the
					# value updates - by default this value is set to a small
					# proportion of the viewport, and changed if viewport resizes
					value_label_node.rect_min_size =\
							new_viewport_size*DEBUG_ITEM_VALUE_MIN_SIZE_FRACTIONAL

