// ══════════════════════════════════════════════════════════
// OBJ_PLAYER — Draw GUI
// Dibuja la interfaz fija del jugador en screen-space.
// El evento Draw GUI corre DESPUÉS del Draw normal y en un
// sistema de coordenadas propio (0,0 = esquina superior izquierda
// de la pantalla, independiente de la cámara).
//
// Contenido actual:
//   • Barra de vida con fondo, relleno y texto HP x/max
//
// Futuro:
//   • Contador de flechas / munición
//   • Icono de dash disponible
//   • Indicador de carga del arco
// ══════════════════════════════════════════════════════════

// ── Parámetros de posición y tamaño ──────────────────────
// Escalado para puerto 1920×1080. Ajustar si cambia DISPLAY_W/H.
var _bar_x = 48;
var _bar_y = 48;
var _bar_w = 300;
var _bar_h = 28;

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
    hp, max_hp,
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
          "HP  " + string(hp) + " / " + string(max_hp));

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
