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
