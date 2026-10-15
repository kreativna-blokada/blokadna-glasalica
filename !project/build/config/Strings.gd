##
# Copyright (C) 2026 Blokadna Igra (blokadna.igra@gmail.com)
##
#description     : Curated registry of string literals
#maintainer      : Zeljko
#version         : 1.0
#===============================================================================
class_name Literals
extends Node

#hint under the button explaining the menu option the ballot card has ticked
const MAIN_MENU_DESCRIPTIONS: Dictionary[Globals.MainMenu, String] = {
	Globals.MainMenu.Leaderboard: """КЛИКНИ НА ДУГМЕ
ДА ПОГЛЕДАШ РАНГ ЛИСТУ""",
	Globals.MainMenu.Difficulty: """КЛИКНИ НА СЕЛЕКТОР
ДА ОДАБЕРЕШ НИВО ТЕЖИНЕ""",
	Globals.MainMenu.Starting: """ПРОТРЕСИ ТЕЛЕФОН
ИЛИ КЛИКНИ ДУГМЕ 3 ПУТА""",
	Globals.MainMenu.Controls: """КЛИКНИ НА СЕЛЕКТОР
ДА ОДАБЕРЕШ КОНТРОЛЕ""",
}

#starting hint on web, where the phone can not be shaken
const WEB_MENU_START_DESCRIPTION: String = "КЛИКНИ ДУГМЕ 3 ПУТА"

#ClickCounterLabel text on the button while the leaderboard row is ticked
const LEADERBOARD_BUTTON_CAPTION: String = "ПОРЕДАК"
#IdLabel text under the ballot box before IdRevealButton is tapped
const ID_WORD: String = "ИНДЕКС"
#IdLabel text under the ballot box once IdRevealButton is tapped, filled with the leaderboard player id
const ID_CAPTION: String = "ИНДЕКС: %s"
#IdFooter text under the TextPopup footer, in latin, filled with the leaderboard player id
const ID_LATIN_CAPTION: String = "(INDEKS: %s)"

#MenuOptionButton text for each difficulty while the difficulty row is ticked
const DIFFICULTY_DESCRIPTIONS: Dictionary[GameDescriptor.Difficulty, String] = {
	GameDescriptor.Difficulty.EASY: "УЧЕЊЕ",
	GameDescriptor.Difficulty.NORMAL: "ИЗАЗОВ",
}

#MenuOptionButton text for each controls choice while the controls row is ticked
const CONTROLLER_DESCRIPTIONS: Dictionary[Globals.ControllerType, String] = {
	Globals.ControllerType.Classic: "КЛАСИЧНЕ",
	Globals.ControllerType.Screen: "ЕКРАНСКЕ",
}

#leaderboard screen board status
const BOARD_LOADING_MESSAGE: String = "УЧИТАВАЊЕ..."
const BOARD_OFFLINE_MESSAGE: String = "РАНГ ЛИСТА НИЈЕ ДОСТУПНА"
const BOARD_FAILED_MESSAGE: String = "РАНГ ЛИСТА НИЈЕ УЧИТАНА"
const EMPTY_BOARD_MESSAGE: String = "ЈОШ НЕМА РЕЗУЛТАТА"
#leaderboard rewards tab placeholder until rewards are added
const REWARDS_UPCOMING_MESSAGE: String = "НАГРАДЕ СТИЖУ УСКОРО!\nНАЈБОЉИ ИГРАЧИ ДАНА, НЕДЕЉЕ И ИЗБОРА БИЋЕ НАГРАЂЕНИ"

#leaderboard screen run score status; %d is the run score
const MISSING_USERNAME_MESSAGE: String = "УНЕСИ ИМЕ ДА ПРИЈАВИШ РЕЗУЛТАТ %s"
const SUBMIT_MESSAGE: String = "ШАЉЕМ РЕЗУЛТАТ %s..."
const SCORE_SAVED_MESSAGE: String = "РЕЗУЛТАТ %s ЈЕ САЧУВАН"
const SCORE_HIGHER_MESSAGE: String = "РЕЗУЛТАТ %s - ТВОЈ НАЈБОЉИ РЕЗУЛТАТ НА РАНГ ЛИСТИ ЈЕ ВЕЋИ"
const FAILED_MESSAGE: String = "РЕЗУЛТАТ %s НИЈЕ ПОСЛАТ"
const LEARNING_SCORE_MESSAGE: String = "РЕЗУЛТАТ %s - УЧЕЊЕ СЕ НЕ БОДУЈЕ НА РАНГ ЛИСТИ"

#leaderboard day strip captions for the two latest days; older days show their date
const TODAY_DAY_CAPTION: String = "ДАНАС"
const YESTERDAY_CAPTION: String = "ЈУЧЕ"
#leaderboard week strip caption, filled with the week's first and last date
const WEEK_CAPTION: String = "%s–%s"

#leaderboard username form status; usernames stay latin, as the database rules allow only A-Z
const USERNAME_SAVED_MESSAGE: String = "ИМЕ ЈЕ САЧУВАНО"
const USERNAME_CHECK_MESSAGE: String = "ПРОВЕРАВАМ ИМЕ..."
const USERNAME_TAKEN_MESSAGE: String = "ИМЕ ЈЕ ЗАУЗЕТО"
const USERNAME_EMPTY_MESSAGE: String = "ИМЕ НЕ МОЖЕ ДА БУДЕ ПРАЗНО"
const USERNAME_TOO_LONG_MESSAGE: String = "ИМЕ МОЖЕ ДА ИМА НАЈВИШЕ %d ЗНАКОВА"
const USERNAME_INVALID_CHARACTER_MESSAGE: String = "ИМЕ СМЕ ДА САДРЖИ САМО ЛАТИНИЧНА СЛОВА A-Z, ЦИФРЕ, РАЗМАК, _ И -"
const USERNAME_NOT_SAVED_MESSAGE: String = "ИМЕ НИЈЕ САЧУВАНО"

#game summary texts, latin like the dialogues they review
const SUMMARY_TITLE: String = "ODGOVORI"
const SUMMARY_CORRECT: String = "TAČNO"
const SUMMARY_WRONG: String = "GREŠKA"
const SUMMARY_YOUR_ANSWER: String = "TVOJ\nODGOVOR"
const SUMMARY_RIGHT_ANSWER: String = "ISPRAVAN\nODGOVOR"
const SUMMARY_WHY: String = "ZAŠTO:"
const SUMMARY_CONTINUE: String = "DALJE"
#game summary station chip for each voting stop name
const SUMMARY_STATION_LABELS: Dictionary[String, String] = {
	"Lamp": "UV LAMPA",
	"ID": "DOKUMENT",
	"List": "POTPIS",
	"Spray": "SPREJ",
	"Ballot": "LISTIĆ",
	"Booth": "PARAVAN",
	"Box": "KUTIJA",
}
