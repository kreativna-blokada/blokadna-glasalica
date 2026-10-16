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

#leaderboard screen board status, latin like the game summary before it
const BOARD_LOADING_MESSAGE: String = "UČITAVANJE..."
const BOARD_OFFLINE_MESSAGE: String = "RANG LISTA NIJE DOSTUPNA"
const BOARD_FAILED_MESSAGE: String = "RANG LISTA NIJE UČITANA"
const EMPTY_BOARD_MESSAGE: String = "JOŠ NEMA REZULTATA"
#rewards screen rules for claiming a top list reward
const REWARDS_RULES_MESSAGE: String = "Prva 3 igrača na dnevnoj, nedeljnoj i ukupnoj rang-listi (zatvara se 31.10.2026.) osvajaju poklon. Piši nam na blokadna.igra@gmail.com i pošalji snimak ekrana sa svojim korisničkim imenom i ID-jem, da potvrdimo tvoj rezultat."

#leaderboard screen captions
const BOARD_TITLE: String = "RANG LISTA"
const BOARD_BACK: String = "NAZAD"
const BOARD_REWARDS: String = "NAGRADE"
#leaderboard tab caption for each score board
const BOARD_TAB_CAPTIONS: Dictionary[Globals.ScoreBoard, String] = {
	Globals.ScoreBoard.Daily: "DNEVNA",
	Globals.ScoreBoard.Weekly: "NEDELJNA",
	Globals.ScoreBoard.Total: "UKUPNA",
}
#leaderboard rank chip and row rank, filled with the rank
const BOARD_RANK_CAPTION: String = "%d."
#leaderboard rank chip and own row below the best scores, whose exact rank is not counted; filled with the number of best scores
const BOARD_BELOW_TOP_CAPTION: String = "> %d"
#leaderboard chip when the player has no score in the period, for each score board
const BOARD_NO_RESULT_CAPTIONS: Dictionary[Globals.ScoreBoard, String] = {
	Globals.ScoreBoard.Daily: "NEMAŠ REZULTAT ZA OVAJ DAN",
	Globals.ScoreBoard.Weekly: "NEMAŠ REZULTAT ZA OVU NEDELJU",
	Globals.ScoreBoard.Total: "NEMAŠ REZULTAT",
}
#leaderboard gap row between the best scores and the player's own lower row
const BOARD_GAP_CAPTION: String = "···"

#leaderboard period captions; the upper line names the period, the lower line dates it
const TODAY_DAY_CAPTION: String = "DANAS"
const YESTERDAY_CAPTION: String = "JUČE"
#weekday names, Monday first, for days older than yesterday
const WEEKDAY_CAPTIONS: PackedStringArray = ["PONEDELJAK", "UTORAK", "SREDA", "ČETVRTAK", "PETAK", "SUBOTA", "NEDELJA"]
const THIS_WEEK_CAPTION: String = "OVA NEDELJA"
const LAST_WEEK_CAPTION: String = "PROŠLA NEDELJA"
const OLDER_WEEK_CAPTION: String = "NEDELJA"
#filled with the week's first and last date
const WEEK_DATES_CAPTION: String = "%s – %s"
const TOTAL_CAPTION: String = "UKUPNO"
const TOTAL_DATES_CAPTION: String = "cela ukupna sezona"

#name step captions and notes; %s is the run score
const USERNAME_TITLE: String = "TVOJE IME"
const USERNAME_CONTINUE: String = "DALJE"
const USERNAME_HINT: String = "Ovo ime vide ostali igrači na rang listi."
#filled with the typed and the allowed name length
const USERNAME_COUNTER_CAPTION: String = "%d / %d"
#above the run score the name step is about to send
const USERNAME_POINTS_CAPTION: String = "OSVOJENO POENA"
const FAILED_MESSAGE: String = "REZULTAT %s NIJE POSLAT"
#the database kept the player's higher best score
const SCORE_HIGHER_MESSAGE: String = "REZULTAT %s - TVOJ NAJBOLJI REZULTAT NA RANG LISTI JE VEĆI"
#learning runs never reach the leaderboard
const LEARNING_SCORE_MESSAGE: String = "REZULTAT %s - UČENJE SE NE BODUJE NA RANG LISTI"
#usernames stay latin, as the database rules allow only A-Z
const USERNAME_TAKEN_MESSAGE: String = "IME JE ZAUZETO"
const USERNAME_EMPTY_MESSAGE: String = "IME NE MOŽE DA BUDE PRAZNO"
const USERNAME_TOO_LONG_MESSAGE: String = "IME MOŽE DA IMA NAJVIŠE %d ZNAKOVA"
const USERNAME_INVALID_CHARACTER_MESSAGE: String = "IME SME DA SADRŽI SAMO SLOVA A-Z, CIFRE, RAZMAK, _ I -"
const USERNAME_NOT_SAVED_MESSAGE: String = "IME NIJE SAČUVANO"

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
