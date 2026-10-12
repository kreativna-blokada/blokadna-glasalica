class_name DialogColors

static var _fallback_color := Color("#f6efdc")

#wcag aaa contrast for large text, the dialogue and name fonts are bold and above 19px
const LARGE_TEXT_CONTRAST_RATIO: float = 4.5
#step of the brightness drop towards the large text contrast, and how far it may go before the colour turns black
const TEXT_SHADE_STEP: float = 0.02
const MAX_TEXT_DARKENING: float = 0.5
#smallest hue distance, from 0 to 0.5, between the two speakers of one dialogue so their colours never mix
const SPEAKER_HUE_GAP: float = 0.25
#how far the voter colour is lightened towards white before it tints the dialogue background
const VOTER_BACKGROUND_LIGHTENING: float = 0.5

#deep text colours each dialogue draws its two speakers from: maroon, burgundy, rust, ochre, olive, forest, pine, teal, petrol, cobalt, navy, indigo, purple, plum
static var _speaker_text_colors: Array[Color] = [
	Color("#800000"), Color("#800040"), Color("#8b3a00"), Color("#6b4f00"), Color("#3d5c00"), Color("#0b5d1e"), Color("#00563f"),
	Color("#006060"), Color("#004a6e"), Color("#0039a6"), Color("#000080"), Color("#3a0080"), Color("#5a007a"), Color("#700060")
]
#colours not drawn since the palette was last refilled, and the two of the dialogue before
static var _undrawn_text_colors: Array[Color] = []
static var _previous_dialogue_text_colors: Array[Color] = []

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
		return _colors[name_token].lightened(VOTER_BACKGROUND_LIGHTENING)

	push_error("Failed to find color for name %s" % voter_name)
	return _fallback_color

static func get_default_color() -> Color:
	return _fallback_color

#left and right speaker text colours for the dialogue opening, a hue apart, none from the dialogue before and none again until the palette is drawn
static func draw_speaker_text_colors() -> Array[Color]:
	var drawn_text_colors: Array[Color] = []
	while drawn_text_colors.size() < 2:
		var eligible_text_colors: Array[Color] = []
		for undrawn_text_color in _undrawn_text_colors:
			if _is_hue_apart(undrawn_text_color, drawn_text_colors):
				eligible_text_colors.append(undrawn_text_color)

		if eligible_text_colors.is_empty():
			_refill_undrawn_text_colors(drawn_text_colors)
			continue
		var drawn_text_color: Color = eligible_text_colors.pick_random()
		_undrawn_text_colors.erase(drawn_text_color)
		drawn_text_colors.append(drawn_text_color)

	_previous_dialogue_text_colors = drawn_text_colors
	return drawn_text_colors

#puts the whole palette back, except the colours of the dialogue before and the ones already drawn for this one
static func _refill_undrawn_text_colors(drawn_text_colors: Array[Color]) -> void:
	_undrawn_text_colors.clear()
	for text_color in _speaker_text_colors:
		if not text_color in _previous_dialogue_text_colors and not text_color in drawn_text_colors:
			_undrawn_text_colors.append(text_color)

#true when the colour hue is far enough from each drawn colour hue
static func _is_hue_apart(text_color: Color, drawn_text_colors: Array[Color]) -> bool:
	for drawn_text_color in drawn_text_colors:
		var hue_distance: float = absf(text_color.h - drawn_text_color.h)
		if minf(hue_distance, 1.0 - hue_distance) < SPEAKER_HUE_GAP:
			return false
	return true

#the deep text colour darkened just enough to reach the large text contrast on the background, at most by the darkening limit
static func get_shaded_text_color(text_color: Color, background_color: Color) -> Color:
	var darkening: float = 0.0
	while darkening < MAX_TEXT_DARKENING and _get_contrast_ratio(text_color.darkened(darkening), background_color) < LARGE_TEXT_CONTRAST_RATIO:
		darkening += TEXT_SHADE_STEP
	return text_color.darkened(darkening)

#prints the text in its deep colour shaded for the background, without any outline around the letters
static func apply_text_colors(text_label: Control, text_color: Color, background_color: Color) -> void:
	var text_color_name: String = "default_color" if text_label is RichTextLabel else "font_color"
	text_label.add_theme_color_override(text_color_name, get_shaded_text_color(text_color, background_color))
	text_label.add_theme_constant_override("outline_size", 0)

#wcag contrast ratio between two colours, from 1 to 21
static func _get_contrast_ratio(first_color: Color, second_color: Color) -> float:
	var first_luminance: float = _get_relative_luminance(first_color)
	var second_luminance: float = _get_relative_luminance(second_color)
	return (maxf(first_luminance, second_luminance) + 0.05) / (minf(first_luminance, second_luminance) + 0.05)

#wcag relative luminance, weighted on linear rgb
static func _get_relative_luminance(srgb_color: Color) -> float:
	return srgb_color.srgb_to_linear().get_luminance()
