// ── CONTROLES DE ZOOM ─────────────────────────────────────
// Temporales para desarrollo. En producción: invocar desde el
// script de cada boss / zona especial en lugar de usar teclado.
//
//  Sprite 256×256, origin=(128,236) → altura visual ~150 px (estándar 256×256)
//  base = 960×540, gameplay_zoom_factor = 1.25
//
//  L → zoom_reset()         vista gameplay: 1200×675  personaje 22.2 %
//                           (equivale a gameplay_zoom_factor × base)
//
//  K → zoom_to_factor(1.6)  vista boss:    1536×864   personaje 17.4 %
//                           boss arenas, revelaciones, enemigos gigantes
//
//  Para zoom más específico desde scripts externos:
//    with (obj_camera_controller) { zoom_to_factor(1.8); }   // área enorme
//    with (obj_camera_controller) { zoom_to_size(1920, 1080); }  // mapa completo

if (keyboard_check_pressed(ord("K"))) {
    zoom_to_factor(1.6);   // boss / arena / cinematic — 1536×864 world visible
}

if (keyboard_check_pressed(ord("L"))) {
    zoom_reset();   // gameplay normal — 1200×675 (base × gameplay_zoom_factor)
}
