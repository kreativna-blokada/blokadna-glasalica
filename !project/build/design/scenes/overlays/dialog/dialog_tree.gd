class_name DialogTree

func _init(file_path: Dictionary) -> void:
	#### file_path should be renamed to dialog_data
	_deserialize(file_path)
	_validate()

func get_root() -> DialogTreeNode:
	return _root

#returns a description of the first structural problem in dialogue data, or "" if it can be deserialized
static func find_data_error(parsed_dialogue: Dictionary) -> String:
	if not parsed_dialogue.get("root") is Dictionary:
		return "missing \"root\" node"
	for dialogue_node_id in parsed_dialogue:
		var dialogue_node: Variant = parsed_dialogue[dialogue_node_id]
		if not dialogue_node is Dictionary or not dialogue_node.get("text") is String:
			return "node \"%s\" needs a \"text\" string" % dialogue_node_id
		var next_node_ids: Array = []
		if dialogue_node.has("choices"):
			if not dialogue_node.choices is Array or dialogue_node.choices.is_empty():
				return "node \"%s\" has an empty or invalid \"choices\"" % dialogue_node_id
			for choice in dialogue_node.choices:
				if not choice is Dictionary or not choice.get("text") is String \
						or not choice.get("explanation") is String \
						or not (choice.get("score") is float or choice.get("score") is int):
					return "node \"%s\" has a choice without text, explanation or score" % dialogue_node_id
				next_node_ids.append(choice.get("next", ""))
		else:
			next_node_ids.append(dialogue_node.get("next", ""))
		for next_node_id in next_node_ids:
			if not next_node_id is String or (next_node_id != "" and not parsed_dialogue.has(next_node_id)):
				return "node \"%s\" points to unknown node \"%s\"" % [dialogue_node_id, next_node_id]
	return ""

# dfs go through each node
# the number of children should always equal the number of choices
# except when there aren't any choices, where the number of children should be one.
# each child may be null, but the count must be as described.
func _validate() -> bool:
	
	var node_stk : Array[DialogTreeNode] = []
	node_stk.push_back(_root)

	var invalid_nodes : Array[DialogTreeNode] = []

	while not node_stk.is_empty():
		var node: DialogTreeNode = node_stk.pop_back()
		var num_choices: int = node.get_num_choices()
		var num_children: int = node.get_num_children()
		
		if num_choices == 0 and num_children != 1:
			invalid_nodes.push_back(node)
		
		if num_choices > 0 and num_children != num_choices:
			invalid_nodes.push_back(node)
		
		for child in node.get_children():
			if child != null:
				node_stk.push_back(child)
		
	if not invalid_nodes.is_empty():
		var invalid_nodes_str: String = ""
		for node in invalid_nodes:
			invalid_nodes_str += node._dialog_descriptor.text
			invalid_nodes_str += '\n'
		
		push_error("Dialog tree is invalid. Invalid nodes:\n%s" % invalid_nodes_str)
	
	return len(invalid_nodes) == 0

func _deserialize(data: Dictionary) -> void:
	#### commented out 7b64814055ee6b6eb9d15d2b811ccde201717f87
	#### var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	#### var data: Dictionary = JSON.parse_string(file.get_as_text())

	var id_to_node: Dictionary = {}
	var node_dependencies: Dictionary = {}

	for id in data:
		var choiceDescriptors: Array[DialogDescriptor.ChoiceDescriptor] = []
		var dependencies: Array[String] = []
		
		var speaker := DialogDescriptor.Speaker.LEFT
		if "speaker" in data[id]:
			speaker = DialogDescriptor.Speaker.get(data[id].speaker)
		
		# only if choices actually exist
		if "choices" in data[id]:
			for choice in data[id].choices:
				var choice_descriptor: DialogDescriptor.ChoiceDescriptor = DialogDescriptor.ChoiceDescriptor.new(
						choice.text, 
						choice.score,
						choice.explanation
				)
				choiceDescriptors.push_back(choice_descriptor)
				# a choice can terminate the conversation, or lead to another node
				if "next" in choice:
					dependencies.push_back(choice.next)
				else:
					dependencies.push_back("")
		# otherwise, a next node might exist
		elif "next" in data[id]:
			dependencies.push_back(data[id].next)
		# if not, this is a leaf node with no choices.
		else:
			dependencies.push_back("")
		
		var descriptor: DialogDescriptor = DialogDescriptor.new(
				_strip_mood_marker(data[id].text),
				speaker,
				choiceDescriptors
		)

		id_to_node[id] = DialogTreeNode.new(descriptor)
		node_dependencies[id] = dependencies
		
	# there MUST be a root node
	_root = id_to_node["root"]
	for id in node_dependencies:
		for dep_id in node_dependencies[id]:
			if dep_id == "":
				id_to_node[id].add_child(null)
			else:
				id_to_node[id].add_child(id_to_node[dep_id])
	
	#### commented out 7b64814
	#### file.close()

#removes a leading mood marking like [POL] so it never shows in the dialogue
static func _strip_mood_marker(dialogue_text: String) -> String:
	for mood_marker in Globals.DIALOGUE_MOOD_MARKERS:
		if dialogue_text.begins_with(mood_marker):
			return dialogue_text.trim_prefix(mood_marker).strip_edges(true, false)
	return dialogue_text

var _root: DialogTreeNode
