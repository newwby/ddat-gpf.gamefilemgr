extends GameGlobal

#class_name GlobalDebug

##############################################################################

# DDAT Debug Manager (or, GlobalDebug) is a singleton designed to aid in
# debugging projects, through error logging, faciliating exposure  of game
# parameters to the developer, and allowing the developer to quickly add
# 'god-mode' actions accessible through a simple UI.
#
# DEPENDENCIES
# Set as an autoload *BEFORE* DDAT_Core.GlobalData
# Set as your first autoload, or as early as you can.
#

# TODO

#// add variation of logError that is just for minor errors (never pushes)

#// instantiate and ready/setup/validate debug info overlay on startup
#// write tests for # log_error() # log_success() and update_debug_info()
#// update method returns for -> void and other in globalDebug
#// update method returns for -> void and other in infoOverlay also

# [globalDebug sample scene]
#include log_error prints, log_success prints,
# verbose_logging arguments (comment explaining why again, ref log_success),
# behaviour of debugInfoOverlay via tracking data like player input, time since scene started
# behaviour/implementation devMode action buttons and devMode command line,
# scene text background showing what key to press to call debugOverlay or devModeMenu

# [debug stat tracking panel feature list]
# - dev uses signal to update a dict with name (key) and value
# - info panel updates automatically whenever the dict data changes
# - info panel alignment and instantiation (under canvas layer) done as part of global debug
#	- info panel orders itself alphabetically
#	- info panel inits canvas layer scaled to base project resolution but dev can override
# - option(oos) category organisation; default blank enum dev can customise
#	- info panel gets subheadings & dividers, empty category == hide
# - globalDebug adds action under F1 (default) for showing panel (this auto-behaviour can be overriden)
#
# [debug action menu feature list]
# - disclaimer at top of menu informing devs to add buttons if none are present
# - command line input for written dev commands
# - keyboard/input typing solution as part of ddat_core
# - dict to add a new method, key is button text and value is method name in file
# - after dev updates dict they add a method to be called when button is pressed
# - buttons without found methods aren't shown when panel is called
# - globalDebug adds action under F2 (default0 for showing debug action panel (auto-behaviour, can be overriden)
#

##############################################################################

# the debug info overlay is a child scene of GlobalDebug which is hidden
# by default in release builds (and visible by default in debug builds),
# consisting of a vbox column of key/value label node pairs on the side
# of the viewport. This allows the developer to set signals or setters within
# their own code to automatically push changes in important values to somewhere
# visible ingame. This is useful to get feedback in unstable release builds.
signal update_debug_overlay_item(item_key, item_value)

# for passing to error logging
const SCRIPT_NAME := "GlobalDebug"

# developer flag, if set then all errors called through the log_error method
# will pause project execution through a false assertion (this functionality
# only applies to project builds with the debugger enabled).
# This flag has no effect on non-debugger/release builds.
const ASSERT_ALL_ERRRORS := false
# developer flag, if set all errors called through log_error will, in any
# build with the debugger enabled, raise the error in the debugger instead of
# as a print statement. No effect on non-debugger/release builds.
const PUSH_ERRORS_TO_DEBUGGER := true
# developer flag, if set the debugger will print a full stack trace (verbose),
# when log_error encounters an error. If unset only a partial/pruned stack
# trace will be included. No effect on non-debugger/release builds.
const PRINT_FULL_STACK_TRACE := true

# the log_success method is intended to be used in conjunction with a bool
# passed by the calling script, a constant in the caller's scope which
# can be toggled on a script-by-script basis in order to provide finer
# logging/debugging control.
# if the dev prefers, they may enable this constant to force every call to
# the log_success method to run, regardless of the calling script's flag
const FORCE_SUCCESS_LOGGING_IN_RELEASE_BUILDS := false

# This flag disables all log_error and log_success calls.
# This setting overrides all others, including any above 'FORCE_' constants.
# Enable this setting if you suspect your logging calls are becoming a
# performance drain and you would like to temporarily suspend them to improve
# game performance. Try to identify excessive calls instead of relying on this.
const OVERRIDE_DISABLE_ALL_LOGGING := false

#// DEPRECATED as now unused
# has the dev debug (info) overlay connected with the globalDebug singleton
#var is_dev_debug_overlay_connected := false
# has the dev action menu connected with the globalDebug singleton
#var is_dev_action_menu_connected := false
# reference to the dev debug (info) overlay, once connection has been made
#var dev_debug_overlay_node: DevDebugOverlay
# reference to the dev action menu, once connection has been made
#var dev_action_menu_node: DevActionMenu

###############################################################################


# debug manager prints some basic information about the user when ready
# with stdout.verbose_logging
func _ready():
	# get basic information on the user
	var user_datetime = OS.get_datetime()
	var user_model_name = OS.get_model_name()
	var user_name = OS.get_name()
	
	# convert the user datetime into something human-readable
	var user_date_as_string =\
			str(user_datetime["year"])+\
			"/"+str(user_datetime["month"])+\
			"/"+str(user_datetime["day"])
	# seperate into both date and time
	var user_time_as_string =\
			str(user_datetime["hour"])+\
			":"+str(user_datetime["minute"])+\
			":"+str(user_datetime["second"])
	
	print("debug manager readied at: "+\
			user_date_as_string+\
			" | "+\
			user_time_as_string)
	print("[user] {name}\n{model}".format({\
			"name": user_name,\
			"model": user_model_name}))


###############################################################################

#// DEPRECATED since devDebugOverlay can just connect to globalDebug signals

## this method is called by the dev debug overlay to establish a connection
## arg is the node to set as the dev debug overlay for globalDebug
#func establish_dev_debug_overlay(caller: DevDebugOverlay):
#	# if this has already been run successfully, ignore
#	if is_dev_debug_overlay_connected:
#		return OK
#
#
#	# if the dev debug overlay was already set once, ignore
#	# do not attempt to set more than one node as the dev debug overlay
#	if dev_debug_overlay_node != null:
#		return ERR_ALREADY_EXISTS
#
#	# if this is the first caller then set as the dev debug overlay
#	dev_debug_overlay_node = caller
#	# establish connection of associated method
#	connect("update_debug_info_overlay",
#			dev_debug_overlay_node, "_update_debug_item_container")
#	is_dev_debug_overlay_connected = true


###############################################################################

# [Usage]
# use GlobalDebug.log_error() in methods at points where you do not expect
# the project to reach during normal runtime
# it is best practice to at least call this method with the name of the calling
# script and an identifier for the method, as release builds (non-debugger
# enabled builds) cannot pass detailed stack information.
# As an optional third argument, you may pass a more detailed string or
# code to help you locate the error.
# in release builds only these arguments will be printed to console/log.
# in debug builds, depending on developer settings, stack traces, error
# warnings, and project pausing can be forced through this method.
static func log_error(\
		calling_script: String = "",\
		calling_method: String = "",\
		error_string: String = "") -> void:
	# if suspending logging, stop immediately
	if OVERRIDE_DISABLE_ALL_LOGGING:
		return
	
	# build error string through this method then print at end of method
	# open all errors with a new line to keep them noticeable in the log
	var print_string = "\nDBGMGR raised error"
	
	# whether release or debug build, basic information must be logged
	if calling_script != "":
		print_string += " at {script}".format({"script": calling_script})
	
	if calling_method != "":
		print_string += " in {method}".format({"method": calling_method})
		
	if error_string != "":
		print_string += " [error code: {error}]".format({"error": error_string})
	
	# debug builds have additional error logging behaviour
	if OS.is_debug_build():
		# get stack trace, split into something more readable
		var full_stack_trace = get_stack()
		var error_stack_trace = full_stack_trace[1]
		var error_func_id = error_stack_trace["function"]
		var error_node_id = error_stack_trace["source"]
		var error_line_id = error_stack_trace["line"]
		# entire stack trace is verbose, so multi-line for readability
		
		print_string += "\nStack Trace: [{f}] [{s}] [{l}]".format({\
				"f": error_func_id,
				"s": error_node_id,
				"l": error_line_id})
		print_string += "\nFull Stack Trace: "
	
	# close all errors with a new line to keep them noticeable in the log
	print_string += "\n"
	
	# with debugger running, and flag set, push as error rather than log print
	if OS.is_debug_build() and PUSH_ERRORS_TO_DEBUGGER:
		push_error(print_string)
	# print regardless
	print(print_string)
	
	# if the appropriate flag is enabled, pause project on error call
	if OS.is_debug_build() and ASSERT_ALL_ERRRORS:
		assert(false, "fatal error, see last error")


# [Usage]
# use GlobalDebug.log_success in methods at points where you expect the
# project to reach during normal runtime
# it is best practice to call this method with at least the script name, and
# the method name, as release builds (non-debugger enabled builds) cannot
# pass detailed stack information.
# unlike with its counterpart log_error, log_success requires the calling
# script's name or id (str(self) will suffice) and calling method to be passed
# as arguments. This is to prevent log_success calls being left in the
# release build without a quick means of identifying where the call was made.
# [Rationale]
# LogSuccess is a replacement for the dev practice of leaving print statements
# in a release-candidate build as a method of debugging. It should be used
# in conjunction with a script-scope bool passed as the first argument. This
# flag can be disabled per script to provide finer debugging control.
# Devs can enable the FORCE_SUCCESS_LOGGING_IN_RELEASE_BUILDS to ignore the
# above behaviour and always print log_success calls to console.
# [Disclaimer]
# LogSuccess is not intended as catch-all solution, it is to be used in
# conjunction with testing, debug builds, and debugging tools such as
# the editor debugger and inspector.
static func log_success(
		verbose_logging_enabled: bool,\
		calling_script: String,\
		calling_method: String,\
		success_string: String = "") -> void:
	# if suspending logging, stop immediately
	if OVERRIDE_DISABLE_ALL_LOGGING:
		return
	
	# log success is a debugging tool that should always be passed a bool
	# from the calling script; if the bool arg is false, and the optional
	# dev flag FORCE_SUCCESS_LOGGING_IN_RELEASE_BUILDS isn't set, this
	# method will not do anything
	if not verbose_logging_enabled\
	and not FORCE_SUCCESS_LOGGING_IN_RELEASE_BUILDS:
		return
	
	# build the print string from arguments
	var print_string = ""
	print_string += "DBGMGR.log({script}.{method})".format({\
			"script": calling_script,
			"method": calling_method,
			})
	
	# if an optional argument was included, append it ehre
	if success_string != "":
		print_string += " [{success}]".format(\
				{"success": success_string})
	
	print(print_string)


# update_debug_info is a method that interfaces with the debug_info_overlay
# child of GlobalDebug (automatically instantiated at runtime)
# arg1 is the key for the debug item.
# this argument should be different when the dev wishes to update the debug
# info overlay for a different debug item, e.g. use a separate key for player
# health, a separate key for player position, etc.
# arg1 shoulod always be a string key
# arg2 can be any type, but it will be converted to string before it is set
# to the text for the value label in the relevant debug info item container
func update_debug_overlay(debug_item_key: String, debug_item_value):
	# everything works, pass on the message to the canvas info overlay
	# validation step added due to strange method-not-declared bug that
	# ocassionally occurs
	emit_signal("update_debug_overlay_item",
			debug_item_key,
			debug_item_value)
	
	#// DEPRECATED as globalDebug no longer keeps record of devDebugOverlay
	
#	else:
#		# if the canvas wasn't found, then the overlay can't do anything
#		# we could leave this as an unanswered signal, but then we wouldn't
#		# know there was an instance of updates being made before the canvas
#		# was ready, or in instances of the canvas failing to ready.
#		log_error(SCRIPT_NAME, "update_debug_info",
#				"dev_debug_overlay not found with "+\
#				"[{key}]: {value}".format(
#				{"key": debug_item_key,
#				"value": debug_item_value})
#				)


##############################################################################

func legacy_methods_below():
	pass


###############################################################################

const UNIT_TEST_ENTRY_LOG_TO_CONSOLE = false

var is_disk_log_called_this_runtime = false

# switchable vars to control how error logging functions
# global scope so can be changed before calling groups that will throw errors
var debug_build_log_to_console = false #false #tempdisable
var debug_build_log_to_disk = false
# should always be false so removed
#var release_build_log_to_console = false
var release_build_log_to_disk = false

var debug_build_log_to_godot_file_logger = true
var release_build_log_to_godot_file_logger = true

var unit_test_log = []


###############################################################################


## override of error logging for build 0.2.6
#func log_error(error_string: String = ""):
#	if not verbose_logging:
#		print("debug manager raised error, enable verbose logging or run in debug mode")
#	pass

# expansion of error logging capabilities
func log_error_ext(error_string: String = ""):
	if verbose_logging:
		print("global_debug calling log_error()")
	var full_error_string = "| DBGMGR ERROR! |"
	var full_stack_trace = get_stack()
	# TODO IDV2 temp removal of DebugBuild stack trace decorator
#	var error_call = full_stack_trace
#	var error_func = "[stack func blank]"
#	var error_node = "[stack node blank]"
#	var error_line = "[stack line blank]"
	# deprecated due to startup crash
#	if full_stack_trace is Array:
#		error_call = full_stack_trace[1]
#		error_func = error_call["function"]
#		error_node = error_call["source"]
#		error_line = error_call["line"]
#	full_error_string += (" ["+str(error_node))+"]"
#	full_error_string += (" ["+str(error_func)+" line "+str(error_line))+"]"
	if error_string != "":
		full_error_string += (" |\n"+"| ERROR CODE: | "+error_string)
	if PRINT_FULL_STACK_TRACE:
		full_error_string += (" |\n"+"| FULL STACK TRACE: | "+str(full_stack_trace))
#	print("temp > ", get_stack())
#	print("temp[0] > ", get_stack()[0])
#	print("temp[1] > ", get_stack()[1])
	_log_error_handler(full_error_string)


# original error logging
func _log_error_handler(error_string):
	if verbose_logging:
		print("global_debug calling _log_error_handler()")
	if OS.is_debug_build() and debug_build_log_to_console:
		_log_error_to_console(error_string)

	if OS.is_debug_build() and debug_build_log_to_disk:
		_log_error_to_disk(error_string)
	elif not OS.is_debug_build() and release_build_log_to_disk:
		_log_error_to_disk(error_string)

	if OS.is_debug_build() and debug_build_log_to_godot_file_logger:
		print_debug(error_string)
	elif not OS.is_debug_build() and release_build_log_to_godot_file_logger:
		print_debug(error_string)


func _log_error_to_console(error_string):
	if verbose_logging:
		print("global_debug calling _log_error_to_console()")
	print(error_string)


# NOTE: this has been superceded by godot's internal logging system,
# which I wasn't aware of when I wrote this
func _log_error_to_disk(error_string):
	if verbose_logging:
		print("global_debug calling _log_error_to_disk()")

	# log cycling
#	var current_file_content
	if not is_disk_log_called_this_runtime:
		# removed due to lack of globalRef
		
			# move log file 2 to file 3, if file 2 exists
#		if GlobalData.validate_file_path(GlobalRef.ERROR_LOG_USER_2):
#			current_file_content = GlobalData.open_and_return_file_as_string(GlobalRef.ERROR_LOG_USER_2)
#			GlobalData.open_and_overwrite_file_with_string(GlobalRef.ERROR_LOG_USER_3, current_file_content, true)

			# move log file 1 to file 2, if file 1 exists
#		if GlobalData.validate_file_path(GlobalRef.ERROR_LOG_USER_1):
#			current_file_content = GlobalData.open_and_return_file_as_string(GlobalRef.ERROR_LOG_USER_1)
#			GlobalData.open_and_overwrite_file_with_string(GlobalRef.ERROR_LOG_USER_2, current_file_content, true)

		is_disk_log_called_this_runtime = true
	
	# removed due to lack of globalRef
#	GlobalData.open_and_overwrite_file_with_string(GlobalRef.ERROR_LOG_USER_1, error_string, true)


	# on all run write to #1 disk
	error_string = error_string


###############################################################################


# deprecating
func log_unit_test(test_outcome, origin_script, test_purpose):
	if verbose_logging:
		print("global_debug calling log_unit_test()")
	unit_test_log.append(test_outcome)
	if UNIT_TEST_ENTRY_LOG_TO_CONSOLE:
		print("outcome: "+str(test_outcome).to_upper()+" | from: "+str(origin_script)+" | purpose: "+str(test_purpose))

# deprecating
func execute_unit_test(optional_identifier_string = null):
	if verbose_logging:
		print("global_debug calling execute_unit_test()")
	var print_string = ""

	for test in unit_test_log:
		if test == false:
			print_string = "||| UNIT TEST FAILED |||"
			if typeof(optional_identifier_string) == TYPE_STRING:
				print_string = print_string+" | "+optional_identifier_string+" |"
			unit_test_log.clear()
			print(print_string)
			return false

	print_string = "||| UNIT TEST PASSED |||"
	if typeof(optional_identifier_string) == TYPE_STRING:
		print_string = print_string+" | "+optional_identifier_string+" |"
	unit_test_log.clear()
	print(print_string)
	return true


########


# public method to test whether a method's actual return value matches the
# expected return value, use for testing simple methods with a return value
# arg 1: self (usually)
# arg 2: an array of values to be tested, at least 2, expected to be equal
func unit_test_comparison_of_values(\
caller: Object,\
comparator_values = []):
	if verbose_logging:
		print("global_debug calling unit_test_comparison_of_values()")
	# check if is a valid test
	if not comparator_values.size() <= 1:
		var result = true
		var last_value = null
		var first_error_value = null
		for value in comparator_values:
			if last_value != null:
				result = (result)==(value==last_value)
				if result == false and first_error_value == null:
					first_error_value = value
			last_value = value

		# output first line
		var first_line_log_string = "###"+" UT Comparison of Values"
		if result == null:
			print(first_line_log_string + " | no result")
		elif result == true:
			print(first_line_log_string +\
					" | result OUTPUT MATCHES")
		elif result == false:
			print(first_line_log_string +\
					" | result OUTPUT DOES NOT MATCH")

		# output second line
		if caller.get("name"):
			print("on object ",	str(caller), " (", str(caller.name), ")")
		else:
			print("on object ", str(caller))

		# output third line
		if comparator_values != null:
			print(" | Compared Values: ", comparator_values)
		#
		# output fourth line
		if first_error_value != null:
			print(" | first non matching value: ", first_error_value)

	# fail state no method / called incorrectly, log error
	else:
		log_error("unit_test_comparison_of_values attempted with on "\
				+str(caller)+" but not enough values were passed. ")



# public method to test whether a method's actual return value matches the
# expected return value, use for testing simple methods with a return value
# arg 1: self (usually)
# arg 2: method name to be tested
# arg 3: expected value if any
# arg 4: values to be passed within an array
func unit_test_expected_output_comparison(\
caller: Object,\
method_name: String,\
method_values: Array = [],\
expected_return_value = null):
	if verbose_logging:
		print("global_debug calling unit_test_expected_output_comparison()")
	# check if is a valid test
	if caller.has_method(method_name):
		var actual_return_value = null
		var result = null
		actual_return_value = caller.callv(method_name, method_values)
		# get if output of the method matches expected output
		if expected_return_value != null:
			result = (expected_return_value == actual_return_value)

		# output first line
		var first_line_log_string = "###"+" UT Expected Output Comparison"
		if result == null:
			print(first_line_log_string + " | no result")
		elif result == true:
			print(first_line_log_string +\
					" | result OUTPUT MATCHES")
		elif result == false:
			print(first_line_log_string +\
					" | result OUTPUT DOES NOT MATCH EXPECTED")

		# output second line
		if caller.get("name"):
			print("on method ", method_name, " of object ",\
					str(caller), " (", str(caller.name), ")")
		else:
			print("on method ", method_name, " of object ", str(caller))
		# output third line
		if expected_return_value != null:
			print(" | Expected Result: ", expected_return_value)
		# output third line
		if actual_return_value != null:
			print(" | Actual Result: ", actual_return_value)
		else:
			print(" | No Output")
		# step output log
		print("")

	# fail state no method / called incorrectly, log error
	else:
		log_error("unit_test_expected_output_comparison attempted with "\
				+method_name+" on "\
				+str(caller)+" but method was not found ")

