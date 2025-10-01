# Example dialogue tree creation script
# This demonstrates how to create a DialogueTree programmatically
# In practice, you would create these as .tres Resource files in the Godot editor

static func create_example_dialogue() -> DialogueTree:
	var tree = DialogueTree.new()
	tree.tree_id = "shop_keeper_greeting"

	# Create nodes
	var greeting = DialogueNode.new()
	greeting.node_id = "greeting_1"
	greeting.type = DialogueNode.NodeType.LINE
	greeting.text = "Welcome to my shop! Are you looking for some plants today?"

	var choice_hub = DialogueNode.new()
	choice_hub.node_id = "choice_hub_1"
	choice_hub.type = DialogueNode.NodeType.CHOICE_HUB

	# Create choices
	var choice_yes = DialogueChoice.new()
	choice_yes.text = "Yes, I'd like to browse your selection."

	var choice_no = DialogueChoice.new()
	choice_no.text = "No thanks, just looking around."

	var choice_question = DialogueChoice.new()
	choice_question.text = "What kinds of plants do you have?"

	# Create response nodes
	var response_yes = DialogueNode.new()
	response_yes.node_id = "response_yes"
	response_yes.type = DialogueNode.NodeType.LINE
	response_yes.text = "Wonderful! Take your time and let me know if you need any help."

	var response_no = DialogueNode.new()
	response_no.node_id = "response_no"
	response_no.type = DialogueNode.NodeType.LINE
	response_no.text = "No problem! Feel free to explore the shop."

	var response_question = DialogueNode.new()
	response_question.node_id = "response_question"
	response_question.type = DialogueNode.NodeType.LINE
	response_question.text = "I specialize in native plants! Everything from pitcher plants to wildflowers."

	# Create end nodes
	var end_yes = DialogueNode.new()
	end_yes.node_id = "end_1"
	end_yes.type = DialogueNode.NodeType.END

	var end_no = DialogueNode.new()
	end_no.node_id = "end_2"
	end_no.type = DialogueNode.NodeType.END

	var end_question = DialogueNode.new()
	end_question.node_id = "end_3"
	end_question.type = DialogueNode.NodeType.END

	# Connect nodes
	greeting.next_node = choice_hub

	choice_yes.next_node = response_yes
	choice_no.next_node = response_no
	choice_question.next_node = response_question

	choice_hub.choices = [choice_yes, choice_no, choice_question]

	response_yes.next_node = end_yes
	response_no.next_node = end_no
	response_question.next_node = end_question

	tree.root_node = greeting

	return tree
