// ══════════════════════════════════════════════════════════
// OBJ_PLAYER — Draw GUI
// Dibuja la interfaz fija del jugador en screen-space.
// El evento Draw GUI corre DESPUÉS del Draw normal y en un
// sistema de coordenadas propio (0,0 = esquina superior izquierda
// de la pantalla, independiente de la cámara).
//
// Contenido actual:
//   • Barra de vida y maná en la esquina superior izquierda.
//   • Icono fijo de flechas y munición actual.
//
// Futuro:
//   • Icono de dash disponible
//   • Indicador de carga del arco
// ══════════════════════════════════════════════════════════

// ── Parámetros de posición y tamaño ──────────────────────
// Escalado para puerto 1920×1080. Ajustar si cambia DISPLAY_W/H.
var _bar_x = 48;
var _bar_y = 48;
var _bar_w = 300;
var _bar_h = 28;
var _mana_y = _bar_y + _bar_h + 8;

// ── Borde exterior de la barra ────────────────────────────
var _prev_color = draw_get_color();
var _prev_alpha = draw_get_alpha();

draw_set_alpha(0.85);
draw_set_color(c_black);
draw_rectangle(_bar_x - 2, _bar_y - 2, _bar_x + _bar_w + 2, _bar_y + _bar_h + 2, true);

// ── Barra de vida ─────────────────────────────────────────
// Colores: fondo rojo oscuro | relleno rojo saturado
scr_draw_healthbar(
    _bar_x, _bar_y,
    _bar_w, _bar_h,
    health, max_health,
    make_color_rgb( 50,  10,  10),   // fondo — rojo muy oscuro
    make_color_rgb(220,  40,  40)    // relleno — rojo
);

// ── Texto HP ──────────────────────────────────────────────
// Dibujado encima de la barra — siempre legible en blanco.
draw_set_alpha(1);
draw_set_color(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_middle);
draw_text(_bar_x + 6, _bar_y + _bar_h * 0.5,
          "HP  " + string(health) + " / " + string(max_health));

// ── Barra de maná ────────────────────────────────────────
// Comparte posición, ancho y borde con HP para leerse como un solo HUD.
draw_set_alpha(0.85);
draw_set_color(c_black);
draw_rectangle(_bar_x - 2, _mana_y - 2, _bar_x + _bar_w + 2, _mana_y + _bar_h + 2, true);

scr_draw_healthbar(
    _bar_x, _mana_y,
    _bar_w, _bar_h,
    mana, max_mana,
    make_color_rgb( 8,  18,  55),   // fondo azul oscuro
    make_color_rgb(35, 100, 235)    // relleno azul
);

draw_set_alpha(1);
draw_set_color(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_middle);
draw_text(_bar_x + 6, _mana_y + _bar_h * 0.5,
          "MP  " + string(mana) + " / " + string(max_mana));

// ── Flechas ──────────────────────────────────────────────
// El mismo arte del pickup se usa como icono fijo de inventario.
var _arrow_icon_x = _bar_x + _bar_w + 34;
var _arrow_icon_y = _mana_y + _bar_h;
var _arrow_color = arrows < ARROW_COST ? c_red : c_white;

draw_set_alpha(1);
draw_set_color(c_white);
draw_sprite_ext(spr_pickup_arrows, 0, _arrow_icon_x, _arrow_icon_y,
                0.06, 0.06, 0, c_white, 1);

draw_set_color(c_black);
draw_set_halign(fa_left);
draw_set_valign(fa_middle);
draw_text(_arrow_icon_x + 30, _arrow_icon_y - 18, "x " + string(arrows));
draw_set_color(_arrow_color);
draw_text(_arrow_icon_x + 29, _arrow_icon_y - 19, "x " + string(arrows));

// ── Restaurar estado de render ────────────────────────────
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(_prev_color);
draw_set_alpha(_prev_alpha);

// ── DEBUG DE MOVIMIENTO (F8) ──────────────────────────────
// Muestra valores de física/estado del player en pantalla.
// Activar/desactivar con F8 en Step_0. Quitar en producción.
if (!player_debug_visible) exit;

var _state_name = "";
switch (player_state) {
    case PSTATE.IDLE:       _state_name = "IDLE";       break;
    case PSTATE.RUN:        _state_name = "RUN";        break;
    case PSTATE.JUMP:       _state_name = "JUMP";       break;
    case PSTATE.FALL:       _state_name = "FALL";       break;
    case PSTATE.WALL:       _state_name = "WALL";       break;
    case PSTATE.DASH:       _state_name = "DASH";       break;
    case PSTATE.ATTACK_1:   _state_name = "ATTACK_1";   break;
    case PSTATE.ATTACK_2:   _state_name = "ATTACK_2";   break;
    case PSTATE.ATTACK_3:   _state_name = "ATTACK_3";   break;
    case PSTATE.DOWN_SLASH: _state_name = "DOWN_SLASH"; break;
    case PSTATE.BLOCK:      _state_name = "BLOCK";      break;
    default:                _state_name = "?" + string(player_state); break;
}

var _lines = [
    "=== PLAYER DEBUG (F8) ===",
    "state      : " + _state_name,
    "grounded   : " + string(isGrounded),
    "hsp (vel_x): " + string_format(vel_x, 1, 2) + "  (move_x=" + string_format(move_x, 1, 2) + ")",
    "vsp (move_y): " + string_format(move_y, 1, 2),
    "",
    "max_walk   : " + string(max_walk_speed) + "  (era 4)",
    "jump_speed : " + string(jump_speed)     + "  (era -10)",
    "grav       : " + string(grav)           + "  (era 0.5)",
    "max_fall   : " + string(max_fall)       + "  (era 14)",
    "dash_speed : " + string(dash_speed)     + "  (era 10)",
    "dash_timer : " + string(dashTimer),
    "dash_jump  : " + string(dash_jump_active),
    "can_airdash: " + string(can_air_dash),
    "",
    "── Afterimage ──",
    "enabled    : " + string(afterimage_enabled),
    "active imgs: " + string(instance_number(obj_dash_afterimage)),
    "spawn_rate : " + string(afterimage_spawn_rate) + "f",
    "alpha_start: " + string_format(afterimage_alpha_start, 1, 2),
    "fade_speed : " + string_format(afterimage_fade_speed,  1, 3)
        + "  (vida ~" + string(round(afterimage_alpha_start / afterimage_fade_speed)) + "f)",
    "max        : " + string(afterimage_max),
];

draw_set_font(-1);
draw_set_halign(fa_left);
draw_set_valign(fa_top);

var _x  = 12;
var _y  = 100;   // debajo del HP bar
var _lh = 18;

for (var _i = 0; _i < array_length(_lines); _i++) {
    draw_set_color(c_black);
    draw_text(_x + 1, _y + 1, _lines[_i]);
    draw_set_color(c_lime);
    draw_text(_x, _y, _lines[_i]);
    _y += _lh;
}
draw_set_color(c_white);
