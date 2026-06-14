// ── CONTROLES DE ZOOM (desarrollo) ───────────────────────
// En producción usar zoom_to_factor() / zoom_reset() desde scripts de boss.
//
//  base = 960×540, player visual = 150px
//
//  J  → zoom_to_factor(1.0)  vista close:   960×540   player 27.8 % (debug)
//  K  → zoom_to_factor(1.5)  vista media:   1440×810  player 18.5 % (combate)
//  L  → zoom_reset()         vista normal:  1920×1080 player 13.9 % ← default
//  F6 → zoom_to_factor(2.5)  vista boss:    2400×1350 player 11.1 % (boss/arena)
//
//  Referencia: sprite 128×128 (72px visual) en 960×540 → 13.3% — la "L" iguala ese feel.

if (keyboard_check_pressed(ord("J"))) {
    zoom_to_factor(1.0);   // 960×540 — muy cerca, player 27.8%
}

if (keyboard_check_pressed(ord("K"))) {
    zoom_to_factor(1.5);   // 1440×810 — intermedio, player 18.5%
}

if (keyboard_check_pressed(ord("L"))) {
    zoom_reset();          // 1920×1080 — normal gameplay, player 13.9%
}

if (keyboard_check_pressed(vk_f6)) {
    zoom_to_factor(2.5);   // 2400×1350 — boss/arena alejado, player 11.1%
}

// F7 → toggle debug HUD de cámara en pantalla
if (keyboard_check_pressed(vk_f7)) {
    camera_debug_visible = !camera_debug_visible;
}
