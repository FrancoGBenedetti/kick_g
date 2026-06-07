// ══════════════════════════════════════════════════════════
// OBJ_ENEMY_ARCHER — Draw
// Dibuja el sprite normal y superpone info de debug cuando
// global.debug_enemy_attacks está activo (toggle con F3).
//
//   AIM → línea amarilla desde el punto de disparo hacia
//         la dirección exacta en que saldrá la flecha.
// ══════════════════════════════════════════════════════════
draw_self();

if (!global.debug_enemy_attacks) exit;
if (estate != ESTATE_AIM) exit;

// ── Origen del disparo ────────────────────────────────────
// Offset fijo desde el centro del sprite. Ajustar si el sprite cambia.
var _ox  = x + facing * 16;
var _oy  = y - 16;

// ── Dirección de la flecha ─────────────────────────────────
var _rad = degtorad(aim_angle);
var _len = 90;
var _ex  = _ox + facing * _len * cos(_rad);
var _ey  = _oy + _len * sin(_rad);

// ── Línea y punto de origen ────────────────────────────────
draw_set_alpha(0.8);
draw_set_color(c_yellow);
draw_line_width(_ox, _oy, _ex, _ey, 3);
draw_circle(_ox, _oy, 4, false);

// ── Reset render state ────────────────────────────────────
draw_set_alpha(1.0);
draw_set_color(c_white);

// ── Debug de separación/contacto (desde parent) ───────────
// El parent draw solo actúa si global.debug_enemy_collision = true.
event_inherited();
