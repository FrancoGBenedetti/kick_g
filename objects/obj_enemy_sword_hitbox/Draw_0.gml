// ══════════════════════════════════════════════════════════
// OBJ_ENEMY_SWORD_HITBOX — Draw
// Visualización de debug de la hitbox de espada enemiga.
//
// Solo dibuja cuando alguno de estos toggles está activo:
//   F8 → global.debug_hitboxes      : todas las hitboxes (bbox + team + parry)
//   F3 → global.debug_enemy_attacks : toggle específico de ataques de enemigos
//
// En producción: reemplazar por instancia de efecto visual (chispa, brillo de espada)
// que viva los mismos frames que la hitbox activa. Este Draw se elimina entonces.
// ══════════════════════════════════════════════════════════
var _dbg_hitbox = variable_global_exists("debug_hitboxes")      && global.debug_hitboxes;
var _dbg_enemy  = variable_global_exists("debug_enemy_attacks") && global.debug_enemy_attacks;
if (!_dbg_hitbox && !_dbg_enemy) exit;

var _dc = draw_get_color();
var _da = draw_get_alpha();

var _x1 = x - hitbox_w * 0.5;
var _y1 = y - hitbox_h * 0.5;
var _x2 = x + hitbox_w * 0.5;
var _y2 = y + hitbox_h * 0.5;

// Relleno: rojo (TEAM_ENEMY melee)
draw_set_color(make_color_rgb(220, 40, 40));
draw_set_alpha(0.25);
draw_rectangle(_x1, _y1, _x2, _y2, false);

// Borde sólido
draw_set_color(make_color_rgb(255, 80, 80));
draw_set_alpha(0.85);
draw_rectangle(_x1, _y1, _x2, _y2, true);

// Cruz en el centro
draw_set_alpha(0.7);
draw_line(x - 4, y, x + 4, y);
draw_line(x, y - 4, x, y + 4);

// ── Metadatos (solo debug_hitboxes) ──────────────────────
// Muestra: tipo, parry flag, team, daño, owner.
if (_dbg_hitbox) {
    draw_set_alpha(1.0);
    draw_set_color(c_white);
    draw_set_halign(fa_center);
    draw_set_valign(fa_bottom);
    var _own = instance_exists(owner) ? object_get_name(owner.object_index) : "?";
    var _lbl = "ENEMY_SWORD"
             + "  D:" + string(damage)
             + "  T:" + string(team)
             + "\n[Parry:" + (can_be_parried ? "Y" : "N") + "]"
             + "  " + _own;
    draw_text(x, _y1 - 2, _lbl);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}

draw_set_color(_dc);
draw_set_alpha(_da);
