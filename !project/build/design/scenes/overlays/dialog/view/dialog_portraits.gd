class_name DialogPortraits

#atlas of all dialog busts, loaded on the first bust asked for
static var _atlas: Texture2D

#bust of the voter variant, the cap voter standing in for a variant without one like it does for the room sprite
static func get_voter_portrait(voter_factory_index: int) -> AtlasTexture:
	var voter_entry: Dictionary = Globals.VoterFactory.get(voter_factory_index, Globals.VoterFactory[Globals.Voter.MaleCap])
	return _get_cell_texture(voter_entry["Portrait"])

#bust of the staff member at the stop, the id clerk standing in at a stop without its own bust
static func get_staff_portrait(stop_name: String) -> AtlasTexture:
	var stop_key: String = stop_name.to_snake_case()
	if not Globals.StaffPortraits.has(stop_key):
		push_warning("No staff portrait for stop %s, showing the id clerk" % stop_name)
		stop_key = "id"
	return _get_cell_texture(Globals.StaffPortraits[stop_key])

#the atlas cell as its own texture
static func _get_cell_texture(cell: Vector2i) -> AtlasTexture:
	if _atlas == null:
		_atlas = load(Globals.Portraits["atlas"])
	var cell_size: int = Globals.Portraits["cell_size"]
	var cell_texture := AtlasTexture.new()
	cell_texture.atlas = _atlas
	cell_texture.region = Rect2(cell * cell_size, Vector2(cell_size, cell_size))
	return cell_texture
