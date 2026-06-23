// ══════════════════════════════════════════════════════════
// OBJ_TIME_MANAGER — Draw
// Debug HUD para mostrar la dificultad actual y valores de configuración.
// ══════════════════════════════════════════════════════════

if (!variable_global_exists("debug_difficulty") || !global.debug_difficulty) {
    exit;  // No mostrar si debug_difficulty no está activo
}

// ── Configuración de posición ──────────────────────────────
var _x = 20;
var _y = 20;
var _line_h = 16;

// ── Guardar estado de render ──────────────────────────────
var _dc = draw_get_color();
var _da = draw_get_alpha();
var _dh = draw_get_halign();
var _dv = draw_get_valign();

draw_set_alpha(1.0);
draw_set_color(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_top);

// ── Encabezado ────────────────────────────────────────────
draw_set_color(c_yellow);
draw_text(_x, _y, "DIFFICULTY: " + get_difficulty_string());
_y += _line_h * 1.5;

// ── PLAYER ────────────────────────────────────────────────
draw_set_color(c_lime);
draw_text(_x, _y, "PLAYER CONFIG:");
_y += _line_h;

draw_set_color(c_white);
draw_text(_x + 10, _y, "Max HP: " + string(global.current_config.player_max_hp));
_y += _line_h;
draw_text(_x + 10, _y, "Parry Window: " + string(global.current_config.parry_window_frames) + " frames");
_y += _line_h;
draw_text(_x + 10, _y, "Perfect Parry: " + string(global.current_config.parry_counter_window) + " frames");
_y += _line_h;
draw_text(_x + 10, _y, "Invuln Duration: " + string(global.current_config.player_default_invuln) + " frames");
_y += _line_h;
draw_text(_x + 10, _y, "Recovery Lock: " + string(global.current_config.damage_recovery_lock_duration) + " frames");
_y += _line_h;
draw_text(_x + 10, _y, "Hitstun: " + string(global.current_config.player_hitstun) + " frames");
_y += _line_h * 1.5;

// ── ENEMY ────────────────────────────────────────────────
draw_set_color(c_orange);
draw_text(_x, _y, "ENEMY MULTIPLIERS:");
_y += _line_h;

draw_set_color(c_white);
draw_text(_x + 10, _y, "Windup: " + string_format(global.current_config.enemy_attack_windup_multiplier, 1, 2) + "x");
_y += _line_h;
draw_text(_x + 10, _y, "Cooldown: " + string_format(global.current_config.enemy_attack_cooldown_multiplier, 1, 2) + "x");
_y += _line_h;
draw_text(_x + 10, _y, "Charge (Archer): " + string_format(global.current_config.enemy_charge_time_multiplier, 1, 2) + "x");
_y += _line_h;

// ── INSTRUCCIONES ─────────────────────────────────────────
_y += _line_h;
draw_set_color(c_gray);
draw_set_halign(fa_left);
draw_text(_x, _y, "[5] Dev Mode  [6] Easy  [7] Normal  [8] Hard  [9] Toggle HUD");

// ── Restaurar render state ────────────────────────────────
draw_set_color(_dc);
draw_set_alpha(_da);
draw_set_halign(_dh);
draw_set_valign(_dv);
