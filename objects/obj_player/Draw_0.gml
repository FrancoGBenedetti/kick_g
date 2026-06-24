// ══════════════════════════════════════════════════════════
// OBJ_PLAYER — Draw (world-space)
//
// Estructura (en orden de ejecución):
//   1. Sprite + health bar (event_inherited)
//   2. DEBUG: parry extendido  → F9  global.debug_parry
//   3. DEBUG: ataque/hitbox    → F7  global.debug_attack
//   4. DEBUG: dash slide       → F5  global.debug_collision
//   5. DEBUG: anclas físicas   → debug_draw_anchors
//   6. Indicador de arco       (solo mientras arco activo)
//
// IMPORTANTE: todo el debug está ANTES del exit del arco.
// El exit de la línea del arco era la causa de que todos los
// bloques de debug de versiones anteriores nunca se ejecutaran.
// ══════════════════════════════════════════════════════════

// ── 1. SPRITE ─────────────────────────────────────────────
// event_inherited() delega al parent: draw_self() + health bar
// (health bar suprimida para el jugador por show_world_healthbar=false)
event_inherited();

// ══════════════════════════════════════════════════════════
// 1b. PARRY POPUP — ! grande sobre la cabeza
// Visible siempre que parry_popup_timer > 0 (independiente de debug flags).
// Duración: parry_popup_timer_max frames reales (default 28 ≈ 0.46s a 60fps).
// Altura: y + col_top - 24  (sobre la hitbox del jugador).
// Ajustar:
//   • Duración   → parry_popup_timer_max en Create_0
//   • Altura     → modificar el offset _popup_y abajo
//   • Tamaño     → cambiar los argumentos xscale/yscale de draw_text_transformed
//   • Color      → cambiar c_yellow / sombra c_black
// ══════════════════════════════════════════════════════════
if (parry_popup_timer > 0) {
    var _dc_pp = draw_get_color();
    var _da_pp = draw_get_alpha();

    var _popup_x = x;
    var _popup_y = y + col_top - 24;   // sobre la cabeza — ajustar según sprite
    var _scale   = 4;                  // tamaño del signo — 3=pequeño, 5=grande

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_alpha(1.0);

    // Sombra (offset +2, +2 en negro)
    draw_set_color(c_black);
    draw_text_transformed(_popup_x + 2, _popup_y + 2, "!", _scale, _scale, 0);

    // Signo principal en amarillo
    draw_set_color(c_yellow);
    draw_text_transformed(_popup_x, _popup_y, "!", _scale, _scale, 0);

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(_dc_pp);
    draw_set_alpha(_da_pp);
}

// ══════════════════════════════════════════════════════════
// 1c. DEBUG KNOCKBACK DEL JUGADOR
// Toggle: global.debug_knockback (activar en obj_time_manager Create o en runtime)
// ══════════════════════════════════════════════════════════
if (variable_global_exists("debug_knockback") && global.debug_knockback) {
    var _dc_kb = draw_get_color();
    var _da_kb = draw_get_alpha();
    draw_set_alpha(1.0);
    draw_set_halign(fa_center);
    draw_set_valign(fa_bottom);

    var _kb_active = (hitstun_timer > 0);
    draw_set_color(_kb_active ? c_red : make_color_rgb(160,160,160));
    draw_text(x, y + col_top - 56,
        "KB:" + (_kb_active ? "ON" : "off")
        + "  hsp:" + string_format(knockback_x, 1, 1)
        + "  vsp:" + string_format(move_y, 1, 1)
        + "  stun:" + string(hitstun_timer) + "/" + string(default_hitstun));

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(_dc_kb);
    draw_set_alpha(_da_kb);
}

// ══════════════════════════════════════════════════════════
// 1b2. DEBUG SUPER ENERGY
// Toggle: global.debug_super_energy (activar en obj_time_manager Create)
// ══════════════════════════════════════════════════════════
if (variable_global_exists("debug_super_energy") && global.debug_super_energy) {
    var _dc_se = draw_get_color();
    var _da_se = draw_get_alpha();
    draw_set_alpha(1.0);
    draw_set_halign(fa_center);
    draw_set_valign(fa_bottom);

    var _pct = (super_energy_max > 0) ? (super_energy / super_energy_max) : 0;

    // Barra de energía: azul eléctrico sobre la cabeza
    var _bx  = x;
    var _by  = y + col_top - 34;
    var _bw  = 80;
    var _bh  = 8;
    // Fondo
    draw_set_color(make_color_rgb(20, 20, 60));
    draw_rectangle(_bx - _bw * 0.5, _by - _bh, _bx + _bw * 0.5, _by, false);
    // Relleno
    draw_set_color(ability_super_attacks ? make_color_rgb(60, 140, 255) : make_color_rgb(80,80,80));
    draw_rectangle(_bx - _bw * 0.5, _by - _bh, _bx - _bw * 0.5 + _bw * _pct, _by, false);
    // Borde
    draw_set_color(c_white);
    draw_set_alpha(0.5);
    draw_rectangle(_bx - _bw * 0.5, _by - _bh, _bx + _bw * 0.5, _by, true);

    // Texto de estado
    draw_set_alpha(1.0);
    draw_set_color(c_aqua);
    draw_text(_bx, _by - _bh - 2,
        "SE:" + string(super_energy) + "/" + string(super_energy_max)
        + "  [" + (ability_super_attacks ? "ON" : "off") + "]"
        + "  U:" + (ability_super_attack_up      ? "Y" : "-")
        + " D:"  + (ability_super_attack_down    ? "Y" : "-")
        + " F:"  + (ability_super_attack_forward ? "Y" : "-")
        + " B:"  + (ability_super_attack_back    ? "Y" : "-"));

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(_dc_se);
    draw_set_alpha(_da_se);
}

// ══════════════════════════════════════════════════════════
// 1c2. DEBUG AIR SWORD BOUNCE
// Toggle: global.debug_air_sword_bounce
// ══════════════════════════════════════════════════════════
if (variable_global_exists("debug_air_sword_bounce") && global.debug_air_sword_bounce) {
    var _dc_asb = draw_get_color();
    var _da_asb = draw_get_alpha();
    draw_set_alpha(1.0);
    draw_set_halign(fa_center);
    draw_set_valign(fa_bottom);

    var _asb_y = y + col_top - 40;

    // Fila de estado
    var _on_cd = (air_sword_bounce_cooldown > 0);
    draw_set_color(_on_cd ? c_red : make_color_rgb(100,200,100));
    draw_text(x, _asb_y,
        "AIR-BOUNCE spd:" + string(air_sword_bounce_speed)
        + "  cd:" + string(air_sword_bounce_cooldown) + "/" + string(air_sword_bounce_cooldown_max)
        + "  grnd:" + string(isGrounded)
        + "  vsp:" + string_format(move_y, 1, 1));

    // Flash "AIR SWORD BOUNCE" durante air_sword_bounce_flash_timer frames
    if (air_sword_bounce_flash_timer > 0) {
        var _alpha = air_sword_bounce_flash_timer / air_sword_bounce_flash_max;
        draw_set_alpha(_alpha);
        var _scale = 2.5;
        draw_set_color(c_black);
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_text_transformed(x + 2, y + col_top - 68, "AIR SWORD BOUNCE", _scale, _scale, 0);
        draw_set_color(c_lime);
        draw_text_transformed(x,     y + col_top - 68, "AIR SWORD BOUNCE", _scale, _scale, 0);
        draw_set_valign(fa_top);
    }

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(_dc_asb);
    draw_set_alpha(_da_asb);
}

// ══════════════════════════════════════════════════════════
// 1d. DEBUG COUNTER ATTACK
// Toggle: global.debug_counterattack (activar en obj_time_manager Create)
// ══════════════════════════════════════════════════════════
if (variable_global_exists("debug_counterattack") && global.debug_counterattack) {
    var _dc_ca = draw_get_color();
    var _da_ca = draw_get_alpha();
    draw_set_alpha(1.0);
    draw_set_halign(fa_center);
    draw_set_valign(fa_bottom);

    var _has_window  = can_counterattack && counterattack_timer > 0;
    var _target_name = instance_exists(counter_target)
                       ? object_get_name(counter_target.object_index)
                       : "noone";

    draw_set_color(_has_window ? c_orange : make_color_rgb(140,140,140));
    draw_text(x, y + col_top - 72,
        "COUNTER:" + (ability_counterattack ? "ON" : "OFF")
        + "  win:" + (_has_window ? "ACTIVE" : "---")
        + "  t:" + string(counterattack_timer)
        + "  ACT:" + string(counter_attack_active)
        + "  tgt:" + _target_name);

    // Si hay ventana activa: dibujar línea hacia el target
    if (_has_window && instance_exists(counter_target)) {
        draw_set_color(c_orange);
        draw_set_alpha(0.8);
        draw_line_width(x, y + col_top * 0.5,
                        counter_target.x, counter_target.y + counter_target.col_top * 0.5, 2);
    }

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(_dc_ca);
    draw_set_alpha(_da_ca);
}

// ══════════════════════════════════════════════════════════
// 2. DEBUG PARRY EXTENDIDO
// Toggle: F9 → global.debug_parry
//
// Panel completo sobre la cabeza del jugador con:
//   • Estado FSM, hitstun, dash
//   • Ventana de parry con barra de progreso
//   • Parry success flash (cyan)
//   • Ventana de contraataque
//   • Cooldown activo
//   • Info de hitboxes de daño cercanas (<150px)
//
// Para desactivar: presionar F9.
// Para activar permanente: global.debug_parry = true en Create del room.
// ══════════════════════════════════════════════════════════
if (variable_global_exists("debug_parry") && global.debug_parry) {

    var _dc_p = draw_get_color();
    var _da_p = draw_get_alpha();
    draw_set_halign(fa_center);
    draw_set_valign(fa_top);

    // ── Nombre del estado FSM ─────────────────────────────
    var _sname = "?";
    switch (player_state) {
        case PSTATE.IDLE:       _sname = "IDLE";  break;
        case PSTATE.RUN:        _sname = "RUN";   break;
        case PSTATE.JUMP:       _sname = "JUMP";  break;
        case PSTATE.FALL:       _sname = "FALL";  break;
        case PSTATE.WALL:       _sname = "WALL";  break;
        case PSTATE.DASH:       _sname = "DASH";  break;
        case PSTATE.ATTACK_1:   _sname = "ATK1";  break;
        case PSTATE.ATTACK_2:   _sname = "ATK2";  break;
        case PSTATE.ATTACK_3:   _sname = "ATK3";  break;
        case PSTATE.DOWN_SLASH: _sname = "POGO";  break;
        case PSTATE.BLOCK:      _sname = "BLOCK"; break;
        default: _sname = "S:" + string(player_state); break;
    }

    // ── Dimensiones del panel ─────────────────────────────
    var _panel_w = 168;
    var _line_h  = 13;
    var _lines   = 10;
    var _panel_h = _lines * _line_h + 12;
    var _px      = x - _panel_w * 0.5;
    var _py      = y + col_top - _panel_h - 10;
    var _tx      = x;
    var _ty      = _py + 5;

    // ── Fondo del panel ───────────────────────────────────
    draw_set_color(c_black);
    draw_set_alpha(0.65);
    draw_rectangle(_px, _py, _px + _panel_w, _py + _panel_h, false);
    draw_set_color(make_color_rgb(80, 80, 80));
    draw_set_alpha(0.85);
    draw_rectangle(_px, _py, _px + _panel_w, _py + _panel_h, true);

    // ── Línea 0: header ───────────────────────────────────
    draw_set_color(c_white);
    draw_set_alpha(1.0);
    draw_text(_tx, _ty, "── PARRY / HIT DEBUG ──");
    _ty += _line_h;

    // ── Línea 0b: invulnerabilidad + hitstun ──────────────
    draw_set_color(is_invulnerable ? c_orange : make_color_rgb(140, 140, 140));
    draw_text(_tx, _ty,
        "INVULN:" + (is_invulnerable ? string(invuln_timer) : "NO")
        + "  HITSTUN:" + string(hitstun_timer)
        + "  KB:" + string_format(knockback_x, 1, 1));
    _ty += _line_h;

    // ── Línea 1: estado FSM + hitstun + dash ─────────────
    // Blanco = normal | Lima = BLOCK activo
    var _is_dashing = (player_state == PSTATE.DASH);
    draw_set_color((player_state == PSTATE.BLOCK) ? c_lime : c_white);
    draw_text(_tx, _ty,
        "STATE:" + _sname
        + "  STN:" + string(hitstun_timer)
        + "  DSH:" + (_is_dashing ? "Y" : "N"));
    _ty += _line_h;

    // ── Línea 2: parry_active + ventana ──────────────────
    // Lima = activo | Gris = inactivo
    draw_set_color(parry_active ? c_lime : make_color_rgb(140, 140, 140));
    draw_text(_tx, _ty,
        "active:" + (parry_active ? "Y" : "N")
        + "  win:" + string(parry_window_timer)
        + "/" + string(parry_window_max));
    _ty += _line_h;

    // ── Línea 3: parry_success + cooldown ─────────────────
    // Cyan = éxito | Rojo = cooldown activo | Gris = normal
    var _psc = parry_success ? c_aqua : make_color_rgb(140, 140, 140);
    draw_set_color(_psc);
    draw_text(_tx, _ty, "success:" + (parry_success ? "Y" : "N"));
    // Cooldown en la misma línea, color independiente
    var _cool_col = (parry_cooldown_timer > 0) ? c_red : make_color_rgb(140, 140, 140);
    draw_set_color(_cool_col);
    draw_text(_tx + 40, _ty, "  cool:" + string(parry_cooldown_timer));
    draw_set_color(_psc);   // restaurar color para el success
    _ty += _line_h;

    // ── Línea 4: can_counterattack + timer + slow ─────────
    // Amarillo = counter disponible | Gris = no disponible
    draw_set_color(can_counterattack ? c_yellow : make_color_rgb(140, 140, 140));
    draw_text(_tx, _ty,
        "ctr:" + (can_counterattack ? "Y" : "N")
        + "[" + string(counterattack_timer) + "/" + string(counter_window_max) + "]"
        + " slow:" + string(parry_slow_timer));
    _ty += _line_h;

    // ── Barra de ventana de parry ─────────────────────────
    // Solo cuando hay ventana activa. Verde → rojo según tiempo restante.
    var _bar_h  = _line_h - 3;
    var _bar_x1 = _px + 4;
    var _bar_x2 = _px + _panel_w - 4;
    var _bar_bw = _bar_x2 - _bar_x1;
    var _bar_y1 = _ty + 1;
    var _bar_y2 = _ty + _bar_h;

    if (parry_active && parry_window_max > 0) {
        // Ventana activa: barra verde que reduce
        var _fill = parry_window_timer / parry_window_max;
        draw_set_color(make_color_rgb(40, 15, 15));
        draw_set_alpha(0.85);
        draw_rectangle(_bar_x1, _bar_y1, _bar_x2, _bar_y2, false);
        draw_set_color(c_lime);
        draw_set_alpha(0.9);
        draw_rectangle(_bar_x1, _bar_y1, _bar_x1 + _bar_bw * _fill, _bar_y2, false);
        draw_set_color(c_white);
        draw_set_alpha(0.75);
        draw_rectangle(_bar_x1, _bar_y1, _bar_x2, _bar_y2, true);
    } else if (is_blocking && !parry_active) {
        // Block normal (post-ventana): barra cian sólida
        draw_set_color(make_color_rgb(0, 80, 100));
        draw_set_alpha(0.85);
        draw_rectangle(_bar_x1, _bar_y1, _bar_x2, _bar_y2, false);
        draw_set_color(c_aqua);
        draw_set_alpha(0.7);
        draw_rectangle(_bar_x1, _bar_y1, _bar_x2, _bar_y2, true);
    } else {
        // Sin ventana: barra gris
        draw_set_color(make_color_rgb(40, 40, 40));
        draw_set_alpha(0.5);
        draw_rectangle(_bar_x1, _bar_y1, _bar_x2, _bar_y2, false);
        draw_set_color(make_color_rgb(80, 80, 80));
        draw_set_alpha(0.6);
        draw_rectangle(_bar_x1, _bar_y1, _bar_x2, _bar_y2, true);
    }
    _ty += _line_h;

    // ── Etiqueta de estado activo (una sola, prioridad) ───
    // Muestra el estado más relevante del momento.
    draw_set_alpha(1.0);
    if (parry_success) {
        draw_set_color(c_aqua);
        draw_text(_tx, _ty, "★  PARRY SUCCESS  ★");
    } else if (parry_active) {
        draw_set_color(c_lime);
        draw_text(_tx, _ty, "◀  PARRY WINDOW  ▶");
    } else if (can_counterattack && counterattack_timer > 0) {
        draw_set_color(c_yellow);
        draw_text(_tx, _ty, "COUNTER WINDOW  [" + string(counterattack_timer) + "]");
    } else if (parry_cooldown_timer > 0) {
        draw_set_color(c_red);
        draw_text(_tx, _ty, "COOLDOWN: " + string(parry_cooldown_timer));
    } else if (player_state == PSTATE.BLOCK) {
        draw_set_color(c_aqua);
        draw_text(_tx, _ty, "BLOCKING (post-window)");
    } else {
        draw_set_color(make_color_rgb(110, 110, 110));
        draw_text(_tx, _ty, "parry ready");
    }
    _ty += _line_h;

    // ── Info de hitboxes de daño cercanas (<150px) ────────
    // Muestra: tipo, damage, can_be_parried, team, owner.
    // Dibujado junto a cada hitbox en world-space.
    var _search_r = 150;

    with (obj_enemy_sword_hitbox) {
        if (point_distance(x, y, other.x, other.y) > _search_r) continue;

        // Highlight de la hitbox
        var _hw = hitbox_w * 0.5;
        var _hh = hitbox_h * 0.5;
        draw_set_color(make_color_rgb(220, 40, 40));
        draw_set_alpha(0.35);
        draw_rectangle(x - _hw, y - _hh, x + _hw, y + _hh, false);
        draw_set_alpha(0.85);
        draw_rectangle(x - _hw, y - _hh, x + _hw, y + _hh, true);

        // Info text junto al hitbox
        var _own_name = instance_exists(owner) ? object_get_name(owner.object_index) : "?";
        var _lx = x + _hw + 4;
        var _ly = y - 26;
        draw_set_color(make_color_rgb(255, 100, 100));
        draw_set_alpha(1.0);
        draw_set_halign(fa_left);
        draw_text(_lx, _ly,      "ENEMY_SWORD");
        draw_text(_lx, _ly + 12, "D:" + string(damage) + " T:" + string(team));
        draw_text(_lx, _ly + 24, "Parry:" + (can_be_parried ? "Y" : "N") + " " + _own_name);
        draw_set_halign(fa_center);
    }

    with (obj_projectile_parent) {
        if (!instance_exists(id)) continue;
        if (team != TEAM_ENEMY) continue;   // solo mostrar proyectiles enemigos
        if (point_distance(x, y, other.x, other.y) > _search_r) continue;

        // Hit radius highlight
        draw_set_color(make_color_rgb(255, 160, 0));
        draw_set_alpha(0.35);
        draw_circle(x, y, hit_radius + 4, false);
        draw_set_alpha(0.85);
        draw_circle(x, y, hit_radius + 4, true);

        // Info text
        var _lx2 = x + hit_radius + 6;
        var _ly2 = y - 20;
        draw_set_color(make_color_rgb(255, 180, 0));
        draw_set_alpha(1.0);
        draw_set_halign(fa_left);
        draw_text(_lx2, _ly2,      object_get_name(object_index));
        draw_text(_lx2, _ly2 + 12, "D:" + string(damage) + " T:" + string(team));
        draw_text(_lx2, _ly2 + 24, "Parry:" + (can_be_parried ? "Y" : "N"));
        draw_set_halign(fa_center);
    }

    // ── Restaurar estado de render ────────────────────────
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(_dc_p);
    draw_set_alpha(_da_p);
}

// ══════════════════════════════════════════════════════════
// 2b. DEBUG DOWN SLASH / POGO
// Activo cuando debug_hitboxes (F8) o debug_attack (F7).
// Muestra: hitbox descendente, bounce_count, cooldown.
// ══════════════════════════════════════════════════════════
var _dbg_ds = (variable_global_exists("debug_hitboxes") && global.debug_hitboxes)
           || (variable_global_exists("debug_attack")   && global.debug_attack);

if (_dbg_ds && player_state == PSTATE.DOWN_SLASH) {
    var _dc_ds = draw_get_color();
    var _da_ds = draw_get_alpha();

    // ── Hitbox descendente ────────────────────────────────
    if (instance_exists(sword_hitbox_id)) {
        var _dhx = sword_hitbox_id.x;
        var _dhy = sword_hitbox_id.y;
        var _dhw = sword_hitbox_id.hitbox_w * 0.5;
        var _dhh = sword_hitbox_id.hitbox_h * 0.5;

        // Relleno verde (pogo activo)
        draw_set_color(c_lime);
        draw_set_alpha(0.25);
        draw_rectangle(_dhx - _dhw, _dhy - _dhh, _dhx + _dhw, _dhy + _dhh, false);
        draw_set_alpha(0.8);
        draw_rectangle(_dhx - _dhw, _dhy - _dhh, _dhx + _dhw, _dhy + _dhh, true);

        // Cruz en el centro
        draw_set_color(c_white);
        draw_set_alpha(0.7);
        draw_line(_dhx - 4, _dhy, _dhx + 4, _dhy);
        draw_line(_dhx, _dhy - 4, _dhx, _dhy + 4);
    }

    // ── Info de estado ────────────────────────────────────
    draw_set_alpha(1.0);
    draw_set_halign(fa_center);
    draw_set_valign(fa_bottom);

    // Sprite activo: _1 (cayendo) o _2 (subiendo)
    var _spr_label = (move_y < 0) ? "DOWN_ATK_2 (RISE)" : "DOWN_ATK_1 (FALL)";
    draw_set_color((move_y < 0) ? c_aqua : c_lime);
    draw_text(x, y + col_top - 20, _spr_label);

    // Velocidad vertical + bounce_count + cooldown + timer
    var _cd_str = (downward_slash_hit_cooldown > 0)
                  ? "  CD:" + string(downward_slash_hit_cooldown)
                  : "";
    draw_set_color(c_white);
    draw_text(x, y + col_top - 6,
        "vsp:" + string(int64(move_y))
        + "  x" + string(bounce_count)
        + _cd_str
        + "  t:" + string(attack_timer));

    // ── Cooldown de re-armado (barra corta) ──────────────
    if (downward_slash_hit_cooldown > 0) {
        var _cd_pct = 1 - (downward_slash_hit_cooldown / downward_slash_hit_cooldown_max);
        var _cb_x1  = x - 20;
        var _cb_x2  = x + 20;
        var _cb_y1  = y + col_top - 4;
        var _cb_y2  = y + col_top;
        draw_set_color(make_color_rgb(40, 40, 40));
        draw_set_alpha(0.7);
        draw_rectangle(_cb_x1, _cb_y1, _cb_x2, _cb_y2, false);
        draw_set_color(c_lime);
        draw_set_alpha(0.85);
        draw_rectangle(_cb_x1, _cb_y1, _cb_x1 + (_cb_x2 - _cb_x1) * _cd_pct, _cb_y2, false);
    }

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(_dc_ds);
    draw_set_alpha(_da_ds);
}

// ══════════════════════════════════════════════════════════
// 3. DEBUG ATAQUE / HITBOX
// Toggle: F7 → global.debug_attack
//
// Muestra:
//   • Hitbox de espada activa (rojo)
//   • Punto de spawn proyectado (naranja)
//   • Estado del combo + frame + attack_timer
// ══════════════════════════════════════════════════════════
if (variable_global_exists("debug_attack") && global.debug_attack) {
    var _da2 = draw_get_color();
    var _db2 = draw_get_alpha();

    // ── Hitbox de espada activa ───────────────────────────
    if (instance_exists(sword_hitbox_id)) {
        var _shx = sword_hitbox_id.x;
        var _shy = sword_hitbox_id.y;
        var _shw = sword_hitbox_id.hitbox_w * 0.5;
        var _shh = sword_hitbox_id.hitbox_h * 0.5;

        draw_set_color(c_red);
        draw_set_alpha(0.30);
        draw_rectangle(_shx - _shw, _shy - _shh, _shx + _shw, _shy + _shh, false);
        draw_set_alpha(0.85);
        draw_rectangle(_shx - _shw, _shy - _shh, _shx + _shw, _shy + _shh, true);

        // Cruz en el centro
        draw_set_color(c_aqua);
        draw_set_alpha(1.0);
        draw_line(_shx - 4, _shy, _shx + 4, _shy);
        draw_line(_shx, _shy - 4, _shx, _shy + 4);
    }

    // ── Punto de spawn proyectado ─────────────────────────
    var _proj_x = x + facing * sword_hitbox_x;
    var _proj_y = y + sword_hitbox_y;
    draw_set_color(make_color_rgb(255, 120, 0));
    draw_set_alpha(0.5);
    draw_circle(_proj_x, _proj_y, 3, false);

    // ── Info de combo sobre la cabeza ────────────────────
    draw_set_alpha(1.0);
    draw_set_color(c_white);
    draw_set_halign(fa_center);
    draw_set_valign(fa_bottom);

    var _astate = "IDLE";
    if      (player_state == PSTATE.ATTACK_1)   _astate = "ATK1";
    else if (player_state == PSTATE.ATTACK_2)   _astate = "ATK2";
    else if (player_state == PSTATE.ATTACK_3)   _astate = "ATK3";
    else if (player_state == PSTATE.DOWN_SLASH)  _astate = "POGO";

    var _frame_str = string(floor(image_index)) + "/" + string(image_number - 1);
    var _timer_str = "t:" + string(attack_timer);
    draw_text(x, y + col_top - 6, _astate + "  " + _frame_str + "  " + _timer_str);

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(_da2);
    draw_set_alpha(_db2);
}

// ══════════════════════════════════════════════════════════
// 4. DEBUG DASH SLIDE
// Activo cuando is_sliding && global.debug_collision
// ══════════════════════════════════════════════════════════
if (is_sliding && variable_global_exists("debug_collision") && global.debug_collision) {
    var _dc = draw_get_color();
    var _da = draw_get_alpha();

    draw_set_color(c_yellow);
    draw_set_alpha(0.30);
    draw_rectangle(x + col_left, y + col_top, x + col_right, y + col_bottom, false);
    draw_set_alpha(1.0);
    draw_rectangle(x + col_left, y + col_top, x + col_right, y + col_bottom, true);

    draw_set_color(make_color_rgb(255, 200, 0));
    draw_set_alpha(0.55);
    draw_line(x + col_left, y + normal_col_top, x + col_right, y + normal_col_top);

    draw_set_color(_dc);
    draw_set_alpha(_da);
}

// ══════════════════════════════════════════════════════════
// 5. DEBUG ANCLAS FÍSICAS
// Activo cuando debug_draw_anchors = true
// ══════════════════════════════════════════════════════════
if (debug_draw_anchors) {
    var _dc = draw_get_color();
    var _da = draw_get_alpha();
    draw_set_alpha(1.0);

    // Bbox de colisión (verde)
    draw_set_color(c_lime);
    draw_set_alpha(0.30);
    draw_rectangle(x + col_left, y + col_top, x + col_right, y + col_bottom, false);
    draw_set_alpha(1.0);
    draw_rectangle(x + col_left, y + col_top, x + col_right, y + col_bottom, true);

    // Origen = pies (rojo)
    draw_set_color(c_red);
    draw_circle(x, y, 4, false);

    // Spawn de flecha (cian)
    var _fire_f = (is_aiming) ? aim_facing : facing;
    var _ax = x + (_fire_f > 0 ? col_right + 8 : col_left - 8);
    var _ay = y + PLAYER_CHEST_Y;
    draw_set_color(c_aqua);
    draw_circle(_ax, _ay, 4, false);
    draw_set_alpha(0.6);
    draw_line(x, _ay, _ax, _ay);
    draw_set_alpha(1.0);

    // Área de espada (amarillo)
    var _hcx = x + facing * sword_hitbox_x;
    var _hcy = y + sword_hitbox_y;
    var _hx1 = _hcx - sword_hitbox_w * 0.5;
    var _hy1 = _hcy - sword_hitbox_h * 0.5;
    var _hx2 = _hcx + sword_hitbox_w * 0.5;
    var _hy2 = _hcy + sword_hitbox_h * 0.5;
    draw_set_color(c_yellow);
    draw_set_alpha(0.30);
    draw_rectangle(_hx1, _hy1, _hx2, _hy2, false);
    draw_set_alpha(1.0);
    draw_rectangle(_hx1, _hy1, _hx2, _hy2, true);
    draw_set_alpha(0.8);
    draw_line(_hcx - 3, _hcy, _hcx + 3, _hcy);
    draw_line(_hcx, _hcy - 3, _hcx, _hcy + 3);

    // Texto de referencia
    draw_set_alpha(1.0);
    draw_set_color(c_white);
    draw_text(x + col_right + 4, y + col_top - 2,
        "chest:" + string(PLAYER_CHEST_Y)
        + "  sword_x:" + string(sword_hitbox_x)
        + "  facing:" + string(facing));

    draw_set_color(_dc);
    draw_set_alpha(_da);
}

// ══════════════════════════════════════════════════════════
// 5b. DEBUG COLISIÓN (F10 → global.debug_collision)
//
// Muestra en world-space:
//   • Bbox de colisión (verde)
//   • Probes horizontales a lo largo del borde izq/der (cyan)
//   • Probes verticales a lo largo del borde sup/inf (amarillo)
//   • Probes de pared izq/der (magenta)
//   • Estado: grounded, wallContact, wallSide, corner_corrected
// ══════════════════════════════════════════════════════════
if (variable_global_exists("debug_collision") && global.debug_collision) {
    var _dc  = draw_get_color();
    var _da  = draw_get_alpha();
    var _STEP = 28;

    // ── Bbox ─────────────────────────────────────────────
    var _bx1 = x + col_left;
    var _by1 = y + col_top;
    var _bx2 = x + col_right;
    var _by2 = y + col_bottom;

    draw_set_alpha(0.20);
    draw_set_color(isGrounded ? c_lime : c_white);
    draw_rectangle(_bx1, _by1, _bx2, _by2, false);
    draw_set_alpha(0.90);
    draw_rectangle(_bx1, _by1, _bx2, _by2, true);

    // ── Probes de colisión HORIZONTAL (bordes izq/der) ──
    // Cyan = libre | Rojo = bloqueado
    draw_set_alpha(1.0);
    var _py = y + col_top + 1;
    var _py_end = y + col_bottom - 1;
    while (_py <= _py_end) {
        var _hit_l = tile_solid_at(collision_map, x + col_left  - 1, _py);
        var _hit_r = tile_solid_at(collision_map, x + col_right + 1, _py);
        draw_set_color(_hit_l ? c_red : c_aqua);
        draw_circle(x + col_left  - 1, _py, 2, false);
        draw_set_color(_hit_r ? c_red : c_aqua);
        draw_circle(x + col_right + 1, _py, 2, false);
        _py = (_py >= _py_end) ? _py_end + 1 : min(_py + _STEP, _py_end);
    }

    // ── Probes de colisión VERTICAL (borde sup/inf) ─────
    var _check_top = y + col_top - 1;
    var _check_bot = y + col_bottom + 1;
    var _probes_x = [x + col_left + 1, x, x + col_right - 1];
    var _labels_x = ["L", "C", "R"];
    for (var _pi = 0; _pi < 3; _pi++) {
        var _px_probe = _probes_x[_pi];
        var _hit_t = tile_solid_at(collision_map, _px_probe, _check_top);
        var _hit_b = tile_solid_at(collision_map, _px_probe, _check_bot);
        draw_set_alpha(1.0);
        draw_set_color(_hit_t ? c_red : c_yellow);
        draw_circle(_px_probe, _check_top, 2, false);
        draw_set_color(_hit_b ? c_red : c_yellow);
        draw_circle(_px_probe, _check_bot, 2, false);
    }

    // ── Punto de origen ───────────────────────────────────
    draw_set_color(c_red);
    draw_set_alpha(1.0);
    draw_circle(x, y, 3, false);

    // ── Panel de estado ───────────────────────────────────
    var _panel_x = x + col_right + 6;
    var _panel_y = y + col_top;
    var _lh      = 13;
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_black);
    draw_set_alpha(0.55);
    draw_rectangle(_panel_x - 2, _panel_y - 2, _panel_x + 120, _panel_y + _lh * 7, false);

    draw_set_alpha(1.0);
    var _col_states = [
        ["grounded",     isGrounded,        c_lime,   c_fuchsia],
        ["wallContact",  wallContact,        c_lime,   c_gray],
        ["wall L",       (wallSide == -1),   c_aqua,   c_gray],
        ["wall R",       (wallSide ==  1),   c_aqua,   c_gray],
        ["corner CC",    corner_corrected,   c_yellow, c_gray],
    ];
    var _ty = _panel_y + 2;
    for (var _si = 0; _si < array_length(_col_states); _si++) {
        var _label = _col_states[_si][0];
        var _val   = _col_states[_si][1];
        var _c_on  = _col_states[_si][2];
        var _c_off = _col_states[_si][3];
        draw_set_color(_val ? _c_on : _c_off);
        draw_text(_panel_x, _ty, _label + ": " + (_val ? "YES" : "no"));
        _ty += _lh;
    }
    // move_x / move_y
    draw_set_color(c_white);
    draw_text(_panel_x, _ty, "mx:" + string_format(move_x,1,1)
                            + " my:" + string_format(move_y,1,1));
    _ty += _lh;
    draw_text(_panel_x, _ty, "CC_MAX:8  PROBE:28px");

    draw_set_color(_dc);
    draw_set_alpha(_da);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}

// ══════════════════════════════════════════════════════════
// 6. INDICADOR DE ARCO
// Solo visible mientras el arco está cargado y la tecla presionada.
// El exit aquí es INTENCIONAL — solo detiene el indicador visual.
// Todo el debug está arriba, por eso no lo afecta.
// ══════════════════════════════════════════════════════════
if (!bow_is_charging || !global.inp.ranged_held) exit;

var _fire_facing = (is_aiming) ? aim_facing : facing;
var _rad   = degtorad(aim_angle);
var _dir_x = _fire_facing * cos(_rad);
var _dir_y = sin(_rad);

var _ox = x;
var _oy = y + PLAYER_CHEST_Y;

var _line_len = 80;
var _tip_x    = _ox + _dir_x * _line_len;
var _tip_y    = _oy + _dir_y * _line_len;

var _prev_color = draw_get_color();
var _prev_alpha = draw_get_alpha();

draw_set_color(make_color_rgb(255, 180, 0));
draw_set_alpha(0.75);
draw_line(_ox, _oy, _tip_x, _tip_y);

draw_set_alpha(1.0);
var _d = 5;
draw_triangle(
    _tip_x,      _tip_y - _d,
    _tip_x + _d, _tip_y,
    _tip_x - _d, _tip_y,
    false
);

draw_set_color(_prev_color);
draw_set_alpha(_prev_alpha);

// ══════════════════════════════════════════════════════════
// BEAT 'EM UP MODE — Red tint + hitbox debug
// (Barra de duración movida a Draw_GUI_0 para mejor visibilidad)
// ══════════════════════════════════════════════════════════
if (beat_em_up_active) {
    // ── Red tint (overlay sobre el sprite) ─────────────────
    var _old_alpha = draw_get_alpha();
    draw_set_alpha(0.3);
    draw_set_color(c_red);
    draw_rectangle(bbox_left, bbox_top, bbox_right, bbox_bottom, false);
    draw_set_alpha(_old_alpha);

    // ── Debug hitbox visualization ─────────────────────────
    if (variable_global_exists("debug_dev") && global.debug_dev && beat_em_up_attack_active) {
        draw_set_alpha(0.5);
        draw_set_color(c_yellow);

        var _hb_x, _hb_y, _hb_w, _hb_h;

        if (beat_em_up_attack_type == "punch") {
            _hb_x = x + (facing > 0 ? beat_punch_reach : -beat_punch_reach);
            _hb_y = y + beat_punch_offset_y;
            _hb_w = beat_punch_reach;
            _hb_h = beat_punch_height;
        } else if (beat_em_up_attack_type == "heavy") {
            _hb_x = x + (facing > 0 ? beat_heavy_reach : -beat_heavy_reach);
            _hb_y = y + beat_heavy_offset_y;
            _hb_w = beat_heavy_reach;
            _hb_h = beat_heavy_height;
        } else if (beat_em_up_attack_type == "uppercut") {
            _hb_x = x + (facing > 0 ? beat_uppercut_reach : -beat_uppercut_reach);
            _hb_y = y + beat_uppercut_offset_y;
            _hb_w = beat_uppercut_reach;
            _hb_h = beat_uppercut_height;
        } else {
            _hb_w = 0; _hb_h = 0;
        }

        if (_hb_w > 0 && _hb_h > 0) {
            draw_rectangle(_hb_x - _hb_w/2, _hb_y - _hb_h/2, _hb_x + _hb_w/2, _hb_y + _hb_h/2, false);
        }

        draw_set_alpha(_old_alpha);
    }
}

// ══════════════════════════════════════════════════════════
// DEBUG: MODO DEV — Info de estado del player
// ══════════════════════════════════════════════════════════
if (variable_global_exists("debug_dev") && global.debug_dev) {
    var _dbg_x = x - 60;
    var _dbg_y = y + col_bottom + 20;
    var _dbg_col = c_lime;

    draw_set_color(_dbg_col);
    draw_set_alpha(0.9);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);

    var _state_names = ["IDLE", "RUN", "JUMP", "FALL", "WALL", "ATTACK_1", "ATTACK_2", "ATTACK_3",
                        "DASH", "BLOCK", "DOWN_SLASH", "DASH_ATTACK", "COUNTER_ATTACK", "DEAD"];
    var _state_str = (_state_names[player_state] != undefined) ? _state_names[player_state] : string(player_state);

    draw_text(_dbg_x, _dbg_y, "[DEV] State: " + _state_str);
    draw_text(_dbg_x, _dbg_y + 12, "HP: " + string(hp) + "/" + string(max_hp));
    draw_text(_dbg_x, _dbg_y + 24, "Diff: " + get_difficulty_string());

    if (is_invulnerable) {
        draw_set_color(c_yellow);
        draw_text(_dbg_x, _dbg_y + 36, "INVULN: " + string(invuln_timer) + "f");
    }

    if (damage_recovery_lock) {
        draw_set_color(c_red);
        draw_text(_dbg_x, _dbg_y + 48, "LOCK: " + string(damage_recovery_lock_timer) + "f");
    }

    // Jump back info
    if (jump_back_input_timer > 0) {
        draw_set_color(make_color_rgb(100, 200, 255));
        draw_text(_dbg_x, _dbg_y + 60, "JB-WINDOW: " + string(jump_back_input_timer) + "f");
        draw_text(_dbg_x, _dbg_y + 72, "Stored facing: " + string(jump_back_stored_facing));
    }

    if (jump_back_active) {
        draw_set_color(make_color_rgb(0, 200, 255));
        draw_text(_dbg_x, _dbg_y + 60, "JUMPBACK ACTIVE: " + string(jump_back_timer) + "f");
        draw_text(_dbg_x, _dbg_y + 72, "Control-Lock: " + string(jump_back_control_lock_timer) + "f");
        if (jump_back_facing_locked) {
            draw_set_color(make_color_rgb(200, 100, 255));
            draw_text(_dbg_x, _dbg_y + 84, "FACING LOCKED: " + string(jump_back_stored_facing));
        }
    }

    // Beat 'em up mode debug
    if (beat_em_up_active) {
        draw_set_color(c_red);
        draw_text(_dbg_x, _dbg_y + 96, "BEAT 'EM UP: " + string(beat_em_up_timer) + "f  MODE:" + combat_mode);
        draw_text(_dbg_x, _dbg_y + 108, "Attack: " + beat_em_up_attack_type + " #" + string(beat_combo_index + 1));
        draw_text(_dbg_x, _dbg_y + 120, "Cooldown: " + string(beat_em_up_cooldown_timer) + "f");

        // Input display para debugging
        var _input_str = "Inputs: ";
        if (global.inp.attack_pressed) _input_str += "Z ";
        if (global.inp.ranged_pressed) _input_str += "X ";
        if (global.inp.move_axis < 0) _input_str += "UP ";
        if (global.inp.dash_pressed) _input_str += "DASH ";
        draw_set_color(make_color_rgb(200, 200, 0));
        draw_text(_dbg_x, _dbg_y + 132, _input_str);
    }
}
