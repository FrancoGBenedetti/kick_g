// End Step — corre DESPUÉS de que todos los objetos hayan movido este frame.
// NO respeta global.do_step: la cámara siempre interpola cada real-frame
// para garantizar seguimiento visual fluido incluso durante slow motion.

// ── Buscar target si no está asignado o fue destruido ─────
if (!instance_exists(target)) {
    target = instance_find(obj_player, 0);
    if (!instance_exists(target)) exit;   // sin jugador: no actualizar cámara
}

// ── Actualizar límites del room ───────────────────────────
// Si hay un override activo (BattleRoom limitando la cámara a una arena),
// el TARGET es esos bounds; si no, el target es el room completo (mismo
// comportamiento de siempre: bounds_right/bounds_bottom recalculados cada
// frame por si el room cambia dinámicamente). En vez de asignar el target
// de golpe, se interpola desde bounds_from_* durante
// bounds_transition_timer frames (arrancado por camera_set_bounds_override/
// camera_clear_bounds_override) — evita el salto brusco de cámara al
// activar/desactivar el lock de una BattleRoom.
var _target_bounds_left, _target_bounds_top, _target_bounds_right, _target_bounds_bottom;

if (camera_bounds_override_enabled) {
    _target_bounds_left   = camera_bounds_left;
    _target_bounds_top    = camera_bounds_top;
    _target_bounds_right  = camera_bounds_right;
    _target_bounds_bottom = camera_bounds_bottom;
} else {
    _target_bounds_left   = 0;
    _target_bounds_top    = 0;
    _target_bounds_right  = room_width;
    _target_bounds_bottom = room_height;
}

if (bounds_transition_timer > 0) {
    var _bt = 1 - (bounds_transition_timer / bounds_transition_duration);
    bounds_left   = lerp(bounds_from_left,   _target_bounds_left,   _bt);
    bounds_top    = lerp(bounds_from_top,    _target_bounds_top,    _bt);
    bounds_right  = lerp(bounds_from_right,  _target_bounds_right,  _bt);
    bounds_bottom = lerp(bounds_from_bottom, _target_bounds_bottom, _bt);
    bounds_transition_timer--;
} else {
    bounds_left   = _target_bounds_left;
    bounds_top    = _target_bounds_top;
    bounds_right  = _target_bounds_right;
    bounds_bottom = _target_bounds_bottom;
}

// ── Zoom: interpolación de dimensiones ────────────────────
// current → target a ritmo de zoom_lerp, independiente del time_scale del juego.
// Aumentar target = zoom out (más mundo visible).
// Reducir target  = zoom in  (menos mundo, más detalle).
current_camera_width  = lerp(current_camera_width,  target_camera_width,  zoom_lerp);
current_camera_height = lerp(current_camera_height, target_camera_height, zoom_lerp);
var _eff_w = current_camera_width;
var _eff_h = current_camera_height;
camera_set_view_size(cam, _eff_w, _eff_h);

// ── Look-ahead horizontal ─────────────────────────────────
var _la_target = 0;
if (lookahead_enabled) {
    _la_target = target.facing * lookahead_dist;
}
lookahead_current = lerp(lookahead_current, _la_target, lookahead_speed);

// ── Offset vertical de apuntado (aim) ─────────────────────
aim_offset_y = lerp(aim_offset_y, aim_offset_target, aim_offset_speed);

// ── Posición objetivo (centro del mundo que debe estar en el centro de la vista) ─
var _target_cx = target.x + offset_x + lookahead_current;
var _target_cy = target.y + offset_y + aim_offset_y;

// Convertir centro → top-left de la vista
var _dest_x = _target_cx - _eff_w * 0.5;
var _dest_y = _target_cy - _eff_h * 0.5;

// ── Lerp ──────────────────────────────────────────────────
if (!cam_initialized) {
    // Primer frame: snap instantáneo para evitar barrido de pantalla al arrancar
    cam_x = _dest_x;
    cam_y = _dest_y;
    cam_initialized = true;
} else {
    cam_x = lerp(cam_x, _dest_x, lerp_x);
    cam_y = lerp(cam_y, _dest_y, lerp_y);
}

// ── Clamp a límites del room ──────────────────────────────
// max(..., bounds_left) protege si el room es más pequeño que la vista.
cam_x = clamp(cam_x, bounds_left, max(bounds_left,  bounds_right  - _eff_w));
cam_y = clamp(cam_y, bounds_top,  max(bounds_top,   bounds_bottom - _eff_h));

// ── Camera shake ──────────────────────────────────────────
shake_x = 0;
shake_y = 0;
if (shake_timer > 0) {
    shake_timer--;
    shake_x = random_range(-shake_intensity, shake_intensity);
    shake_y = random_range(-shake_intensity, shake_intensity);
    shake_intensity *= shake_decay;   // decaimiento progresivo
    if (shake_intensity < 0.5) {
        shake_intensity = 0;
        shake_timer     = 0;
    }
}

// ── Aplicar posición final a la cámara GMS2 ───────────────
camera_set_view_pos(cam, cam_x + shake_x, cam_y + shake_y);
