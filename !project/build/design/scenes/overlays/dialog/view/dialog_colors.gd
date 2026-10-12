class_name DialogColors

static var _fallback_color := Color("#f6efdc")

#text colours for light and dark speaker fills
const DARK_TEXT_COLOR: Color = Color("#1a1a22")
const LIGHT_TEXT_COLOR: Color = Color("#fffaf0")
#wcag aaa contrast, text gets a halo in the opposite text colour
const ENHANCED_CONTRAST_RATIO: float = 7.0
#px of the halo around text on mid-tone fills
const TEXT_OUTLINE_SIZE: int = 4
#okhsl lightness above which a speaker colour counts as light
const LIGHT_FILL_LIGHTNESS: float = 0.5
#okhsl lightness step and saturation scale from a speaker colour to its highlight shade, same hue so the speaker families never mix
const HIGHLIGHT_LIGHTNESS_STEP: float = 0.18
const HIGHLIGHT_SATURATION_SCALE: float = 1.5

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

#text colour with the higher contrast against the speaker fill
static func get_text_color(fill_color: Color) -> Color:
	var dark_text_contrast: float = _get_contrast_ratio(DARK_TEXT_COLOR, fill_color)
	var light_text_contrast: float = _get_contrast_ratio(LIGHT_TEXT_COLOR, fill_color)
	return DARK_TEXT_COLOR if dark_text_contrast >= light_text_contrast else LIGHT_TEXT_COLOR

#halo colour for text on mid-tone fills, transparent when the text alone is contrasting enough
static func get_text_outline_color(fill_color: Color) -> Color:
	var text_color: Color = get_text_color(fill_color)
	if _get_contrast_ratio(text_color, fill_color) >= ENHANCED_CONTRAST_RATIO:
		return Color.TRANSPARENT
	return LIGHT_TEXT_COLOR if text_color == DARK_TEXT_COLOR else DARK_TEXT_COLOR

#shade of the speaker colour family marking the highlighted answer, darker for light colours and lighter for dark ones
static func get_highlight_color(fill_color: Color) -> Color:
	var is_light_fill: bool = fill_color.ok_hsl_l > LIGHT_FILL_LIGHTNESS
	var highlight_lightness: float = fill_color.ok_hsl_l + (-HIGHLIGHT_LIGHTNESS_STEP if is_light_fill else HIGHLIGHT_LIGHTNESS_STEP)
	var highlight_saturation: float = fill_color.ok_hsl_s * HIGHLIGHT_SATURATION_SCALE
	return Color.from_ok_hsl(fill_color.ok_hsl_h, clampf(highlight_saturation, 0.0, 1.0), clampf(highlight_lightness, 0.0, 1.0), fill_color.a)

#text colour, halo colour and halo size contrasting the fill behind the text
static func apply_text_colors(text_label: Control, fill_color: Color) -> void:
	var text_color_name: String = "default_color" if text_label is RichTextLabel else "font_color"
	text_label.add_theme_color_override(text_color_name, get_text_color(fill_color))
	text_label.add_theme_color_override("font_outline_color", get_text_outline_color(fill_color))
	text_label.add_theme_constant_override("outline_size", TEXT_OUTLINE_SIZE)

#wcag contrast ratio between two colours, from 1 to 21
static func _get_contrast_ratio(first_color: Color, second_color: Color) -> float:
	var first_luminance: float = _get_relative_luminance(first_color)
	var second_luminance: float = _get_relative_luminance(second_color)
	return (maxf(first_luminance, second_luminance) + 0.05) / (minf(first_luminance, second_luminance) + 0.05)

#wcag relative luminance, weighted on linear rgb
static func _get_relative_luminance(srgb_color: Color) -> float:
	return srgb_color.srgb_to_linear().get_luminance()