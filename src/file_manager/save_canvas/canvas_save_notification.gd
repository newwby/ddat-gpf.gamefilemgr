extends CanvasLayer

#class_name SaveNotificationCanvas

#
# SaveNotificationCanvas
#

# for logging
const SCRIPT_NAME := "SaveNotificationCanvas"
const VERBOSE_LOGGING := true

# node references
onready var saving_icon_node: TextureRect =\
		$ScreenMargin/SaveInProgressIcon
onready var pulse_animplr_node: AnimationPlayer =\
		$ScreenMargin/SaveInProgressIcon/PulseAnimator

##############################################################################

# Called when the node enters the scene tree for the first time.
#func _ready():
#	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

##############################################################################

# public


func show_icon(is_shown: bool = true):
	if saving_icon_node != null:
		saving_icon_node.visible = is_shown
	if pulse_animplr_node != null:
		pulse_animplr_node.stop()
		if is_shown:
			pulse_animplr_node.play("modulate_pulse")

