// ══════════════════════════════════════════════════════════
// OBJ_ENEMY_ARCHER — Draw
// Dibuja el sprite normal y superpone info de debug cuando
// global.debug_enemy_attacks está activo (toggle con F3).
//
//   AIM → línea amarilla desde el punto de disparo hacia
//         la dirección exacta en que saldrá la flecha.
// ══════════════════════════════════════════════════════════
draw_self();

// Mostrar debug si: global.debug_dev (modo dev) O global.debug_enemy_attacks (F3)
var _show_debug = (variable_global_exists("debug_dev") && global.debug_dev) || global.debug_enemy_attacks;
if (!_show_debug) exit;
if (estate != ESTATE_AIM) exit;

// ── Origen del disparo usando los offsets configurables ─────
var _ox  = x + (facing > 0 ? col_right + projectile_spawn_offset_x : col_left - projectile_spawn_offset_x);
var _oy  = y + projectile_spawn_offset_y;

// ── Dirección de la flecha ─────────────────────────────────
var _rad = degtorad(aim_angle);
var _len = 90;
var _ex  = _ox + facing * _len * cos(_rad);
var _ey  = _oy + _len * sin(_rad);

// ── Línea y punto de origen ────────────────────────────────
draw_set_alpha(0.8);
draw_set_color(c_yellow);
draw_line_width(_ox, _oy, _ex, _ey, 3);
draw_circle(_ox, _oy, 6, false);   // círculo del spawn

// ── Punto de referencia del cuerpo (para comparar) ─────────
draw_set_color(c_aqua);
draw_set_alpha(0.4);
draw_circle(x, y, 3, false);

// ── Reset render state ────────────────────────────────────
draw_set_alpha(1.0);
draw_set_color(c_white);

// ── Debug de separación/contacto (desde parent) ───────────
// El parent draw solo actúa si global.debug_enemy_collision = true.
event_inherited();
