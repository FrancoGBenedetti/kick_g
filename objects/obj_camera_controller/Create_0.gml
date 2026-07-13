// ══════════════════════════════════════════════════════════
// CAMERA CONTROLLER — Create
//
// Sistema de cámara centralizado con 3 vistas:
//   CLOSE   (960×540)  — acción / zoom in
//   DEFAULT (1152×648) — gameplay normal  ← inicio
//   FAR     (1280×720) — boss / zoom out
//
// Cambiar vista: K (alejar) / L (acercar)
// API externa: with (obj_camera_controller) { camera_set_view_mode(CameraViewMode.FAR); }
// ══════════════════════════════════════════════════════════

// ── Vista activa (índice numérico para poder hacer ±1) ────
// 0 = CLOSE | 1 = DEFAULT | 2 = FAR
camera_view_index = 1;   // inicia en DEFAULT

// ── Tamaño actual (interpolado por lerp cada frame) ───────
current_camera_width  = CAM_VIEW_DEFAULT_W;   // 1792
current_camera_height = CAM_VIEW_DEFAULT_H;   // 1008

// ── Tamaño objetivo (camera_set_view_mode escribe aquí) ───
target_camera_width  = current_camera_width;
target_camera_height = current_camera_height;

// ── Velocidad de interpolación de zoom ────────────────────
// 0.08 → transición suave (~0.5-1s)
// 0.12 → más reactivo
zoom_lerp = 0.08;

// ── Crear cámara GMS2 y asignarla al viewport 0 ───────────
cam = camera_create();
// Aplicar vista DEFAULT inmediatamente (sin lerp) para que el
// primer frame ya muestre el tamaño correcto.
camera_set_view_size(cam, current_camera_width, current_camera_height);
camera_set_view_pos(cam, 0, 0);

view_camera[0]  = cam;
view_wport[0]   = DISPLAY_W;   // 1920
view_hport[0]   = DISPLAY_H;   // 1080
view_xport[0]   = 0;
view_yport[0]   = 0;
view_visible[0] = true;
view_enabled    = true;

// ── Target de seguimiento ─────────────────────────────────
target          = noone;
cam_initialized = false;

// ── Posición actual de la cámara (top-left del mundo) ─────
cam_x = 0;
cam_y = 0;

// ── Suavizado de posición ─────────────────────────────────
lerp_x = 0.12;
lerp_y = 0.10;

// ── Offset del centro de la vista al target ───────────────
// CAM_OFFSET_Y = -80 → player a 62% desde arriba en vista 648px
offset_x = 0;
offset_y = CAM_OFFSET_Y;

// ── Look-ahead horizontal ─────────────────────────────────
lookahead_enabled = false;
lookahead_dist    = CAM_LOOKAHEAD;
lookahead_speed   = 0.06;
lookahead_current = 0;

// ── Offset vertical (aim) ─────────────────────────────────
aim_offset_y       = 0;
aim_offset_target  = 0;
aim_offset_speed   = 0.05;

// ── Camera shake ──────────────────────────────────────────
shake_intensity = 0;
shake_timer     = 0;
shake_decay     = 0.85;
shake_x         = 0;
shake_y         = 0;

do_shake = function(_intensity, _duration) {
    shake_intensity = _intensity;
    shake_timer     = _duration;
};

// ── API principal: cambiar modo de cámara ─────────────────
// _mode    : CameraViewMode.CLOSE / DEFAULT / FAR
// _instant : true = sin lerp (para iniciar rooms sin barrido)
//
// Uso externo:
//   with (obj_camera_controller) { camera_set_view_mode(CameraViewMode.FAR); }
//   with (obj_camera_controller) { camera_set_view_mode(CameraViewMode.DEFAULT, true); }
camera_set_view_mode = function(_mode, _instant = false) {
    camera_view_index = _mode;
    var _w, _h;
    switch (_mode) {
        case CameraViewMode.CLOSE:
            _w = CAM_VIEW_CLOSE_W;    // 960
            _h = CAM_VIEW_CLOSE_H;    // 540
        break;
        case CameraViewMode.FAR:
            _w = CAM_VIEW_FAR_W;      // 1280
            _h = CAM_VIEW_FAR_H;      // 720
        break;
        default: // CameraViewMode.DEFAULT
            _w = CAM_VIEW_DEFAULT_W;  // 1152
            _h = CAM_VIEW_DEFAULT_H;  // 648
        break;
    }
    target_camera_width  = _w;
    target_camera_height = _h;
    if (_instant) {
        current_camera_width  = _w;
        current_camera_height = _h;
        camera_set_view_size(cam, _w, _h);
    }
};

// ── Zoom step: aleja un nivel (K) ─────────────────────────
camera_zoom_step_out = function() {
    var _next = clamp(camera_view_index + 1, 0, 2);
    if (_next != camera_view_index) {
        camera_set_view_mode(_next);
        show_debug_message("[CAMERA] → " + ["CLOSE","DEFAULT","FAR"][_next]);
    }
};

// ── Zoom step: acerca un nivel (L) ────────────────────────
camera_zoom_step_in = function() {
    var _next = clamp(camera_view_index - 1, 0, 2);
    if (_next != camera_view_index) {
        camera_set_view_mode(_next);
        show_debug_message("[CAMERA] → " + ["CLOSE","DEFAULT","FAR"][_next]);
    }
};

// ── Zoom a dimensiones absolutas (uso avanzado) ───────────
zoom_to_size = function(_width, _height) {
    target_camera_width  = _width;
    target_camera_height = _height;
};

// ── Restaurar a DEFAULT ───────────────────────────────────
zoom_reset = function() {
    camera_set_view_mode(CameraViewMode.DEFAULT);
};

// ── Límites del room ──────────────────────────────────────
bounds_left   = 0;
bounds_top    = 0;
bounds_right  = room_width;
bounds_bottom = room_height;

// ── Override de bounds (usado por BattleRoom para limitar la cámara
// a una arena más chica que el room completo) ─────────────
// Mientras camera_bounds_override_enabled == true, Step_2.gml usa
// camera_bounds_left/top/right/bottom en vez de recalcular bounds_right/
// bounds_bottom desde room_width/room_height cada frame.
camera_bounds_override_enabled = false;
camera_bounds_left   = 0;
camera_bounds_top    = 0;
camera_bounds_right  = 0;
camera_bounds_bottom = 0;

// ── API: activar/desactivar el override de bounds ─────────
// Uso externo (igual patrón que camera_set_view_mode):
//   with (obj_camera_controller) { camera_set_bounds_override(a,b,c,d); }
//   with (obj_camera_controller) { camera_clear_bounds_override(); }
camera_set_bounds_override = function(_left, _top, _right, _bottom) {
    if (_right <= _left || _bottom <= _top) {
        show_debug_message("[CAMERA WARNING] Invalid override bounds — ignored.");
        return;
    }

    camera_bounds_override_enabled = true;
    camera_bounds_left   = _left;
    camera_bounds_top    = _top;
    camera_bounds_right  = _right;
    camera_bounds_bottom = _bottom;

    if ((_right - _left) < current_camera_width || (_bottom - _top) < current_camera_height) {
        show_debug_message("[CAMERA WARNING] Arena bounds smaller than camera view.");
        // No es un error — Step_2 ya clampea de forma segura (la vista
        // simplemente muestra un poco más que la arena). Solo se avisa.
    }

    show_debug_message("[CAMERA] bounds override enabled");
    show_debug_message("[CAMERA] override bounds: " + string(_left) + "/" + string(_top) + "/" + string(_right) + "/" + string(_bottom));
};

camera_clear_bounds_override = function() {
    camera_bounds_override_enabled = false;
    show_debug_message("[CAMERA] bounds override disabled");
};

// ── Debug HUD ─────────────────────────────────────────────
// F7 → toggle. true = visible al arrancar para validar zoom.
camera_debug_visible = true;
