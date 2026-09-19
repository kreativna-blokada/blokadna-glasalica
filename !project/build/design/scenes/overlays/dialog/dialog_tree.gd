class_name DialogTree

func _init(file_path: String) -> void:
	_deserialize(file_path)
	_validate()

func get_root() -> DialogTreeNode:
	return _root

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

func _deserialize(file_path: String) -> void:
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	var data: Dictionary = JSON.parse_string(file.get_as_text())

	var id_to_node: Dictionary = {}
	var node_dependencies: Dictionary = {}

	for id in data:
		var choiceDescriptors: Array[DialogDescriptor.ChoiceDescriptor] = []
		var dependencies: Array[String] = []
		# only if choices actually exist
		if "choices" in data[id]:
			for choice in data[id].choices:
				var choice_descriptor: DialogDescriptor.ChoiceDescriptor = DialogDescriptor.ChoiceDescriptor.new(choice.text, choice.score)
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
				data[id].text,
				DialogDescriptor.Speaker.LEFT, # todo serialize
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
	
	
	file.close()
	
var _root: DialogTreeNode
