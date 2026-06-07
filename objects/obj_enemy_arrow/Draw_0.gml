// ══════════════════════════════════════════════════════════
// OBJ_ENEMY_ARROW — Draw
// Visual placeholder (rombo naranja) + debug heredado.
//
// Siempre visible: rombo naranja de 5 px.
// event_inherited(): activa el debug del parent (vector, bbox,
//   flags [P][B][S]) solo si global.debug_projectiles = true.
// debug_enemy_attacks: mantiene el vector legado para compat.
//
// Reemplazar el rombo cuando exista spr_enemy_arrow:
//   draw_sprite_ext(spr_enemy_arrow, 0, x, y,
//       1, 1, image_angle, c_white, 1);
// ══════════════════════════════════════════════════════════

// ── Placeholder visual ────────────────────────────────────
draw_set_color(c_orange);
draw_set_alpha(1.0);
var _r = 5;
draw_triangle(x, y - _r, x + _r, y, x - _r, y, false);
draw_triangle(x, y + _r, x + _r, y, x - _r, y, false);

// ── Debug del parent (vector + bbox + flags) ──────────────
// Solo se dibuja si global.debug_projectiles = true.
event_inherited();

// ── Debug legado: vector de velocidad ─────────────────────
// Mantenido para compatibilidad con global.debug_enemy_attacks.
// Consolidar con debug_projectiles cuando se estandarice el sistema.
if (!variable_global_exists("debug_enemy_attacks") || !global.debug_enemy_attacks) {
    draw_set_color(c_white);
    draw_set_alpha(1.0);
    exit;
}

draw_set_color(c_yellow);
draw_set_alpha(0.85);
draw_line_width(x, y, x + vel_x * 3.0, y + vel_y * 3.0, 2);

draw_set_alpha(1.0);
draw_set_color(c_white);
