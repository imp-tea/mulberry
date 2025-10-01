extends Node

# State
var registered_npcs: Dictionary = {}  # npc_id -> NPC
var npc_memory: Dictionary = {}  # npc_id -> memory data
var current_conversation: Dictionary = {}  # Active conversation state
var active_dialogue_tree: DialogueTree = null
var current_node: DialogueNode = null

# Signals
signal dialogue_started(speaker: BaseNPC, dialogue_data: DialogueNode)
signal line_displayed(speaker: BaseNPC, text: String, tags: Dictionary)
signal choices_presented(choices: Array[DialogueChoice])
signal choice_selected(choice: DialogueChoice)
signal dialogue_finished(speaker: BaseNPC)

func register_npc(npc: BaseNPC):
	if npc.npc_id.is_empty():
		push_error("NPC must have an npc_id: " + str(npc))
		return

	registered_npcs[npc.npc_id] = npc
	if not npc_memory.has(npc.npc_id):
		npc_memory[npc.npc_id] = {
			"last_bark_time": 0,
			"last_bark_id": "",
			"lines_said": [],
			"conversation_count": 0
		}

func start_conversation(npc: BaseNPC):
	# Don't start if already in conversation
	if not current_conversation.is_empty():
		return

	# Select first available dialogue tree
	var eligible_trees = get_eligible_trees(npc)
	if eligible_trees.is_empty():
		push_warning("No eligible dialogue trees for NPC: " + npc.npc_id)
		return

	active_dialogue_tree = eligible_trees[0]
	current_node = active_dialogue_tree.root_node
	current_conversation = {
		"npc": npc,
		"tree": active_dialogue_tree,
		"started_at": Time.get_ticks_msec()
	}

	dialogue_started.emit(npc, current_node)
	display_current_node()

func display_current_node():
	if not current_node:
		end_conversation()
		return

	match current_node.type:
		DialogueNode.NodeType.LINE:
			# Display text
			var speaker = current_conversation.npc
			line_displayed.emit(speaker, current_node.text, current_node.tags)

			# Track in memory
			track_line_said(speaker.npc_id, current_node.node_id)

		DialogueNode.NodeType.CHOICE_HUB:
			# Present choices
			choices_presented.emit(current_node.choices)

		DialogueNode.NodeType.END:
			end_conversation()

func advance_to_next():
	if current_node and current_node.next_node:
		current_node = current_node.next_node
		display_current_node()
	else:
		end_conversation()

func select_choice(choice: DialogueChoice):
	if not choice:
		return

	current_node = choice.next_node
	choice_selected.emit(choice)
	display_current_node()

func get_eligible_trees(npc: BaseNPC) -> Array[DialogueTree]:
	var eligible: Array[DialogueTree] = []
	for tree in npc.dialogue_trees:
		if tree and tree.root_node:
			eligible.append(tree)
	return eligible

func track_line_said(npc_id: String, line_id: String):
	if npc_memory.has(npc_id):
		npc_memory[npc_id].lines_said.append(line_id)

func end_conversation():
	if not current_conversation.is_empty():
		var npc = current_conversation.npc
		if npc_memory.has(npc.npc_id):
			npc_memory[npc.npc_id].conversation_count += 1

		dialogue_finished.emit(npc)

	current_conversation = {}
	active_dialogue_tree = null
	current_node = null

func is_in_conversation() -> bool:
	return not current_conversation.is_empty()
