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

// ══════════════════════════════════════════════════════════
// BEAT 'EM UP HUD — barra HEAVY/gancho + combo + duración
// ══════════════════════════════════════════════════════════
// Este bloque vivía en Draw_GUI_0.gml, un archivo que NUNCA estuvo
// conectado a ningún evento real de obj_player (el .yy solo registra
// Create, Step, Draw normal y Draw GUI = este mismo evento, eventNum
// 64) — por eso nunca se veía nada de esto, aunque el código en sí
// estaba bien. Se movió acá, que es el evento Draw GUI de verdad.

// ── Carga de golpe fuerte (HEAVY) — Barra azul arriba a la derecha ────
// Siempre visible, se llena con jab/recto que CONECTAN de verdad.
var _heavy_bar_w = 120;
var _heavy_bar_h = 10;
var _heavy_bar_x = display_get_gui_width() - _heavy_bar_w - 24;
var _heavy_bar_y = 24;
var _heavy_pct = beat_heavy_charge / beat_heavy_charge_max;

draw_set_color(c_black);
draw_rectangle(_heavy_bar_x, _heavy_bar_y, _heavy_bar_x + _heavy_bar_w, _heavy_bar_y + _heavy_bar_h, false);

var _heavy_bar_color = beat_heavy_unlocked ? c_lime : c_blue;  // verde si está listo, azul si cargando
draw_set_color(_heavy_bar_color);
draw_rectangle(_heavy_bar_x, _heavy_bar_y, _heavy_bar_x + (_heavy_bar_w * _heavy_pct), _heavy_bar_y + _heavy_bar_h, false);

draw_set_color(beat_heavy_unlocked ? c_lime : c_white);
draw_rectangle(_heavy_bar_x, _heavy_bar_y, _heavy_bar_x + _heavy_bar_w, _heavy_bar_y + _heavy_bar_h, true);

draw_set_color(beat_heavy_unlocked ? c_lime : c_white);
draw_set_halign(fa_right);
draw_set_valign(fa_middle);
draw_text(_heavy_bar_x - 8, _heavy_bar_y + _heavy_bar_h / 2, "HEAVY");

if (beat_heavy_unlocked) {
    draw_set_color(c_lime);
    draw_set_halign(fa_center);
    draw_text(_heavy_bar_x + _heavy_bar_w / 2, _heavy_bar_y + _heavy_bar_h + 8, "READY");
}

// ── Contador simple de combo del gancho (prototipo/debug) ────
// "COMBO: 0/4" ... "COMBO: 4/4 HOOK READY". Solo sube con jab/recto
// que CONECTAN (ver player_register_beat_combo_hit() en Create_0.gml).
var _combo_label = "COMBO: " + string(beat_heavy_charge) + "/" + string(beat_heavy_charge_max)
                 + (beat_heavy_unlocked ? " HOOK READY" : "");
draw_set_color(beat_heavy_unlocked ? c_lime : c_white);
draw_set_halign(fa_right);
draw_set_valign(fa_middle);
draw_text(_heavy_bar_x + _heavy_bar_w, _heavy_bar_y + _heavy_bar_h + 22, _combo_label);

if (variable_global_exists("debug_dev") && global.debug_dev) {
    draw_set_color(c_aqua);
    draw_text(_heavy_bar_x + _heavy_bar_w, _heavy_bar_y + _heavy_bar_h + 36,
              "combo_timer=" + string(beat_heavy_combo_timer) + "/" + string(beat_heavy_combo_timeout)
              + "  active=" + string(beat_heavy_combo_active)
              + "  unlocked=" + string(beat_heavy_unlocked));
}

// ── Beat 'em Up Mode — Barra de duración en HUD ──────────────
if (beat_em_up_active) {
    var _beat_bar_x = 16;
    var _beat_bar_y = 48;
    var _beat_bar_w = 140;
    var _beat_bar_h = 12;
    var _beat_progress = beat_em_up_timer / beat_em_up_duration;
    _beat_progress = max(0, min(1, _beat_progress));

    draw_set_color(c_black);
    draw_rectangle(_beat_bar_x, _beat_bar_y, _beat_bar_x + _beat_bar_w, _beat_bar_y + _beat_bar_h, false);

    draw_set_color(c_red);
    draw_rectangle(_beat_bar_x, _beat_bar_y, _beat_bar_x + (_beat_bar_w * _beat_progress), _beat_bar_y + _beat_bar_h, false);

    draw_set_color(c_white);
    draw_rectangle(_beat_bar_x, _beat_bar_y, _beat_bar_x + _beat_bar_w, _beat_bar_y + _beat_bar_h, true);

    draw_set_color(c_white);
    draw_set_halign(fa_left);
    draw_set_valign(fa_middle);
    draw_text(_beat_bar_x + _beat_bar_w + 8, _beat_bar_y + _beat_bar_h / 2, "BEAT");

    // Próximo golpe del combo jab/recto (beat_combo_index alterna 0=jab, 1=recto
    // desde la sesión de timing — ya no es un contador 0-3, así que se muestra
    // el nombre del golpe en vez del viejo "COMBO N / 4" que quedaba engañoso.
    if (beat_combo_index >= 0) {
        draw_set_color(c_yellow);
        draw_text(_beat_bar_x + _beat_bar_w + 8, _beat_bar_y + _beat_bar_h + 16,
                  "NEXT: " + ((beat_combo_index mod 2 == 0) ? "JAB" : "RIGHT STRAIGHT"));
    }
}

// ── HUD de dificultad (tecla 9) ──────────────────────────────
if (variable_global_exists("debug_difficulty") && global.debug_difficulty) {
    var _diff_hud_x = 16;
    var _diff_hud_y = 260;
    var _diff_line_h = 14;

    draw_set_color(c_white);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_font(-1);

    draw_text(_diff_hud_x, _diff_hud_y, "DIFFICULTY: " + get_difficulty_string());
    draw_text(_diff_hud_x, _diff_hud_y + _diff_line_h * 1, "Player HP: " + string(hp) + "/" + string(max_hp));
    if (variable_global_exists("current_config")) {
        draw_text(_diff_hud_x, _diff_hud_y + _diff_line_h * 2, "Parry Window: " + string(global.current_config.parry_window_frames) + "f");
        draw_text(_diff_hud_x, _diff_hud_y + _diff_line_h * 3, "Invuln: " + string(global.current_config.player_default_invuln) + "f");
        draw_text(_diff_hud_x, _diff_hud_y + _diff_line_h * 4, "Recovery Lock: " + string(global.current_config.damage_recovery_lock_duration) + "f");

        draw_set_color(make_color_rgb(200, 200, 100));
        draw_text(_diff_hud_x, _diff_hud_y + _diff_line_h * 6, "Enemy Windup Mult: " + string(global.current_config.enemy_attack_windup_multiplier));
        draw_text(_diff_hud_x, _diff_hud_y + _diff_line_h * 7, "Enemy Cooldown Mult: " + string(global.current_config.enemy_attack_cooldown_multiplier));

        if (variable_global_exists("enemy_test_hp_multiplier")) {
            draw_text(_diff_hud_x, _diff_hud_y + _diff_line_h * 8, "Enemy HP Test Mult: x" + string(global.enemy_test_hp_multiplier));
        }
    }

    if (beat_em_up_active) {
        draw_set_color(c_red);
        draw_text(_diff_hud_x, _diff_hud_y + _diff_line_h * 10, "Beat 'em Up: ACTIVE (" + string(beat_em_up_timer) + "f)");
    }
}

// ── Restaurar estado de render (post Beat 'em Up HUD) ─────
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
    "",
    "── Arco (temporal) ──",
    "bow_aiming     : " + string(is_aiming),
    "bow_charging   : " + string(bow_is_charging),
    "bow_shooting   : " + string(bow_shooting),
    "charge_timer   : " + string(bow_charge_timer) + " / " + string(bow_charge_time_required) + " (visual)",
    "charge_max_dmg : " + string(bow_charge_timer) + " / " + string(bow_max_charge_frames) + " (daño)",
    "fully_charged  : " + string(bow_fully_charged),
    "sprite_index   : " + sprite_get_name(sprite_index),
    "image_index    : " + string_format(image_index, 1, 2),
    "anim_state     : " + player_anim_state,
    "",
    "── Beat combo (temporal) ──",
    "combo_index    : " + string(beat_combo_index) + (beat_combo_index < 0 ? "" : (beat_combo_index mod 2 == 0 ? " (jab)" : " (right straight)")),
    "buffer_timer   : " + string(beat_combo_input_buffer_timer) + " / " + string(beat_combo_input_buffer_max),
    "can_cancel     : " + string(beat_attack_can_cancel),
    "hitbox_active  : " + string(beat_em_up_attack_active),
    "attack_elapsed : " + string(beat_attack_total_frames - beat_punch_visual_timer) + " / " + string(beat_attack_total_frames),
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
