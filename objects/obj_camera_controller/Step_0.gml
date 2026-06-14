// ── CONTROLES DE ZOOM ─────────────────────────────────────
// Temporales para desarrollo. En producción: invocar desde el
// script de cada boss / zona especial en lugar de usar teclado.
//
//  Sprite 256×256, origin=(128,236) → altura visual ~150 px
//  base = 960×540, gameplay_zoom_factor = 1.333
//
//  J → zoom_to_factor(1.0)  zoom in máx:  960×540   personaje 27.8 % (muy cerca, debug)
//  L → zoom_reset()         vista normal: 1280×720  personaje 20.8 % ← default
//  K → zoom_to_factor(1.667) vista boss:  1600×900  personaje 16.7 % (boss/arena)
//
//  Para zoom más específico desde scripts externos:
//    with (obj_camera_controller) { zoom_to_factor(2.0); }   // área enorme 1920×1080
//    with (obj_camera_controller) { zoom_to_size(1920, 1080); }  // mapa completo

if (keyboard_check_pressed(ord("J"))) {
    zoom_to_factor(1.0);   // zoom in debug — 960×540 (pixel-perfect base)
}

if (keyboard_check_pressed(ord("K"))) {
    zoom_to_factor(1.667);  // boss / arena / cinematic — 1600×900 world visible
}

if (keyboard_check_pressed(ord("L"))) {
    zoom_reset();   // gameplay normal — 1280×720 (base × gameplay_zoom_factor)
}

// ── DEBUG DE CÁMARA (tecla P) ─────────────────────────────
// Muestra en consola: vista actual, target, y % de pantalla del player.
// Quitar en producción o dejar — no afecta performance.
if (keyboard_check_pressed(ord("P"))) {
    var _player_visual_h = 150;   // px visible del sprite 256×256
    var _pct = (_player_visual_h / current_camera_height) * 100;
    show_debug_message("=== CAMERA DEBUG ===");
    show_debug_message("  view current : " + string(round(current_camera_width)) + "×" + string(round(current_camera_height)));
    show_debug_message("  view target  : " + string(round(target_camera_width))  + "×" + string(round(target_camera_height)));
    show_debug_message("  zoom factor  : ×" + string_format(current_camera_height / base_camera_height, 1, 3));
    show_debug_message("  player h pct : " + string_format(_pct, 1, 1) + "% of screen height");
    show_debug_message("  cam pos      : (" + string(round(cam_x)) + ", " + string(round(cam_y)) + ")");
}
