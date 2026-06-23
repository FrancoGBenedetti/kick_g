// ══════════════════════════════════════════════════════════
// OBJ_SWORD_HITBOX — Draw
// Visualización de debug de la hitbox de espada del jugador.
//
// Dibuja siempre que alguno de estos esté activo:
//   5 → global.debug_dev        : modo dev (muestra todo)
//   F8 → global.debug_hitboxes  : todas las hitboxes (bbox + team + parry)
//   F7 → global.debug_attack    : toggle específico de espada del jugador
//
// En producción (sin sprite de slash todavía):
//   • Asignar spr_slash al spawnear:  sprite_index = spr_slash
//   • image_xscale = owner.facing     (voltear según dirección)
//   • image_speed  = 1
//   • Mover la destrucción al Animation End Event en lugar de lifetime.
//   • Eliminar este evento Draw una vez que exista el visual real.
// ══════════════════════════════════════════════════════════
var _dbg_dev = variable_global_exists("debug_dev") && global.debug_dev;
var _dbg_hitbox = variable_global_exists("debug_hitboxes") && global.debug_hitboxes;
var _dbg_attack = variable_global_exists("debug_attack")   && global.debug_attack;
if (!_dbg_dev && !_dbg_hitbox && !_dbg_attack) exit;

var _dc = draw_get_color();
var _da = draw_get_alpha();

var _x1 = x - hitbox_w * 0.5;
var _y1 = y - hitbox_h * 0.5;
var _x2 = x + hitbox_w * 0.5;
var _y2 = y + hitbox_h * 0.5;

// Relleno: amarillo claro (TEAM_PLAYER melee — igual que estilo enemigos)
draw_set_color(c_yellow);
draw_set_alpha(0.35);
draw_rectangle(_x1, _y1, _x2, _y2, false);

// Borde sólido amarillo fuerte
draw_set_color(c_yellow);
draw_set_alpha(0.9);
draw_rectangle(_x1, _y1, _x2, _y2, true);

// Cruz en el centro
draw_set_alpha(0.7);
draw_line(x - 4, y, x + 4, y);
draw_line(x, y - 4, x, y + 4);

// ── Metadatos ───────────────────────────────────────────
draw_set_alpha(1.0);
draw_set_color(c_white);
draw_set_halign(fa_center);
draw_set_valign(fa_bottom);
var _lbl = (is_pogo ? "[POGO]" : "[SWORD]")
         + " DMG:" + string(damage)
         + " W:" + string(hitbox_w)
         + " H:" + string(hitbox_h);
draw_text(x, _y1 - 8, _lbl);
draw_set_halign(fa_left);
draw_set_valign(fa_top);

draw_set_color(_dc);
draw_set_alpha(_da);
