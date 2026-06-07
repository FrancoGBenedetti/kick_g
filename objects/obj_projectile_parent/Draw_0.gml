// ══════════════════════════════════════════════════════════
// OBJ_PROJECTILE_PARENT — Draw
// Debug visual para proyectiles. Solo activo cuando:
//   global.debug_projectiles = true
//
// Los hijos que tienen su propio visual (sprite o draw manual)
// deben llamar event_inherited() en su Draw para incluir este
// debug encima de su visual propio.
//
// Muestra:
//   • Vector de velocidad (amarillo) escalado x4
//   • Bbox de detección hit_radius (verde semitransparente)
//   • Flags activos: [P] parriable | [B] bloqueable |
//                    [S] destruible por espada | [!] unbreakable
// ══════════════════════════════════════════════════════════
var _dbg_proj   = variable_global_exists("debug_projectiles") && global.debug_projectiles;
var _dbg_hitbox = variable_global_exists("debug_hitboxes")    && global.debug_hitboxes;
if (!_dbg_proj && !_dbg_hitbox) exit;

var _dc = draw_get_color();
var _da = draw_get_alpha();

// ── Vector de velocidad ───────────────────────────────────
draw_set_color(c_yellow);
draw_set_alpha(0.85);
var _scale = 4.0;
draw_line_width(x, y, x + vel_x * _scale, y + vel_y * _scale, 2);

// ── Hit radius (bbox de detección) ───────────────────────
draw_set_color(c_lime);
draw_set_alpha(0.20);
draw_rectangle(x - hit_radius, y - hit_radius, x + hit_radius, y + hit_radius, false);
draw_set_alpha(0.80);
draw_rectangle(x - hit_radius, y - hit_radius, x + hit_radius, y + hit_radius, true);

// ── Indicadores de flags ──────────────────────────────────
draw_set_alpha(1.0);
draw_set_color(c_white);
var _flags = "";
if (can_be_parried)            _flags += "[P]";
if (can_be_blocked)            _flags += "[B]";
if (can_be_destroyed_by_sword) _flags += "[S]";
if (is_unbreakable)            _flags += "[!]";
if (team == TEAM_ENEMY)        _flags += " E";
if (team == TEAM_PLAYER)       _flags += " P";
if (_flags != "") {
    draw_text(x + hit_radius + 3, y - 8, _flags);
}

// ── Lifetime restante ─────────────────────────────────────
draw_set_color(make_color_rgb(200, 200, 200));
draw_text(x + hit_radius + 3, y + 2, string(lifetimeTimer));

// ── Tipo de objeto (solo debug_hitboxes) ─────────────────
if (_dbg_hitbox) {
    draw_set_color(c_white);
    draw_set_halign(fa_center);
    draw_set_valign(fa_bottom);
    draw_text(x, y - hit_radius - 2,
        object_get_name(object_index) + "  D:" + string(damage));
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}

draw_set_color(_dc);
draw_set_alpha(_da);
