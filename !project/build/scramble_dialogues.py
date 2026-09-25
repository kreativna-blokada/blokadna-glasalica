#!/usr/bin/env python3
import hashlib
import json
import sys
import time
from pathlib import Path

#XOR-scrambles dialogues/voter_*.json into dialogues_content.bin
#dialogues_content.bin is built into the game and hosted online
PROJECT_DIR = Path(__file__).resolve().parents[2]
SOURCE_DIR = PROJECT_DIR / "!project/build/design/dialogues"
DIALOGUES_BUILTIN_PATH = SOURCE_DIR / "dialogues_content.bin"
# local clone of github.com/zeljko-vulovic/glasalica
HOSTED_PATH = PROJECT_DIR.parent.parent / "glasalica/dialogues.bin"

# must match DialogueScrambler._get_scramble_key()
KEY = hashlib.sha256(b"gl4sal1ca-917-d1al0g").digest()


# mirrors DialogTree.find_data_error
def find_data_error(data):
    if not isinstance(data.get("root"), dict):
        return 'missing "root" node'
    for node_id, node in data.items():
        if not isinstance(node, dict) or not isinstance(node.get("text"), str):
            return f'node "{node_id}" needs a "text" string'
        if "choices" in node:
            choices = node["choices"]
            if not isinstance(choices, list) or not choices:
                return f'node "{node_id}" has an empty or invalid "choices"'
            for choice in choices:
                score = choice.get("score") if isinstance(choice, dict) else None
                if not isinstance(choice, dict) or not isinstance(choice.get("text"), str) \
                        or not isinstance(choice.get("explanation"), str) \
                        or isinstance(score, bool) or not isinstance(score, (int, float)):
                    return f'node "{node_id}" has a choice without text, explanation or score'
            nexts = [choice.get("next", "") for choice in choices]
        else:
            nexts = [node.get("next", "")]
        for next_id in nexts:
            if not isinstance(next_id, str) or (next_id and next_id not in data):
                return f'node "{node_id}" points to unknown node "{next_id}"'
    return ""


# returns SHA-256 checksum + content, XORed with the repeating key
def scramble(plain):
    data = hashlib.sha256(plain).digest() + plain
    return bytes(byte ^ KEY[i % len(KEY)] for i, byte in enumerate(data))


def main():
    dialogues = {}
    for path in sorted(SOURCE_DIR.glob("voter_*.json")):
        try:
            dialogue = json.loads(path.read_text(encoding="utf-8-sig"))
        except json.JSONDecodeError as error:
            sys.exit(f"Invalid dialogue {path.name}: {error}")
        error_message = "not a JSON object" if not isinstance(dialogue, dict) else find_data_error(dialogue)
        if error_message:
            sys.exit(f"Invalid dialogue {path.name}: {error_message}")
        dialogues[path.stem] = dialogue

    content = {"version": int(time.time()), "dialogues": dialogues}
    scrambled = scramble(json.dumps(content, ensure_ascii=False).encode("utf-8"))

    DIALOGUES_BUILTIN_PATH.write_bytes(scrambled)
    print(f"Scrambled {len(dialogues)} dialogues, version {content['version']} -> {DIALOGUES_BUILTIN_PATH}")

    if not HOSTED_PATH.parent.is_dir():
        print(f"Hosting repo not found, skipped: {HOSTED_PATH}")
        return
    HOSTED_PATH.write_bytes(scrambled)
    print(f"Hosted copy -> {HOSTED_PATH} (commit and push it to publish)")


if __name__ == "__main__":
    main()
