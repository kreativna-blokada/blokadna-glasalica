class_name DialogTree

func _init() -> void:
	_deserialize()
	_validate()
	pass

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

func _deserialize() -> void:
	# example before actual deserialization comes in
	var root_descriptor: DialogDescriptor = DialogDescriptor.new(
			"Hello world", DialogDescriptor.Speaker.LEFT,
			[
				DialogDescriptor.ChoiceDescriptor.new("Choice one", 100),
				DialogDescriptor.ChoiceDescriptor.new("Choice two", 2),
				DialogDescriptor.ChoiceDescriptor.new("Choice three", 3)
			])

	_root = DialogTreeNode.new(root_descriptor)

	var c1_descriptor: DialogDescriptor = DialogDescriptor.new(
			"Hello world", DialogDescriptor.Speaker.LEFT,
			[
				DialogDescriptor.ChoiceDescriptor.new("Choice one", 100),
				DialogDescriptor.ChoiceDescriptor.new("Choice two", 2),
				DialogDescriptor.ChoiceDescriptor.new("Choice three", 3)
			])
	var c2_descriptor: DialogDescriptor = DialogDescriptor.new(
			"DOBAR DAN I DOBRODOSLI NA PREDAVANJE", DialogDescriptor.Speaker.LEFT,
			[
				DialogDescriptor.ChoiceDescriptor.new("iz operativnih sistema", 100),
				DialogDescriptor.ChoiceDescriptor.new("iz osnova racunarske tehnike", 2)
			])
	var c3_descriptor: DialogDescriptor = DialogDescriptor.new(
			"Nema izbora ovde", DialogDescriptor.Speaker.LEFT,
			[])

	var c1 : DialogTreeNode = DialogTreeNode.new(c1_descriptor)
	c1.add_children([null, null, null])
	var c2 : DialogTreeNode = DialogTreeNode.new(c2_descriptor)
	c2.add_children([null, null])
	var c3 : DialogTreeNode = DialogTreeNode.new(c3_descriptor)
	c3.add_children([null])
	_root.add_children([c1, c2, c3])

var _root: DialogTreeNode