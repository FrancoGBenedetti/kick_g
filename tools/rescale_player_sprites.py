#!/usr/bin/env python3
"""
rescale_player_sprites.py
=========================
Rescala todos los sprites del jugador de 192×128 → 128×128.

Transformación:
  - Escala al 75% con NEAREST (sin interpolación, sin blur)
  - Recentra el resultado en un canvas 128×128 alineando el
    punto de suelo (origin_y=118) exactamente en y=118 del nuevo canvas
  - Actualiza los metadatos .yy: width, seqWidth, xorigin, yorigin, bbox

Uso:
  python3 tools/rescale_player_sprites.py --dry-run   # solo muestra cambios
  python3 tools/rescale_player_sprites.py             # aplica cambios (crea backups)

Requisitos:
  pip3 install Pillow

Notas:
  - Al 75% NEAREST, cada 4 px de origen → 3 px de salida (sin mezcla).
    El arte queda nítido; nada es borroso. Sin embargo, al no ser escala
    entera (×0.5, ×0.25), se descartan algunas filas/columnas de píxeles.
    Es el trade-off entre automatización y pixel-art puro de redibujado.
  - Los backups se guardan en sprites/<nombre>/backup_pre_rescale/
  - El script es idempotente: volver a correrlo detecta que ya es 128px y salta.
"""

import argparse
import os
import re
import shutil
import sys

try:
    from PIL import Image
except ImportError:
    print("ERROR: Pillow no está instalado. Ejecuta: pip3 install Pillow")
    sys.exit(1)

# ─────────────────────────────────────────────────────────────────────────────
# CONFIGURACIÓN
# ─────────────────────────────────────────────────────────────────────────────
PROJECT_ROOT  = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPRITES_DIR   = os.path.join(PROJECT_ROOT, "sprites")

OLD_W, OLD_H  = 192, 128
NEW_W, NEW_H  = 128, 128

# Origin actual → origin destino
OLD_OX, OLD_OY = 96, 118
NEW_OX, NEW_OY = 64, 118

# Factor de escala: 75% → personaje de ~71px (objetivo 64-72px)
SCALE = 0.75

# Bbox destino (manual, rectángulo — valores del usuario)
NEW_BBOX_L = 48
NEW_BBOX_R = 80
NEW_BBOX_T = 46
NEW_BBOX_B = 118

# Sprites a procesar (en orden de prioridad)
TARGET_SPRITES = [
    "spr_player_idle_master",
    "spr_player_run_start",
    "spr_player_run_loop",
    "spr_player_run_end",
    "spr_player_dash_start",
    "spr_player_dash_loop",
    "spr_player_dash_end",
    "spr_player_jump",
    "spr_player_fall",
    "spr_player_wallslide",
]

# ─────────────────────────────────────────────────────────────────────────────
# GEOMETRÍA DE LA TRANSFORMACIÓN
# ─────────────────────────────────────────────────────────────────────────────
# Tamaño de la imagen escalada al 75%
SCALED_W = int(OLD_W * SCALE)  # 144
SCALED_H = int(OLD_H * SCALE)  # 96

# Offset de pegado: el origin escalado debe quedar en (NEW_OX, NEW_OY)
#   scaled_origin_x = floor(OLD_OX * SCALED_W / OLD_W) = floor(96 * 144/192) = 72
#   scaled_origin_y = floor(OLD_OY * SCALED_H / OLD_H) = floor(118 * 96/128) = 88
#   paste_x = NEW_OX - 72 = 64 - 72 = -8
#   paste_y = NEW_OY - 88 = 118 - 88 = 30
SCALED_OX = OLD_OX * SCALED_W // OLD_W   # 72
SCALED_OY = OLD_OY * SCALED_H // OLD_H   # 88
PASTE_X   = NEW_OX - SCALED_OX           # -8
PASTE_Y   = NEW_OY - SCALED_OY           # 30


# ─────────────────────────────────────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────────────────────────────────────
def transform_frame(src_path: str, dst_path: str, dry_run: bool) -> None:
    """Rescala un PNG de frame y lo escribe en dst_path."""
    img = Image.open(src_path).convert("RGBA")
    w, h = img.size

    if w != OLD_W or h != OLD_H:
        print(f"    [SKIP] {os.path.basename(src_path)} — tamaño inesperado {w}×{h}")
        return

    # 1. Escalar al 75% con NEAREST (sin interpolación)
    try:
        resample = Image.Resampling.NEAREST   # Pillow ≥ 9.1
    except AttributeError:
        resample = Image.NEAREST              # Pillow < 9.1

    scaled = img.resize((SCALED_W, SCALED_H), resample=resample)

    # 2. Canvas destino 128×128 transparente
    canvas = Image.new("RGBA", (NEW_W, NEW_H), (0, 0, 0, 0))

    # 3. Pegar en offset calculado
    canvas.paste(scaled, (PASTE_X, PASTE_Y), scaled)

    if not dry_run:
        canvas.save(dst_path, "PNG", optimize=False)


def update_yy(yy_path: str, dry_run: bool) -> list[str]:
    """Actualiza los metadatos del .yy y retorna lista de cambios aplicados."""
    with open(yy_path, "r", encoding="utf-8") as f:
        content = f.read()

    changes = []
    original = content

    # ── Detectar si ya fue procesado ──────────────────────────────
    if f'"width":{NEW_W}' in content or f'"width": {NEW_W}' in content:
        return ["[YA PROCESADO — sin cambios en .yy]"]

    # ── Dimensiones del canvas ─────────────────────────────────────
    for old, new, label in [
        (f'"width":{OLD_W}',      f'"width":{NEW_W}',      f"width {OLD_W}→{NEW_W}"),
        (f'"width": {OLD_W}',     f'"width": {NEW_W}',     f"width {OLD_W}→{NEW_W}"),
        (f'"seqWidth":{OLD_W}.0', f'"seqWidth":{NEW_W}.0', f"seqWidth {OLD_W}→{NEW_W}"),
        (f'"seqWidth": {OLD_W}.0',f'"seqWidth": {NEW_W}.0',f"seqWidth {OLD_W}→{NEW_W}"),
    ]:
        if old in content:
            content = content.replace(old, new)
            changes.append(label)

    # ── Origin ────────────────────────────────────────────────────
    # xorigin: cualquier valor → 64
    new_content, n = re.subn(r'"xorigin"\s*:\s*\d+', f'"xorigin":{NEW_OX}', content)
    if n > 0:
        content = new_content
        changes.append(f"xorigin →{NEW_OX}")

    # yorigin: cualquier valor → 118 (también corrige los que tienen 128)
    new_content, n = re.subn(r'"yorigin"\s*:\s*\d+', f'"yorigin":{NEW_OY}', content)
    if n > 0:
        content = new_content
        changes.append(f"yorigin →{NEW_OY}")

    # ── Bounding box ──────────────────────────────────────────────
    for key, val in [
        ("bbox_left",   NEW_BBOX_L),
        ("bbox_right",  NEW_BBOX_R),
        ("bbox_top",    NEW_BBOX_T),
        ("bbox_bottom", NEW_BBOX_B),
    ]:
        new_content, n = re.subn(rf'"{key}"\s*:\s*\d+', f'"{key}":{val}', content)
        if n > 0 and new_content != content:
            content = new_content
            changes.append(f"{key} →{val}")

    if content != original and not dry_run:
        with open(yy_path, "w", encoding="utf-8") as f:
            f.write(content)

    return changes if changes else ["(sin cambios)"]


# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────
def main():
    parser = argparse.ArgumentParser(description="Rescala sprites del jugador 192→128px.")
    parser.add_argument("--dry-run", action="store_true",
                        help="Muestra qué haría sin escribir nada.")
    args = parser.parse_args()
    dry = args.dry_run

    if dry:
        print("=" * 60)
        print("  MODO DRY-RUN — no se modifica ningún archivo")
        print("=" * 60)

    total_pngs = 0
    total_sprites = 0

    for spr_name in TARGET_SPRITES:
        spr_dir     = os.path.join(SPRITES_DIR, spr_name)
        layers_dir  = os.path.join(spr_dir, "layers")
        yy_path     = os.path.join(spr_dir, f"{spr_name}.yy")
        backup_dir  = os.path.join(spr_dir, "backup_pre_rescale")

        if not os.path.isdir(spr_dir):
            print(f"\n[NO ENCONTRADO] {spr_name} — saltado")
            continue

        print(f"\n{'─'*55}")
        print(f"  {spr_name}")
        print(f"{'─'*55}")

        # ── Backup ────────────────────────────────────────────────
        if not dry:
            if os.path.isdir(backup_dir):
                print(f"  [BACKUP] Ya existe backup_pre_rescale — no sobreescribir")
            else:
                shutil.copytree(layers_dir, os.path.join(backup_dir, "layers"))
                shutil.copy2(yy_path, backup_dir)
                print(f"  [BACKUP] Creado en backup_pre_rescale/")

        # ── Actualizar .yy ─────────────────────────────────────────
        yy_changes = update_yy(yy_path, dry)
        print(f"  .yy: {', '.join(yy_changes)}")

        # ── Procesar PNGs ──────────────────────────────────────────
        frame_dirs = [
            d for d in os.listdir(layers_dir)
            if os.path.isdir(os.path.join(layers_dir, d))
        ]

        frame_pngs = 0
        for frame_uuid in sorted(frame_dirs):
            frame_path = os.path.join(layers_dir, frame_uuid)
            pngs = [f for f in os.listdir(frame_path) if f.endswith(".png")]
            for png_name in pngs:
                src = os.path.join(frame_path, png_name)
                dst = src   # sobreescribir in-place
                if dry:
                    # Solo verificar tamaño
                    img = Image.open(src)
                    w, h = img.size
                    print(f"    [DRY] frame/{frame_uuid[:8]}…/{png_name[:8]}… — {w}×{h} → {NEW_W}×{NEW_H}")
                else:
                    transform_frame(src, dst, dry_run=False)
                frame_pngs += 1

        print(f"  PNGs procesados: {frame_pngs}")
        total_pngs    += frame_pngs
        total_sprites += 1

    print(f"\n{'='*55}")
    print(f"  TOTAL: {total_sprites} sprites, {total_pngs} PNGs")
    if dry:
        print(f"  (dry-run — ningún archivo modificado)")
        print(f"\n  Para aplicar: python3 tools/rescale_player_sprites.py")
    else:
        print(f"  Completado. Backups en sprites/<nombre>/backup_pre_rescale/")
        print(f"\n  SIGUIENTES PASOS:")
        print(f"  1. Abrir GameMaker y verificar sprites en el IDE")
        print(f"  2. Actualizar scr_config.gml (ver comentario en el script)")
        print(f"  3. Recalibrar wallslide_sprite_offset_x (empezar desde 0)")
        print(f"  4. Ajustar PLAYER_DRAW_OY si el personaje flota o se hunde")
    print(f"{'='*55}\n")


if __name__ == "__main__":
    main()
