// ══════════════════════════════════════════════════════════
// CAMERA CONTROLLER
// Crea y gestiona la cámara GMS2 para este room.
// ══════════════════════════════════════════════════════════

// ── Tamaño base de la vista (en píxeles de mundo) ────────
// 960×540 = 16:9, escala ×2 al port 1920×1080 (pixel-perfect puro).
//   → 1 px de mundo = 2 px en pantalla
//   → personaje 192×128 (visual ~118px) = 21.8% de pantalla a zoom ×1.0
//
// El zoom de GAMEPLAY se aplica sobre este base con gameplay_zoom_factor.
// La vista real durante el juego normal es base × gameplay_zoom_factor.
//
//   ×1.00 = pixel-perfect puro        → 960×540  (personaje 21.8%)
//   ×1.25 = HNAD / Mega Man X4 feel   → 1200×675 (personaje 17.5%) ← default
//   ×1.60 = boss / arena / cinematic  → 1536×864 (personaje 13.7%)
base_camera_width   = GAME_W;   // 960 — desde scr_config
base_camera_height  = GAME_H;   // 540 — desde scr_config

// ── Factor de zoom del gameplay normal ────────────────────
// Estado "en reposo" durante el juego. zoom_reset() vuelve aquí.
// 1.0  = pixel-perfect estricto (personaje grande en pantalla).
// 1.25 = más entorno visible, estilo HNAD / MMX4.
// Aumentar si se quiere ver más nivel. No superar 1.6 sin revisar
// que el room sea suficientemente grande para el clamp de cámara.
gameplay_zoom_factor = 1.25;

// Tamaño actual de la vista (interpolado cada frame por zoom_lerp).
// No modificar directamente — se actualiza solo en End Step.
current_camera_width  = base_camera_width  * gameplay_zoom_factor;   // 1200
current_camera_height = base_camera_height * gameplay_zoom_factor;   // 675

// Tamaño objetivo al que la cámara transiciona.
// Modificar esto para cambiar el zoom dinámicamente.
target_camera_width   = current_camera_width;
target_camera_height  = current_camera_height;

// Velocidad de interpolación del zoom (0.0 = sin movimiento | 1.0 = instantáneo).
// 0.05–0.08: transición suave tipo cinemática (~0.5–1s)
// 0.10–0.15: transición reactiva para combate
zoom_lerp = 0.06;

// ── Crear cámara GMS2 y asignarla al viewport 0 ───────────
cam = camera_create();
camera_set_view_size(cam, base_camera_width, base_camera_height);
camera_set_view_pos(cam, 0, 0);

view_camera[0]  = cam;
view_wport[0]   = DISPLAY_W;   // 1920 — port completo HD
view_hport[0]   = DISPLAY_H;   // 1080
view_xport[0]   = 0;
view_yport[0]   = 0;
view_visible[0] = true;
view_enabled    = true;

// ── Target de seguimiento ─────────────────────────────────
// Se busca automáticamente en el primer End Step.
// Para override manual: cam_controller.target = other_instance_id;
target          = noone;
cam_initialized = false;   // flag para snap inicial (evita zoom-out al arrancar)

// ── Posición actual de la cámara (top-left del mundo) ─────
cam_x = 0;
cam_y = 0;

// ── Suavizado (lerp) ──────────────────────────────────────
// 0.0 = cámara fija | 1.0 = sin suavizado (instantáneo).
// Valores recomendados:
//   0.08–0.10 → suave (Shovel Knight, Celeste)
//   0.12–0.15 → ágil y reactivo (Mega Man X)
lerp_x = 0.12;
lerp_y = 0.10;

// ── Offset del centro de la vista al target ───────────────
// offset_x > 0 → la vista se desplaza a la derecha del jugador
// offset_y < 0 → elevado: muestra más espacio arriba (plataformas, picos)
//
// Con vista de gameplay 1200×675 (base×1.25) y CAM_OFFSET_Y=-50:
//   player aparece a 675/2 + 50 = 387px desde arriba = 57% de pantalla
//   → tercio inferior visible, ~290px de nivel bajo el jugador ✓
offset_x = 0;
offset_y = CAM_OFFSET_Y;   // -50 — desde scr_config

// ── Look-ahead horizontal ─────────────────────────────────
// Desplaza la cámara en la dirección que mira el jugador.
// Futuro: activar cuando exista sprite de run/dash con facing claro.
lookahead_enabled = false;
lookahead_dist    = CAM_LOOKAHEAD;  // 120 px proporcional a 960px de vista — desde scr_config
lookahead_speed   = 0.06;           // velocidad de transición del look-ahead
lookahead_current = 0;      // valor interpolado actual

// ── Offset vertical (aim) ─────────────────────────────────
// Futuro: desplazar vista arriba/abajo al apuntar o caer.
aim_offset_y       = 0;
aim_offset_target  = 0;
aim_offset_speed   = 0.05;

// ── Camera shake ──────────────────────────────────────────
// Activar externamente: with (obj_camera_controller) { do_shake(4, 12); }
shake_intensity = 0;
shake_timer     = 0;
shake_decay     = 0.85;   // factor de decaimiento por frame (0=apagado, 1=constante)
shake_x         = 0;
shake_y         = 0;

do_shake = function(_intensity, _duration) {
    shake_intensity = _intensity;
    shake_timer     = _duration;
};

// ── API de zoom ───────────────────────────────────────────
// Llamar desde cualquier sistema externo para cambiar el zoom.

// Zoom a un factor relativo al tamaño base.
//   factor > 1.0 → zoom out (cámara ve más mundo)
//   factor < 1.0 → zoom in  (cámara ve menos mundo, mayor detalle)
//   factor = 1.0 → tamaño normal
// Ejemplo desde un boss: with (obj_camera_controller) { zoom_to_factor(1.5); }
zoom_to_factor = function(_factor) {
    target_camera_width  = base_camera_width  * _factor;
    target_camera_height = base_camera_height * _factor;
};

// Zoom a dimensiones absolutas en píxeles de mundo.
// Útil cuando una zona del mapa tiene dimensiones específicas.
// Ejemplo: zoom_to_size(640, 360)  → muestra exactamente 640×360 del mundo.
zoom_to_size = function(_width, _height) {
    target_camera_width  = _width;
    target_camera_height = _height;
};

// Restaurar al zoom de gameplay normal (base × gameplay_zoom_factor).
// Esta es la vista "de reposo" durante el juego.
// NO vuelve al pixel-perfect puro (×1.0) — usa gameplay_zoom_factor.
// Para volver al base exacto: zoom_to_factor(1.0).
zoom_reset = function() {
    target_camera_width  = base_camera_width  * gameplay_zoom_factor;
    target_camera_height = base_camera_height * gameplay_zoom_factor;
};

// Cambiar velocidad de transición sin afectar el target.
// Útil para hacer una transición lenta (cinemática) vs rápida (combate).
zoom_set_speed = function(_speed) {
    zoom_lerp = _speed;
};

// ── Límites del room (clamp) ──────────────────────────────
// bounds_* pueden sobreescribirse para boss rooms o secciones de scroll fijo.
// Ejemplo: bounds_right = 640 → la cámara no avanza más allá de x=640.
bounds_left   = 0;
bounds_top    = 0;
bounds_right  = room_width;
bounds_bottom = room_height;
