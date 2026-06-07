// ══════════════════════════════════════════════════════════
// OBJ_ENEMY_SWORDSMAN — Draw
// Dibuja el sprite y overlays de debug.
//
// F3 → global.debug_enemy_attacks: hitbox WINDUP/ACTIVE + rangos de ataque
// F6 → global.debug_enemy_ai     : estado FSM + timers (en obj_enemy_parent)
// ══════════════════════════════════════════════════════════
draw_self();

if (global.debug_enemy_attacks) {

    var _dc = draw_get_color();
    var _da = draw_get_alpha();

    // ── Attack stop distance (horizontal) ────────────────
    // Línea vertical a cada lado mostrando el rango real de ataque.
    // Cuando el jugador está dentro de estas líneas → el enemigo ataca.
    draw_set_color(make_color_rgb(255, 80, 80));
    draw_set_alpha(0.5);
    draw_line_width(x + facing * attack_stop_distance, y - 20,
                    x + facing * attack_stop_distance, y + 8, 2);
    // Tolerancia vertical: caja sobre el enemigo
    draw_set_color(make_color_rgb(255, 80, 80));
    draw_set_alpha(0.18);
    draw_rectangle(x + facing * attack_stop_distance - 2,
                   y - attack_vertical_tolerance,
                   x + facing * attack_stop_distance + 2,
                   y + attack_vertical_tolerance, false);

    // ── Zona de alcance real de la hitbox ────────────────
    // Rectángulo semitransparente donde caerá el golpe (hitbox preview).
    var _hx = x + facing * esword_hitbox_offset_x;
    var _hy = y + esword_hitbox_offset_y;
    var _hw = esword_hitbox_w * 0.5;
    var _hh = esword_hitbox_h * 0.5;

    if (estate == ESTATE_ATTACK_WINDUP) {
        // Anticipación: outline amarillo tenue
        draw_set_color(c_yellow);
        draw_set_alpha(0.2);
        draw_rectangle(_hx - _hw, _hy - _hh, _hx + _hw, _hy + _hh, false);
        draw_set_alpha(0.6);
        draw_rectangle(_hx - _hw, _hy - _hh, _hx + _hw, _hy + _hh, true);
    }

    if (instance_exists(sword_hitbox_id)) {
        // Hitbox activa: relleno + outline sólido
        var _ax = sword_hitbox_id.x;
        var _ay = sword_hitbox_id.y;
        var _aw = sword_hitbox_id.hitbox_w * 0.5;
        var _ah = sword_hitbox_id.hitbox_h * 0.5;
        draw_set_color(c_yellow);
        draw_set_alpha(0.45);
        draw_rectangle(_ax - _aw, _ay - _ah, _ax + _aw, _ay + _ah, false);
        draw_set_alpha(1.0);
        draw_rectangle(_ax - _aw, _ay - _ah, _ax + _aw, _ay + _ah, true);
    }

    // ── Timers sobre el enemigo ───────────────────────────
    draw_set_halign(fa_center);
    draw_set_valign(fa_bottom);
    draw_set_alpha(1.0);

    var _state_label = "";
    var _timer_label = "";
    var _col         = c_white;

    switch (estate) {
        case ESTATE_CHASE:
            _state_label = "CHASE";
            _col = c_lime;
            if (attack_cooldown_timer > 0) {
                _timer_label = "CD:" + string(attack_cooldown_timer);
            }
            break;
        case ESTATE_ATTACK_WINDUP:
            _state_label = "WINDUP";
            _col = c_yellow;
            _timer_label = "W:" + string(attack_windup_timer);
            break;
        case ESTATE_ATTACK_ACTIVE:
            _state_label = "ATTACK";
            _col = make_color_rgb(255, 100, 0);
            _timer_label = "A:" + string(attack_active_timer);
            break;
        case ESTATE_COOLDOWN:
            _state_label = "COOLDOWN";
            _col = make_color_rgb(160, 160, 255);
            _timer_label = "CD:" + string(attack_cooldown_timer);
            break;
        case ESTATE_PATROL:
            _state_label = "PATROL";
            _col = c_gray;
            break;
    }

    draw_set_color(_col);
    draw_text(x, y + col_top - 30, _state_label);
    if (_timer_label != "") {
        draw_set_color(c_white);
        draw_text(x, y + col_top - 18, _timer_label);
    }

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(_dc);
    draw_set_alpha(_da);
}

// ── Debug de separación/contacto (desde parent) ───────────
event_inherited();
