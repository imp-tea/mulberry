extends Control
class_name DialogueBox

@export var text_label: RichTextLabel
@export var speaker_label: Label
@export var choices_container: VBoxContainer
@export var continue_button: Button

var choice_button_scene = preload("res://Dialogue/UI/ChoiceButton.tscn")
var current_text: String = ""
var display_speed: float = 0.03
var is_displaying: bool = false
var display_timer: float = 0.0
var char_index: int = 0
var waiting_for_input: bool = false

func _ready():
	DialogueService.dialogue_started.connect(_on_dialogue_started)
	DialogueService.line_displayed.connect(_on_line_displayed)
	DialogueService.choices_presented.connect(_on_choices_presented)
	DialogueService.dialogue_finished.connect(_on_dialogue_finished)
	visible = false

	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)

func _process(delta: float) -> void:
	if is_displaying:
		display_timer += delta
		if display_timer >= display_speed:
			display_timer = 0.0
			char_index += 1
			if char_index <= current_text.length():
				text_label.text = current_text.substr(0, char_index)
			else:
				is_displaying = false
				_on_text_finished()

func _input(event):
	if not visible:
		return

	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		if is_displaying:
			# Skip text animation
			char_index = current_text.length()
			text_label.text = current_text
			is_displaying = false
			_on_text_finished()
		elif waiting_for_input:
			_on_continue_pressed()

func _on_dialogue_started(speaker: BaseNPC, dialogue_data: DialogueNode):
	visible = true
	speaker_label.text = speaker.npc_name
	text_label.text = ""
	clear_choices()
	if continue_button:
		continue_button.visible = false

func _on_line_displayed(speaker: BaseNPC, text: String, tags: Dictionary):
	current_text = text
	char_index = 0
	is_displaying = true
	display_timer = 0.0
	waiting_for_input = false
	text_label.text = ""

	if continue_button:
		continue_button.visible = false

	speaker_label.text = speaker.npc_name

func _on_text_finished():
	# Check if this line has a next node (auto-advance) or needs input
	if DialogueService.current_node and DialogueService.current_node.type == DialogueNode.NodeType.LINE:
		if DialogueService.current_node.next_node:
			waiting_for_input = true
			if continue_button:
				continue_button.visible = true
		else:
			# No next node, end conversation
			DialogueService.end_conversation()

func _on_continue_pressed():
	if waiting_for_input:
		waiting_for_input = false
		if continue_button:
			continue_button.visible = false
		DialogueService.advance_to_next()

func _on_choices_presented(choices: Array[DialogueChoice]):
	clear_choices()

	if continue_button:
		continue_button.visible = false

	for choice in choices:
		var button: Button = choice_button_scene.instantiate()
		button.text = choice.text
		button.pressed.connect(func(): _on_choice_selected(choice))
		choices_container.add_child(button)

func _on_choice_selected(choice: DialogueChoice):
	clear_choices()
	DialogueService.select_choice(choice)

func clear_choices():
	for child in choices_container.get_children():
		child.queue_free()

func _on_dialogue_finished(speaker: BaseNPC):
	visible = false
	clear_choices()
	text_label.text = ""
	speaker_label.text = ""
