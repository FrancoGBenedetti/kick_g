// ══════════════════════════════════════════════════════════
// OBJ_PLAYER — Draw GUI
//
// Dibuja elementos del HUD en screen-space (fijos en pantalla).
// - Barra de carga de golpe fuerte (arriba a la derecha, siempre)
// - Barra de Beat 'em Up Mode (debajo del HP HUD)
// - Información de dificultad (cuando global.debug_difficulty = true)
// ══════════════════════════════════════════════════════════

// ── Carga de golpe fuerte (HEAVY) — Barra azul arriba a la derecha ────
// Siempre visible, se llena con golpes ligeros y parry
var _heavy_bar_w = 120;
var _heavy_bar_h = 10;
var _heavy_bar_x = display_get_gui_width() - _heavy_bar_w - 24;
var _heavy_bar_y = 24;
var _heavy_pct = beat_heavy_charge / beat_heavy_charge_max;

// ── Fondo negro ─────────────────────────────────────────────
draw_set_color(c_black);
draw_rectangle(_heavy_bar_x, _heavy_bar_y, _heavy_bar_x + _heavy_bar_w, _heavy_bar_y + _heavy_bar_h, false);

// ── Barra azul de progreso ──────────────────────────────────
var _bar_color = beat_heavy_unlocked ? c_lime : c_blue;  // verde si está listo, azul si cargando
draw_set_color(_bar_color);
draw_rectangle(_heavy_bar_x, _heavy_bar_y, _heavy_bar_x + (_heavy_bar_w * _heavy_pct), _heavy_bar_y + _heavy_bar_h, false);

// ── Borde blanco/verde ───────────────────────────────────────
draw_set_color(beat_heavy_unlocked ? c_lime : c_white);
draw_rectangle(_heavy_bar_x, _heavy_bar_y, _heavy_bar_x + _heavy_bar_w, _heavy_bar_y + _heavy_bar_h, true);

// ── Etiqueta "HEAVY" ─────────────────────────────────────────
draw_set_color(beat_heavy_unlocked ? c_lime : c_white);
draw_set_halign(fa_right);
draw_set_valign(fa_middle);
draw_text(_heavy_bar_x - 8, _heavy_bar_y + _heavy_bar_h / 2, "HEAVY");

// ── Estado visual si está listo ──────────────────────────────
if (beat_heavy_unlocked) {
    draw_set_color(c_lime);
    draw_text(_heavy_bar_x + _heavy_bar_w / 2, _heavy_bar_y + _heavy_bar_h + 8, "READY");
}

// ── Beat 'em Up Mode — Barra de duración en HUD ──────────────
if (beat_em_up_active) {
    var _bar_x = 16;           // posición X en pantalla (izquierda)
    var _bar_y = 48;           // posición Y en pantalla (debajo del HP)
    var _bar_w = 140;          // ancho de la barra
    var _bar_h = 12;           // alto de la barra
    var _progress = beat_em_up_timer / beat_em_up_duration;
    _progress = max(0, min(1, _progress));  // clamp 0-1

    // ── Fondo oscuro ─────────────────────────────────────────
    draw_set_color(c_black);
    draw_rectangle(_bar_x, _bar_y, _bar_x + _bar_w, _bar_y + _bar_h, false);

    // ── Barra roja de progreso ───────────────────────────────
    draw_set_color(c_red);
    draw_rectangle(_bar_x, _bar_y, _bar_x + (_bar_w * _progress), _bar_y + _bar_h, false);

    // ── Borde blanco ─────────────────────────────────────────
    draw_set_color(c_white);
    draw_rectangle(_bar_x, _bar_y, _bar_x + _bar_w, _bar_y + _bar_h, true);

    // ── Texto "BEAT" ─────────────────────────────────────────
    draw_set_color(c_white);
    draw_set_halign(fa_left);
    draw_set_valign(fa_middle);
    draw_text(_bar_x + _bar_w + 8, _bar_y + _bar_h / 2, "BEAT");
}

// ── HUD de dificultad (tecla 9) ──────────────────────────────
if (variable_global_exists("debug_difficulty") && global.debug_difficulty) {
    var _hud_x = 16;
    var _hud_y = 140;
    var _line_h = 14;
    var _col = c_white;

    draw_set_color(_col);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_font(-1);

    // Dificultad actual
    draw_text(_hud_x, _hud_y, "DIFFICULTY: " + get_difficulty_string());

    // Player stats
    draw_text(_hud_x, _hud_y + _line_h * 1, "Player HP: " + string(hp) + "/" + string(max_hp));
    if (variable_global_exists("current_config")) {
        draw_text(_hud_x, _hud_y + _line_h * 2, "Parry Window: " + string(global.current_config.parry_window_frames) + "f");
        draw_text(_hud_x, _hud_y + _line_h * 3, "Invuln: " + string(global.current_config.player_default_invuln) + "f");
        draw_text(_hud_x, _hud_y + _line_h * 4, "Recovery Lock: " + string(global.current_config.damage_recovery_lock_duration) + "f");

        // Enemy multipliers
        draw_set_color(make_color_rgb(200, 200, 100));
        draw_text(_hud_x, _hud_y + _line_h * 6, "Enemy Windup Mult: " + string(global.current_config.enemy_attack_windup_multiplier));
        draw_text(_hud_x, _hud_y + _line_h * 7, "Enemy Cooldown Mult: " + string(global.current_config.enemy_attack_cooldown_multiplier));

        if (variable_global_exists("enemy_test_hp_multiplier")) {
            draw_text(_hud_x, _hud_y + _line_h * 8, "Enemy HP Test Mult: x" + string(global.enemy_test_hp_multiplier));
        }
    }

    // Beat 'em Up status
    if (beat_em_up_active) {
        draw_set_color(c_red);
        draw_text(_hud_x, _hud_y + _line_h * 10, "Beat 'em Up: ACTIVE (" + string(beat_em_up_timer) + "f)");
    }
}
