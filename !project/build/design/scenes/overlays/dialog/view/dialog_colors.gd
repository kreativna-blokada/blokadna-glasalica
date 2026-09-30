class_name DialogColors

static var _fallback_color := Color("#f6efdc")

static var _colors: Dictionary[String, Color] = {
	"MaleCap" : Color("#a8a6a8"),
	"MaleBlue" : Color("#59616d"),
	"MaleGreen" : Color("#647569"),
	"MaleIndigo" : Color("#5a627b"),
	"MaleMagenta" : Color("#68627b"),
	"MaleRed" : Color("#7e5c66"),
	"MaleViolet" : Color("#6d6d6d"),
	"MaleYellow" : Color("#657470"),
	"FemaleBlondeLilacSkirt" : Color("#a08aba"),
	"FemaleBlondeRoseSkirt" : Color("#be6e86"),
	"FemaleBlondeWineSkirt" : Color("#8e4056"),
	"FemaleBrunetteLilacSkirt" : Color("#a08aba"),
	"FemaleBrunetteRoseSkirt" : Color("#be6e86"),
	"FemaleBrunetteWineSkirt" : Color("#8e4056"),
	"FemaleShortHairBlondeLilacPants" : Color("#a08aba"),
	"FemaleShortHairBrunetteRosePants" : Color("#be6e86")
}

static func get_color(voter_name: String) -> Color:
	var name_token := voter_name.split('_')[0]
	if _colors.has(name_token):
		return _colors[name_token]
	
	push_error("Failed to find color for name %s" % voter_name)
	return _fallback_color

static func get_default_color() -> Color:
	return _fallback_color