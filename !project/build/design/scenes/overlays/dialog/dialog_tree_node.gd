class_name DialogTreeNode

func _init(dialog_descriptor: DialogDescriptor) -> void:
	_dialog_descriptor = dialog_descriptor

func add_child(_child: DialogTreeNode) -> void:
	_children.append(_child)
	
func add_children(children: Array[DialogTreeNode]) -> void:
	for child in children:
		_children.append(child)

func get_num_choices() -> int:
	return len(_dialog_descriptor.choices)

func get_num_children() -> int:
	return len(_children)

func get_children() -> Array[DialogTreeNode]:
	return _children

func get_child(idx: int) -> DialogTreeNode:
	return _children[idx]

func get_dialog_descriptor() -> DialogDescriptor:
	return _dialog_descriptor



var _dialog_descriptor: DialogDescriptor
# loosely coupled with the choices, to allow easier deserialization
var _children: Array[DialogTreeNode]