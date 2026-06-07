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

// ── Debug de colisión entre enemigos (F5) ─────────────────
if (!variable_global_exists("debug_enemy_collision") || !global.debug_enemy_collision) exit;

var _dc = draw_get_color();
var _da = draw_get_alpha();

// ── Radio de separación ───────────────────────────────────
// Círculo/caja que muestra el umbral de repulsión.
// Verde = sin contacto con otro enemigo.
// Naranja = empujando a otro enemigo.
var _col = is_blocked_by_enemy ? make_color_rgb(255, 140, 0) : make_color_rgb(0, 200, 80);
draw_set_color(_col);
draw_set_alpha(0.15);
draw_circle(x, y, enemy_separation_radius, false);
draw_set_alpha(0.7);
draw_circle(x, y, enemy_separation_radius, true);

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
// Color / label según la condición que determina si se bloquean o no.
//
//   VERDE  "queue/block"      → ambos en aggro + cerca + mismo piso → separación activa
//   NARANJA "patrol pass"     → al menos uno patrulla → se cruzan
//   CYAN   "not close enough" → alguno está lejos del jugador → se cruzan
//   GRIS   "diff floor"       → diferente piso → se cruzan
with (obj_enemy_parent) {
    if (id == other.id) continue;

    var _ndx   = other.x - x;
    var _ndy   = other.y - y;
    var _ndist = sqrt(_ndx * _ndx + _ndy * _ndy);
    if (_ndist > other.enemy_separation_radius * 5) continue;   // demasiado lejos, no dibujar

    // Evaluar cada condición en orden (misma lógica que Step)
    var _label = "";
    var _col   = c_white;

    var _diff_floor = (abs(_ndy) > other.enemy_same_floor_tolerance);
    var _patrol_pass = (other.estate == ESTATE_PATROL || estate == ESTATE_PATROL);
    var _p_exists    = instance_exists(obj_player);
    var _not_close   = false;
    if (_p_exists) {
        var _caller_dp   = point_distance(other.x, other.y, obj_player.x, obj_player.y);
        var _neighbor_dp = point_distance(x, y, obj_player.x, obj_player.y);
        _not_close = (_caller_dp >= other.enemy_queue_distance_to_player
                   || _neighbor_dp >= enemy_queue_distance_to_player);
    } else {
        _not_close = true;
    }

    if (_diff_floor) {
        _col   = make_color_rgb(140, 140, 140);
        _label = "diff floor";
    } else if (_patrol_pass) {
        _col   = make_color_rgb(255, 160, 40);
        _label = "patrol pass";
    } else if (_not_close) {
        _col   = make_color_rgb(0, 200, 220);
        _label = "not close";
    } else {
        _col   = make_color_rgb(80, 230, 80);
        _label = "queue/block";
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
