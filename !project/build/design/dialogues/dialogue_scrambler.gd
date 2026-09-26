##
# Copyright (C) 2026 Blokadna Igra (blokadna.igra@gmail.com)
##
#description     : Unscrambles dialogue content made by scramble_dialogues.py (XOR with a SHA-256 checksum)
#author          : Zeljko Vulovic
#date            : 20260924
#version         : 1.0
#===============================================================================
class_name DialogueScrambler

const SHA256_DIGEST_SIZE: int = 32

#private vars
static var _scrambler_key: PackedByteArray = PackedByteArray()

#FUNCTIONS
#███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗███████╗
#██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
#█████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████╗
#██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║╚════██║
#██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║███████║
#╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝

#returns the plain bytes, or an empty array if the input is malformed, altered or the key is wrong
static func unscramble_dialogue_content(scrambled_dialogues: PackedByteArray) -> PackedByteArray:
	if scrambled_dialogues.size() <= SHA256_DIGEST_SIZE:
		return PackedByteArray()

	var scrambler_key: PackedByteArray = _get_scrambler_key()
	if scrambler_key.is_empty():
		return PackedByteArray()
	var checksummed_dialogues: PackedByteArray = scrambled_dialogues.duplicate()
	for byte_index in checksummed_dialogues.size():
		checksummed_dialogues[byte_index] ^= scrambler_key[byte_index % scrambler_key.size()]

	var readable_dialogues: PackedByteArray = checksummed_dialogues.slice(SHA256_DIGEST_SIZE)
	if checksummed_dialogues.slice(0, SHA256_DIGEST_SIZE) != _get_dialogues_checksum(readable_dialogues):
		return PackedByteArray()
	return readable_dialogues

#computes the SHA-256 checksum of the given bytes
static func _get_dialogues_checksum(readable_dialogues: PackedByteArray) -> PackedByteArray:
	var dialogues_hashing_context: HashingContext = HashingContext.new()
	dialogues_hashing_context.start(HashingContext.HASH_SHA256)
	dialogues_hashing_context.update(readable_dialogues)
	return dialogues_hashing_context.finish()

#hashed scramble key from the gitignored runtime credentials, or an empty array if it is missing
static func _get_scrambler_key() -> PackedByteArray:
	if _scrambler_key.is_empty():
		var runtime_credentials: ConfigFile = ConfigFile.new()
		if runtime_credentials.load(Globals.RUNTIME_CREDENTIALS) != OK:
			push_error("DialogueScrambler._get_scrambler_key: missing %s" % Globals.RUNTIME_CREDENTIALS)
			return PackedByteArray()
		var scramble_passphrase: String = str(runtime_credentials.get_value("dialogues", "scrambler_key", ""))
		if scramble_passphrase.is_empty():
			push_error("DialogueScrambler._get_scrambler_key: no dialogues/scrambler_key in %s" % Globals.RUNTIME_CREDENTIALS)
			return PackedByteArray()
		_scrambler_key = scramble_passphrase.sha256_buffer()
	return _scrambler_key
