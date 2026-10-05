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
	Globals.MainMenu.Team: """КРЕАТИВНА БЛОКАДА

Марија М., Игор И.,
Немања М., Ђорђе Ђ.,
Александар Љ., Андреј О.,
Давор В., Марко М.,
Милош С., Немања Л.,
Милош П., Владимир А.,
Жељко В. као и сви
саборци студентског покрета""",
}

#starting hint on web, where the phone can not be shaken
const WEB_MENU_START_DESCRIPTION: String = "КЛИКНИ ДУГМЕ 3 ПУТА"

#MenuOptionButton text for each difficulty while the difficulty row is ticked
const DIFFICULTY_DESCRIPTIONS: Dictionary[GameDescriptor.Difficulty, String] = {
	GameDescriptor.Difficulty.EASY: "ЖЕЛИМ ДА УЧИМ",
	GameDescriptor.Difficulty.NORMAL: "ХОЋУ ИЗАЗОВ",
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

#leaderboard screen run score status; %d is the run score
const MISSING_USERNAME_MESSAGE: String = "УНЕСИ ИМЕ ДА ПРИЈАВИШ РЕЗУЛТАТ %d"
const SUBMIT_MESSAGE: String = "ШАЉЕМ РЕЗУЛТАТ %d..."
const SCORE_SAVED_MESSAGE: String = "РЕЗУЛТАТ %d ЈЕ САЧУВАН"
const SCORE_HIGHER_MESSAGE: String = "РЕЗУЛТАТ %d - ТВОЈ НАЈБОЉИ РЕЗУЛТАТ НА РАНГ ЛИСТИ ЈЕ ВЕЋИ"
const FAILED_MESSAGE: String = "РЕЗУЛТАТ %d НИЈЕ ПОСЛАТ"

#leaderboard username form status; usernames stay latin, as the database rules allow only A-Z
const USERNAME_SAVED_MESSAGE: String = "ИМЕ ЈЕ САЧУВАНО"
const USERNAME_CHECK_MESSAGE: String = "ПРОВЕРАВАМ ИМЕ..."
const USERNAME_TAKEN_MESSAGE: String = "ИМЕ ЈЕ ЗАУЗЕТО"
const USERNAME_EMPTY_MESSAGE: String = "ИМЕ НЕ МОЖЕ ДА БУДЕ ПРАЗНО"
const USERNAME_TOO_LONG_MESSAGE: String = "ИМЕ МОЖЕ ДА ИМА НАЈВИШЕ %d ЗНАКОВА"
const USERNAME_INVALID_CHARACTER_MESSAGE: String = "ИМЕ СМЕ ДА САДРЖИ САМО ЛАТИНИЧНА СЛОВА A-Z, ЦИФРЕ, РАЗМАК, _ И -"
const USERNAME_NOT_SAVED_MESSAGE: String = "ИМЕ НИЈЕ САЧУВАНО"
