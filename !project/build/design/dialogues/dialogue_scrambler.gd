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

	var scramble_key: PackedByteArray = _get_scramble_key()
	var checksummed_dialogues: PackedByteArray = scrambled_dialogues.duplicate()
	for byte_index in checksummed_dialogues.size():
		checksummed_dialogues[byte_index] ^= scramble_key[byte_index % scramble_key.size()]

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

#assembled at runtime so the key never appears as one searchable string in the exported .pck
static func _get_scramble_key() -> PackedByteArray:
	return "".join(["gl4", "sal", "1ca", "-", str(7 * 131), "-d1", "al0g"]).sha256_buffer()
