// ══════════════════════════════════════════════════════════
// OBJ_ENEMY_SWORDSMAN — Draw
// Dibuja el sprite y overlays de debug.
//
// F3 → global.debug_enemy_attacks: hitbox WINDUP/ACTIVE + rangos de ataque
// F6 → global.debug_enemy_ai     : estado FSM + timers (en obj_enemy_parent)
// ══════════════════════════════════════════════════════════
draw_self();

// ── Debug collision view: mostrar más información ────────
if (global.debug_collision_view) {
    draw_set_color(c_white);
    draw_set_alpha(0.7);
    draw_text(x, y + col_bottom + 10,
        "reach=" + string(enemy_attack_reach) + " h=" + string(enemy_attack_height));
}

// Mostrar debug si: global.debug_dev (modo dev) O global.debug_enemy_attacks (F3)
var _show_debug = (variable_global_exists("debug_dev") && global.debug_dev) || global.debug_enemy_attacks;
if (_show_debug) {

    var _dc = draw_get_color();
    var _da = draw_get_alpha();

    // ── Attack trigger distance — rango de DECISIÓN ──────
    // Línea roja: cuando el jugador cruza esta línea, el enemigo entra en WINDUP
    // y comienza a avanzar hacia la distancia real de golpe.
    draw_set_color(make_color_rgb(255, 80, 80));
    draw_set_alpha(0.5);
    draw_line_width(x + facing * attack_trigger_distance, y - 20,
                    x + facing * attack_trigger_distance, y + 8, 2);
    // Zona de detección vertical (área donde el trigger es válido)
    draw_set_color(make_color_rgb(255, 80, 80));
    draw_set_alpha(0.10);
    draw_rectangle(x + facing * attack_trigger_distance - 2,
                   y - attack_vertical_tolerance,
                   x + facing * attack_trigger_distance + 2,
                   y + attack_vertical_tolerance, false);

    // ── Línea naranja: distancia de parada (informativa)
    // El enemigo se detiene aquí para disparar, pero el hitbox ya cubre
    // desde el origen (0) hasta la línea roja (attack_trigger_distance).
    // Esta línea marca dónde se para el enemigo, no el alcance del golpe.
    draw_set_color(make_color_rgb(255, 160, 0));
    draw_set_alpha(0.2);
    draw_line_width(x + facing * attack_stop_distance, y - 12,
                    x + facing * attack_stop_distance, y + 4, 1);

    // ── Zona de alcance real de la hitbox ────────────────
    // Rectángulo semitransparente donde caerá el golpe (hitbox preview).
    var _hx = x + facing * esword_hitbox_offset_x;
    var _hy = y + esword_hitbox_offset_y;
    var _hw = esword_hitbox_w * 0.5;
    var _hh = esword_hitbox_h * 0.5;

    if (estate == ESTATE_ATTACK_WINDUP) {
        // Anticipación: outline amarillo tenue (hitbox previsto, no activo aún)
        draw_set_color(c_yellow);
        draw_set_alpha(0.2);
        draw_rectangle(_hx - _hw, _hy - _hh, _hx + _hw, _hy + _hh, false);
        draw_set_alpha(0.6);
        draw_rectangle(_hx - _hw, _hy - _hh, _hx + _hw, _hy + _hh, true);
        draw_set_alpha(0.8);
        draw_text(_hx, _hy - _hh - 10, "WINDUP (no daño aún)");
    }

    if (instance_exists(sword_hitbox_id)) {
        // Hitbox activa: relleno rojo + outline sólido (diferente de windup)
        var _ax = sword_hitbox_id.x;
        var _ay = sword_hitbox_id.y;
        var _aw = sword_hitbox_id.hitbox_w * 0.5;
        var _ah = sword_hitbox_id.hitbox_h * 0.5;
        draw_set_color(make_color_rgb(255, 0, 0));  // rojo para ACTIVE
        draw_set_alpha(0.6);
        draw_rectangle(_ax - _aw, _ay - _ah, _ax + _aw, _ay + _ah, false);
        draw_set_alpha(1.0);
        draw_rectangle(_ax - _aw, _ay - _ah, _ax + _aw, _ay + _ah, true);
        draw_set_alpha(0.8);
        draw_text(_ax, _ay - _ah - 10, "HITBOX ACTIVE!");
    }

    // ── Estado FSM + sprite visual ────────────────────────
    draw_set_halign(fa_center);
    draw_set_valign(fa_bottom);
    draw_set_alpha(1.0);

    var _state_label  = "";
    var _timer_label  = "";
    var _col          = c_white;
    var _sprite_label = "";

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
            _timer_label = "W:" + string(attack_windup_timer) + " dx:" + string(abs(obj_player.x - x));
            break;
        case ESTATE_ATTACK_ACTIVE:
            _state_label = "ATTACK";
            _col = make_color_rgb(255, 0, 0);  // rojo para ATTACK activo
            _timer_label = "A:" + string(attack_active_timer);
            if (instance_exists(sword_hitbox_id)) {
                _timer_label += " [HITBOX]";
            }
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

    // Sprite activo (para confirmar coincidencia lógica↔visual)
    if      (sprite_index == spr_test_atk)  _sprite_label = "[ATK]";
    else if (sprite_index == spr_test_walk) _sprite_label = "[WALK]";
    else if (sprite_index == spr_test)      _sprite_label = "[IDLE]";
    else                                    _sprite_label = "[spr:" + string(sprite_index) + "]";

    // Flags extra en una línea
    var _flags = "";
    if (is_blocked_by_enemy) _flags += " BLK";
    if (hitstun_timer > 0)   _flags += " HIT:" + string(hitstun_timer);

    draw_set_color(_col);
    draw_text(x, y + col_top - 42, _state_label + " " + _sprite_label);
    if (_timer_label != "") {
        draw_set_color(c_white);
        draw_text(x, y + col_top - 30, _timer_label);
    }
    if (_flags != "") {
        draw_set_color(make_color_rgb(255, 80, 80));
        draw_text(x, y + col_top - 18, string_trim(_flags));
    }
    // move_x y facing para verificar walk
    draw_set_color(make_color_rgb(180, 180, 180));
    draw_text(x, y + col_top - 6,
        "mx:" + string_format(move_x, 1, 1)
        + "  f:" + string(facing));

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(_dc);
    draw_set_alpha(_da);
}

// ── Debug de separación/contacto (desde parent) ───────────
event_inherited();
