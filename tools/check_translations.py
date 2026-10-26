#!/usr/bin/env python3
"""Confere se todos os textos do jogo têm tradução em locale/en.po.

Os textos ficam em português no código e nas cenas e servem de chave
(msgid). Este script junta os textos traduzíveis e lista os que faltam no
.po e os que sobraram nele.

Uso: python3 tools/check_translations.py
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
LITERAL = r'"((?:[^"\\]|\\.)*)"'
# Textos de cena que não precisam de tradução.
IGNORED = {"+", "127.0.0.1", "Pique-Prop"}


def unescape(text):
    return text.encode().decode("unicode_escape").encode("latin-1").decode("utf-8")


def strings_in(text):
    return [unescape(s) for s in re.findall(LITERAL, text)]


def collect():
    found = set()
    scripts = [p for p in ROOT.rglob("*.gd") if ".godot" not in p.parts and "build" not in p.parts]
    for path in scripts:
        source = path.read_text()
        found.update(unescape(s) for s in re.findall(r"\btr\(" + LITERAL, source))
        for line in source.splitlines():
            # Mensagens enviadas pelo host: [chave, args...] e textos ditos em constantes.
            if re.search(r"_announce\.rpc\(\[|result_message = \[|_map_announcement = \[|_end_round\(false, \[", line):
                found.update(s for s in strings_in(line) if re.search(r"[A-Za-zÀ-ú]", s))
            elif re.search(r'^\s*"(name|description)": ', line) or "add_item(\"" in line:
                found.update(strings_in(line)[-1:] if "add_item" in line else strings_in(line)[1:2])
            elif "auto_time_check.text" in line:
                found.update(strings_in(line))
    game_state = (ROOT / "autoload/game_state.gd").read_text()
    for block in re.findall(r"const (?:MAPS|MODES).*?\n\]", game_state, re.S):
        found.update(re.findall(r'"(?:name|description)": ' + LITERAL, block))
    hud = (ROOT / "scenes/ui/hud.gd").read_text()
    found.update(re.findall(r"GameState\.Phase\.\w+: " + LITERAL, hud))
    debug = (ROOT / "autoload/debug_tools.gd").read_text()
    found.update(re.findall(r"const HELP := " + LITERAL, debug))
    input_mode = (ROOT / "autoload/input_mode.gd").read_text()
    buttons = re.search(r"const BUTTON_NAMES := \{(.*?)\n\}", input_mode, re.S).group(1)
    found.update(re.findall(r':\s*' + LITERAL, buttons))
    builder = (ROOT / "tools/map_builder.gd").read_text()
    labels = re.search(r"const PRIMITIVE_LABELS := \{(.*?)\n\}", builder, re.S).group(1)
    found.update(re.findall(r':\s*' + LITERAL, labels))
    for path in (ROOT / "scripts/catalog").glob("*_items.gd"):
        # Primeiro argumento de item(...) e dos atalhos (_sofa, _bed...) é o nome exibido.
        found.update(re.findall(r'\b(?:item|_\w+)\(' + LITERAL, path.read_text()))
    for path in (ROOT / "scenes/ui").glob("*.tscn"):
        found.update(re.findall(r'^(?:text|tooltip_text|placeholder_text) = ' + LITERAL, path.read_text(), re.M))
    return {s for s in found if s not in IGNORED and s.strip()}


def po_ids(path):
    ids = {}
    text = path.read_text()
    for match in re.finditer(r'^msgid ((?:"(?:[^"\\]|\\.)*"\s*)+)msgstr ((?:"(?:[^"\\]|\\.)*"\s*)+)', text, re.M):
        msgid = "".join(unescape(s) for s in re.findall(LITERAL, match.group(1)))
        msgstr = "".join(unescape(s) for s in re.findall(LITERAL, match.group(2)))
        if msgid:
            ids[msgid] = msgstr
    return ids


def main():
    wanted = collect()
    translated = po_ids(ROOT / "locale/en.po")
    missing = sorted(wanted - translated.keys())
    unused = sorted(translated.keys() - wanted)
    empty = sorted(k for k, v in translated.items() if not v)
    for title, items in (("Sem tradução", missing), ("Sobrando no .po", unused), ("Tradução vazia", empty)):
        if items:
            print(f"{title} ({len(items)}):")
            for item in items:
                print("  " + repr(item))
    print(f"textos: {len(wanted)} | traduzidos: {len(wanted & translated.keys())}")
    return 1 if missing or empty else 0


if __name__ == "__main__":
    sys.exit(main())
