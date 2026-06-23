// ── CONTROLES DE ZOOM (desarrollo) ───────────────────────
// En producción usar zoom_to_factor() / zoom_reset() desde scripts de boss.
//
//  base = 960×540, player visual = 150px
//
//  J  → zoom_to_factor(2.0)   vista close:   1920×1080  player 13.9%
//  K  → zoom_to_factor(2.667) vista debug:   2560×1440  player 10.4% (= zoom_reset)
//  L  → zoom_reset()          vista NORMAL:  2560×1440  player 10.4% ← default
//  F6 → zoom_to_factor(3.333) vista boss:    3200×1800  player  8.3%
//  F5 → zoom_to_factor(4.0)   vista ultra:   3840×2160  player  6.9% (extremo)
//
//  Referencia:
//    Mega Man X4 ≈ 9-11%  → el ×2.667 (10.4%) iguala ese feel.
//    Have a Nice Death ≈ 8-9% → el ×3.333 (8.3%) para arenas grandes.

if (keyboard_check_pressed(ord("J"))) {
    zoom_to_factor(2.0);    // 1920×1080 — close, player 13.9%
}

if (keyboard_check_pressed(ord("K"))) {
    zoom_to_factor(2.667);  // 2560×1440 — normal (mismo que zoom_reset)
}

if (keyboard_check_pressed(ord("L"))) {
    zoom_reset();           // 2560×1440 — NORMAL gameplay, player 10.4%
}

if (keyboard_check_pressed(vk_f6)) {
    zoom_to_factor(3.333);  // 3200×1800 — boss/arena, player 8.3%
}

// F7 → toggle debug HUD de cámara en pantalla
if (keyboard_check_pressed(vk_f7)) {
    camera_debug_visible = !camera_debug_visible;
}
