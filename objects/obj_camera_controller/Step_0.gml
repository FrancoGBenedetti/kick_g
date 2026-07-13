// ── CONTROLES DE ZOOM ─────────────────────────────────────
//
//  K → alejar (zoom out) — sube un nivel: CLOSE→DEFAULT→FAR
//  L → acercar (zoom in) — baja un nivel: FAR→DEFAULT→CLOSE
//
//  Secuencia:  CLOSE ←→ DEFAULT ←→ FAR
//              (0)        (1)       (2)
//
//  F7 → toggle debug HUD de cámara

if (keyboard_check_pressed(ord("K"))) {
    camera_zoom_step_out();   // aleja
}

if (keyboard_check_pressed(ord("L"))) {
    camera_zoom_step_in();    // acerca
}

if (keyboard_check_pressed(vk_f7)) {
    camera_debug_visible = !camera_debug_visible;
}
