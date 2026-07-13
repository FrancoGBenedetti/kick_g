// ══════════════════════════════════════════════════════════
// OBJ_ENEMY_PARENT — Draw
// Solo dibuja overlays de debug cuando global.debug_enemy_collision
// está activo. No dibuja el sprite del enemigo (cada hijo lo hace).
//
// Los hijos que quieran incluir este debug deben llamar:
//   event_inherited();   // al FINAL de su propio Draw event
//
// Activar con F5 en runtime (toggle en obj_input/Step_1).
// ══════════════════════════════════════════════════════════
// ── Debug de IA (F6) ──────────────────────────────────────
if (variable_global_exists("debug_enemy_ai") && global.debug_enemy_ai) {
    var _dc2 = draw_get_color();
    var _da2 = draw_get_alpha();

    // Estado actual de la FSM sobre la cabeza del enemigo
    draw_set_alpha(1.0);
    draw_set_color(c_white);
    draw_set_halign(fa_center);
    draw_set_valign(fa_bottom);

    // Nombre del estado
    var _state_name = "???";
    if (estate == ESTATE_PATROL)       _state_name = "PATROL";
    else if (estate == ESTATE_CHASE)   _state_name = "CHASE";
    else if (estate == ESTATE_ATTACK)  _state_name = "ATTACK";
    else if (estate == ESTATE_STUN)    _state_name = "STUN";
    else if (estate == ESTATE_DEAD)    _state_name = "DEAD";
    // Estados extendidos del swordsman (valores 2-4 reutilizados con distinto significado)
    else if (variable_instance_exists(id, "ESTATE_ATTACK_WINDUP")
          && estate == ESTATE_ATTACK_WINDUP) _state_name = "WINDUP";
    else if (variable_instance_exists(id, "ESTATE_ATTACK_ACTIVE")
          && estate == ESTATE_ATTACK_ACTIVE) _state_name = "ACTIVE";
    else if (variable_instance_exists(id, "ESTATE_COOLDOWN")
          && estate == ESTATE_COOLDOWN)      _state_name = "COOLDOWN";
    else _state_name = "STATE:" + string(estate);

    // Flags en una sola línea
    var _flags = "";
    if (can_patrol)    _flags += "[P]";
    if (can_chase)     _flags += "[C]";
    if (can_drop_down) _flags += "[D]";
    if (is_blocked_by_enemy) { draw_set_color(c_orange); }

    draw_text(x, y + col_top - 18, _state_name + "  " + _flags);

    // Info de detección del jugador
    if (instance_exists(obj_player)) {
        var _adx = abs(obj_player.x - x);
        var _ady = abs(obj_player.y - y);
        draw_set_color(c_lime);
        draw_set_alpha(0.8);
        var _info = "dx:" + string(int64(_adx)) + " dy:" + string(int64(_ady));
        draw_text(x, y + col_top - 6, _info);

        // Indicar si jugador está arriba/abajo/mismo piso
        var _rel = "same";
        if (obj_player.y - y >  player_below_threshold) _rel = "below";
        else if (y - obj_player.y > player_below_threshold) _rel = "above";
        draw_set_color(c_yellow);
        draw_text(x, y + col_top + 6, _rel);
    }

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(_dc2);
    draw_set_alpha(_da2);
}

// ── Debug knockback del enemigo ───────────────────────────
if (variable_global_exists("debug_knockback") && global.debug_knockback) {
    var _dc_kb = draw_get_color();
    var _da_kb = draw_get_alpha();
    draw_set_alpha(1.0);
    draw_set_halign(fa_center);
    draw_set_valign(fa_bottom);

    var _kb_active = (hitstun_timer > 0);
    draw_set_color(_kb_active ? c_red : make_color_rgb(160,160,160));
    draw_text(x, y + col_top - 34,
        "KB:" + (_kb_active ? "ON" : "off")
        + "  hsp:" + string_format(knockback_x, 1, 1)
        + "  vsp:" + string_format(move_y, 1, 1)
        + "  stun:" + string(hitstun_timer) + "/" + string(default_hitstun)
        + "  ×" + string_format(enemy_knockback_multiplier, 1, 1));

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(_dc_kb);
    draw_set_alpha(_da_kb);
}

// ── Debug counter attack (enemigo vulnerable) ─────────────
if (variable_global_exists("debug_counterattack") && global.debug_counterattack) {
    var _dc_ca2 = draw_get_color();
    var _da_ca2 = draw_get_alpha();
    draw_set_alpha(1.0);
    draw_set_halign(fa_center);
    draw_set_valign(fa_bottom);

    draw_set_color(parried_vulnerable ? c_orange : make_color_rgb(140,140,140));
    draw_text(x, y + col_top - 50,
        "VUL:" + (parried_vulnerable ? "YES" : "no")
        + "  t:" + string(parried_vulnerable_timer)
        + "  ctr:" + (can_be_countered ? "YES" : "no"));

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(_dc_ca2);
    draw_set_alpha(_da_ca2);
}

// ── Debug de BattleRoom (F1) ───────────────────────────────
// Solo se muestra si este enemigo fue creado por obj_enemy_spawner
// (tiene battleroom_owner asignado).
if ((variable_global_exists("debug_battleroom") && global.debug_battleroom)
&& variable_instance_exists(id, "battleroom_owner")) {
    var _dc3 = draw_get_color();
    var _da3 = draw_get_alpha();

    draw_set_alpha(1);
    draw_set_halign(fa_center);
    draw_set_valign(fa_bottom);
    draw_set_color(c_aqua);

    var _owner_txt   = instance_exists(battleroom_owner) ? object_get_name(battleroom_owner.object_index) : "none";
    var _spawner_txt = (variable_instance_exists(id, "spawned_by_spawner") && instance_exists(spawned_by_spawner))
        ? spawned_by_spawner.spawner_id : "none";

    draw_text(x, y - 90, "[BR] owner:" + _owner_txt + "  id:" + string(battleroom_id));
    draw_text(x, y - 76, "spawner:" + _spawner_txt
        + "  reg:" + string(battleroom_enemy_registered)
        + "  died:" + string(battleroom_death_notified));

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(_dc3);
    draw_set_alpha(_da3);
}

// ── Debug de colisión entre enemigos (F5) ─────────────────
if (!variable_global_exists("debug_enemy_collision") || !global.debug_enemy_collision) exit;

var _dc = draw_get_color();
var _da = draw_get_alpha();

// ── Radio de separación ───────────────────────────────────
// Verde   = sin bloqueo
// Naranja = soft push activo (solapamiento)
// Rojo    = hard block activo (detenido por bloqueador)
var _hard = instance_exists(blocking_enemy_id);
var _col  = _hard
            ? c_red
            : (is_blocked_by_enemy ? make_color_rgb(255, 140, 0) : make_color_rgb(0, 200, 80));
draw_set_color(_col);
draw_set_alpha(0.15);
draw_circle(x, y, enemy_separation_radius, false);
draw_set_alpha(0.7);
draw_circle(x, y, enemy_separation_radius, true);

// ── Zona de detección frontal (hard block range) ──────────
// Rectángulo delante del enemigo mostrando enemy_block_distance.
if (move_x != 0 || is_blocked_by_enemy) {
    var _detect_dir = (move_x != 0) ? sign(move_x) : facing;
    var _edge_x     = (_detect_dir > 0) ? (x + col_right) : (x + col_left);
    var _zone_x1    = (_detect_dir > 0) ? _edge_x : (_edge_x - enemy_block_distance);
    var _zone_x2    = (_detect_dir > 0) ? (_edge_x + enemy_block_distance) : _edge_x;
    var _zone_y1    = y + col_top;
    var _zone_y2    = y + col_bottom;
    draw_set_color(_hard ? c_red : make_color_rgb(255, 200, 0));
    draw_set_alpha(0.18);
    draw_rectangle(_zone_x1, _zone_y1, _zone_x2, _zone_y2, false);
    draw_set_alpha(0.55);
    draw_rectangle(_zone_x1, _zone_y1, _zone_x2, _zone_y2, true);
}

// ── Línea hacia el bloqueador ─────────────────────────────
if (_hard && instance_exists(blocking_enemy_id)) {
    draw_set_color(c_red);
    draw_set_alpha(0.85);
    draw_line_width(x, y, blocking_enemy_id.x, blocking_enemy_id.y, 2);
    draw_set_alpha(1.0);
    draw_set_color(c_white);
    draw_set_halign(fa_center);
    draw_set_valign(fa_bottom);
    draw_text(x, y + col_top - 16, "BLOCKED BY: " + object_get_name(blocking_enemy_id.object_index));
}

// ── Cooldown de contacto ──────────────────────────────────
// Línea corta hacia el jugador si puede hacer daño (cooldown = 0).
if (instance_exists(obj_player) && contact_damage_enabled) {
    if (contact_damage_cooldown <= 0) {
        draw_set_color(c_red);
        draw_set_alpha(0.8);
        // Línea corta hacia el jugador (máx 24 px)
        var _dx = obj_player.x - x;
        var _dy = obj_player.y - y;
        var _len = min(sqrt(_dx*_dx + _dy*_dy), 24);
        var _ang = point_direction(x, y, obj_player.x, obj_player.y);
        draw_line_width(x, y,
            x + lengthdir_x(_len, _ang),
            y + lengthdir_y(_len, _ang), 2);
    }
}

// ── Líneas hacia vecinos: razón de bloqueo o paso ─────────
// Color / label según las nuevas condiciones del sistema unificado:
//   ROJO   "hard blocked"    → este enemigo está detenido por el vecino (hard block activo)
//   VERDE  "active"          → mismo piso + ambos flags → separación/bloqueo activos
//   NARANJA "no-block flag"  → vecino no bloquea (blocks_other_enemies=false)
//   GRIS   "diff floor"      → diferente piso → se ignoran
with (obj_enemy_parent) {
    if (id == other.id) continue;

    var _ndx   = other.x - x;
    var _ndy   = other.y - y;
    var _ndist = sqrt(_ndx * _ndx + _ndy * _ndy);
    if (_ndist > other.enemy_separation_radius * 6) continue;   // demasiado lejos, no dibujar

    var _label    = "";
    var _col      = c_white;
    var _diff_floor     = (abs(_ndy) > other.enemy_same_floor_tolerance);
    var _no_block_flag  = (!blocks_other_enemies || !other.blocked_by_other_enemies);
    var _is_my_blocker  = (other.blocking_enemy_id == id);

    if (_is_my_blocker) {
        _col   = c_red;
        _label = "BLOCKING";
    } else if (_diff_floor) {
        _col   = make_color_rgb(140, 140, 140);
        _label = "diff floor";
    } else if (_no_block_flag) {
        _col   = make_color_rgb(255, 160, 40);
        _label = "no-block flag";
    } else {
        _col   = make_color_rgb(80, 230, 80);
        _label = "active";
    }

    draw_set_color(_col);
    draw_set_alpha(0.5);
    draw_line(x, y, other.x, other.y);
    draw_set_alpha(0.9);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text((x + other.x) * 0.5, (y + other.y) * 0.5 - 6, _label);
}

// ── Etiquetas de estado ───────────────────────────────────
draw_set_alpha(1.0);
draw_set_color(c_white);
draw_set_halign(fa_center);
draw_set_valign(fa_bottom);

var _label = "";
if (is_blocked_by_enemy)         _label += "BLOCKED ";
if (contact_damage_cooldown > 0) _label += "CD:" + string(contact_damage_cooldown) + " ";
else if (contact_damage_enabled) _label += "DMG-RDY ";

if (_label != "") {
    draw_text(x, y + col_top - 4, string_trim(_label));
}

draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(_dc);
draw_set_alpha(_da);
