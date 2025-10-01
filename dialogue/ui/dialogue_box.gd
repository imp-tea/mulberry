extends Control
class_name DialogueBox

@export var characters_per_second: float = 42.0
@export var auto_show_on_start: bool = true

var _service = null
@onready var _speaker_label: Label = $Panel/VBox/Header/SpeakerLabel
@onready var _body_text: RichTextLabel = $Panel/VBox/BodyText
@onready var _choice_container: VBoxContainer = $Panel/VBox/ChoiceContainer
@onready var _advance_hint: Label = $Panel/VBox/Footer/AdvanceHint
@onready var _next_button: Button = $Panel/VBox/Footer/NextButton
@onready var _auto_timer: Timer = $AutoAdvanceTimer

var _active_graph_id: StringName
var _active_actor_id: StringName
var _active_node_id: StringName
var _active_snippet_id: StringName

var _is_revealing := false
var _allow_skip := true
var _pending_auto_advance := false
var _total_characters := 1
var _last_payload: Dictionary = {}

func _ready() -> void:
	_auto_timer.timeout.connect(_on_auto_advance_timeout)
	_next_button.pressed.connect(_on_next_pressed)
	_service = _get_service()
	if _service == null:
		push_warning("DialogueBox could not find DialogueService autoload.")
		return
	_service.conversation_started.connect(_on_conversation_started)
	_service.snippet_ready.connect(_on_snippet_ready)
	_service.snippet_display_completed.connect(_on_snippet_display_completed)
	_service.choice_presented.connect(_on_choice_presented)
	_service.choice_selected.connect(_on_choice_selected)
	_service.conversation_finished.connect(_on_conversation_finished)
	_reset_display()

func _process(delta: float) -> void:
	if not visible or _service == null:
		return
	if _is_revealing:
		if characters_per_second <= 0.0:
			_finish_reveal()
			return
		var step := (characters_per_second / max(1.0, float(_total_characters))) * delta
		_body_text.visible_ratio = clamp(_body_text.visible_ratio + step, 0.0, 1.0)
		if _body_text.visible_ratio >= 0.999:
			_finish_reveal()

func _unhandled_input(event: InputEvent) -> void:
	if not visible or _service == null:
		return
	if event.is_action_pressed("ui_accept"):
		if _is_revealing and _allow_skip:
			_finish_reveal()
		elif not _choice_container.visible and not _is_revealing:
			_on_next_pressed()
		get_viewport().set_input_as_handled()

func _on_conversation_started(graph_id: StringName, actor_id: StringName, node_id: StringName, _context) -> void:
	_active_graph_id = graph_id
	_active_actor_id = actor_id
	_active_node_id = node_id
	_reset_display()
	if auto_show_on_start:
		visible = true

func _on_snippet_ready(graph_id: StringName, actor_id: StringName, node_id: StringName, snippet_id: StringName, payload: Dictionary) -> void:
	if _service == null:
		return
	_active_graph_id = graph_id
	_active_actor_id = actor_id
	_active_node_id = node_id
	_active_snippet_id = snippet_id
	_last_payload = payload.duplicate(true)
	_pending_auto_advance = payload.get("auto_advance", false)
	_allow_skip = payload.get("allow_player_skip", true)
	_auto_timer.stop()
	_clear_choices()
	_body_text.bbcode_text = payload.get("text", "")
	_body_text.visible_ratio = 0.0
	_total_characters = max(1, _body_text.get_total_character_count())
	if _total_characters <= 1:
		_total_characters = max(1, payload.get("text", "").length())
	_is_revealing = true
	_next_button.disabled = true
	_advance_hint.visible = false
	_update_speaker_label(payload.get("speaker_id", StringName()))
	if auto_show_on_start:
		visible = true

func _on_snippet_display_completed(graph_id: StringName, actor_id: StringName, node_id: StringName, snippet_id: StringName) -> void:
	if graph_id != _active_graph_id or snippet_id != _active_snippet_id:
		return
	if not _choice_container.visible:
		_next_button.disabled = false
		_advance_hint.visible = true

func _on_choice_presented(graph_id: StringName, actor_id: StringName, node_id: StringName, options: Array) -> void:
	if graph_id != _active_graph_id:
		return
	_clear_choices()
	_choice_container.visible = true
	_next_button.disabled = true
	_advance_hint.visible = false
	for option_dict in options:
		var button := Button.new()
		button.text = option_dict.get("text", "...")
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var option_id: StringName = option_dict.get("id", StringName())
		button.pressed.connect(_on_choice_button_pressed.bind(option_id))
		_choice_container.add_child(button)
	if _choice_container.get_child_count() > 0:
		var first_button := _choice_container.get_child(0)
		if first_button is Control:
			(first_button as Control).grab_focus()

func _on_choice_selected(graph_id: StringName, actor_id: StringName, node_id: StringName, option_id: StringName) -> void:
	if graph_id != _active_graph_id:
		return
	_next_button.disabled = true
	_choice_container.visible = false
	_advance_hint.visible = false

func _on_conversation_finished(graph_id: StringName, actor_id: StringName, reason: String, _summary: Dictionary) -> void:
	if graph_id != _active_graph_id:
		return
	_reset_display()
	visible = false

func _on_choice_button_pressed(option_id: StringName) -> void:
	if _service == null:
		return
	_service.select_choice(option_id)
	for child in _choice_container.get_children():
		if child is Button:
			(child as Button).disabled = true

func _on_next_pressed() -> void:
	if _service == null or _is_revealing:
		return
	_next_button.disabled = true
	_advance_hint.visible = false
	_service.advance_from_snippet()

func _finish_reveal() -> void:
	if not _is_revealing:
		return
	_is_revealing = false
	_body_text.visible_ratio = 1.0
	if _service != null:
		_service.notify_snippet_display_complete()
	if _pending_auto_advance and not _choice_container.visible:
		var delay := float(_last_payload.get("auto_advance_delay", 0.75))
		_auto_timer.start(max(0.05, delay))
	else:
		_next_button.disabled = false
		_advance_hint.visible = not _choice_container.visible

func _on_auto_advance_timeout() -> void:
	if _service == null:
		return
	_service.advance_from_snippet()

func _clear_choices() -> void:
	for child in _choice_container.get_children():
		child.queue_free()
	_choice_container.visible = false

func _reset_display() -> void:
	_clear_choices()
	_body_text.bbcode_text = ""
	_body_text.visible_ratio = 0.0
	_is_revealing = false
	_next_button.disabled = true
	_advance_hint.visible = false
	_auto_timer.stop()

func _update_speaker_label(speaker_id: StringName) -> void:
	var label_text := ""
	if speaker_id != StringName() and _service != null:
		var actor_state := _service.get_actor_state(speaker_id)
		if actor_state.has("display_name"):
			label_text = str(actor_state["display_name"])
		elif actor_state.has("name"):
			label_text = str(actor_state["name"])
		else:
			label_text = String(speaker_id)
	_speaker_label.text = label_text
	_speaker_label.visible = not label_text.is_empty()

func _get_service():
	if Engine.get_singleton_list().has(StringName("DialogueService")):
		return DialogueService
	return null


