#!/usr/bin/env python3
"""E6b-4: chaves do tamanho do card (largura/altura) no editor.

Uso, na raiz do projeto:  python3 update_arb_e6b4.py
Saída esperada na 1ª vez: "+12 chaves" para pt, es e en.
Saída esperada na 2ª vez: "+0 chaves" para os três (idempotente).
Depois: flutter gen-l10n
"""
import json
import pathlib
import sys

PH_WH = {"width": {"type": "int"}, "height": {"type": "int"}}
PH_CT = {"current": {"type": "int"}, "total": {"type": "int"}}

# chave -> (pt, es, en, placeholders ou None)
KEYS = {
    "cardSizeTitle": (
        "Tamanho do card", "Tamaño de la tarjeta", "Card size", None),
    "cardSizeHelp": (
        "O card cresce para a direita e para baixo, só sobre posições em "
        "branco. O tamanho vale quando você salva.",
        "La tarjeta crece hacia la derecha y hacia abajo, solo sobre "
        "posiciones en blanco. El tamaño vale al guardar.",
        "The card grows to the right and downward, only over blank "
        "positions. The size applies when you save.",
        None),
    "cardSizeSummary": (
        "Tamanho: {width} × {height} posições (largura × altura).",
        "Tamaño: {width} × {height} posiciones (ancho × alto).",
        "Size: {width} × {height} positions (width × height).",
        PH_WH),
    "cardSizeNoRoomRight": (
        "Não há espaço para crescer à direita.",
        "No hay espacio para crecer a la derecha.",
        "There is no room to grow to the right.",
        None),
    "cardSizeNoRoomBelow": (
        "Não há espaço para crescer para baixo.",
        "No hay espacio para crecer hacia abajo.",
        "There is no room to grow downward.",
        None),
    "cardSizeWidthOf": (
        "Largura: {current} de {total}",
        "Ancho: {current} de {total}",
        "Width: {current} of {total}",
        PH_CT),
    "cardSizeHeightOf": (
        "Altura: {current} de {total}",
        "Alto: {current} de {total}",
        "Height: {current} of {total}",
        PH_CT),
    "cardSizeWidthDecrease": (
        "Diminuir a largura", "Reducir el ancho", "Decrease width", None),
    "cardSizeWidthIncrease": (
        "Aumentar a largura", "Aumentar el ancho", "Increase width", None),
    "cardSizeHeightDecrease": (
        "Diminuir a altura", "Reducir el alto", "Decrease height", None),
    "cardSizeHeightIncrease": (
        "Aumentar a altura", "Aumentar el alto", "Increase height", None),
    "cardSizeNotFit": (
        "O tamanho escolhido não cabe mais. Ajuste e salve de novo.",
        "El tamaño elegido ya no cabe. Ajústalo y guarda de nuevo.",
        "The chosen size no longer fits. Adjust it and save again.",
        None),
}


def find(lang: str) -> pathlib.Path:
    found = sorted(pathlib.Path("lib").rglob(f"app_{lang}.arb"))
    if len(found) != 1:
        sys.exit(f"app_{lang}.arb: esperava 1 arquivo em lib/, achei {found}")
    return found[0]


def update(lang: str, index: int) -> None:
    path = find(lang)
    data = json.loads(path.read_text(encoding="utf-8"))
    added = 0
    for key, values in KEYS.items():
        if key in data:
            continue
        data[key] = values[index]
        added += 1
        # @meta só no ARB-base (pt), como no resto do projeto.
        if lang == "pt" and values[3] is not None:
            data[f"@{key}"] = {"placeholders": values[3]}
    path.write_text(
        json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"{path}: +{added} chaves")


for i, lang in enumerate(("pt", "es", "en")):
    update(lang, i)
