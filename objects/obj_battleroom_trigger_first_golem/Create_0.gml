// ══════════════════════════════════════════════════════════
// BATTLEROOM TRIGGER — Create
//
// Activa una BattleRoom (cualquier hijo de obj_battleroom_parent,
// sea obj_battleroom_template o una sala concreta) por battleroom_id
// cuando el jugador lo toca.
//
// Responsabilidad única: detectar al jugador, encontrar la sala por
// id y llamar battleroom_start(). NO controla cámara, spawn, paredes,
// recompensa, música ni conteo de enemigos — eso es de
// obj_battleroom_parent.
// ══════════════════════════════════════════════════════════

target_battleroom_id = "";

trigger_once = true;
used         = false;
enabled      = true;

debug_enabled = false;

// ── Zona de detección ─────────────────────────────────────
// Este objeto no tiene sprite/mask propio, así que la detección usa
// un rectángulo manual (mismo patrón que obj_trap_parent) en vez de
// place_meeting. (x, y) se toma como el punto base/pies del trigger.
// Ajustar trigger_w/trigger_h según el tamaño real de cada trigger.
trigger_w = 80;
trigger_h = 160;

// ── Estado interno ─────────────────────────────────────────
was_touching_player = false;   // activa solo al ENTRAR en contacto, no cada frame que se solapan


// ════════════════════════════════════════════════════════════
// FUNCIONES INTERNAS
// ════════════════════════════════════════════════════════════

/// @desc true si el debug del trigger está activo. Mismo flag global que
/// obj_battleroom_parent (F1 en obj_input), más un flag local propio.
battleroom_trigger_is_debug = function() {
    return debug_enabled || (variable_global_exists("debug_battleroom") && global.debug_battleroom);
};

/// @desc true si el jugador está tocando la zona del trigger.
battleroom_trigger_check_player = function() {
    if (!instance_exists(obj_player)) return false;

    var _x1 = x - trigger_w * 0.5;
    var _y1 = y - trigger_h;
    var _x2 = _x1 + trigger_w;
    var _y2 = y;

    return collision_rectangle(_x1, _y1, _x2, _y2, obj_player, false, true) != noone;
};

/// @desc Busca la BattleRoom con battleroom_id == target_battleroom_id entre
/// TODOS los hijos de obj_battleroom_parent (with() incluye subtipos, así que
/// funciona igual con obj_battleroom_template que con una sala concreta).
/// Devuelve noone si no hay ninguna, o la primera si hay más de una (con warning).
battleroom_trigger_find_room = function() {
    var _found       = noone;
    var _match_count = 0;

    with (obj_battleroom_parent) {
        if (battleroom_id == other.target_battleroom_id) {
            _match_count++;
            if (_match_count == 1) _found = id;
        }
    }

    if (_match_count > 1 && battleroom_trigger_is_debug()) {
        show_debug_message("[BATTLEROOM TRIGGER] warning: multiple BattleRooms found for ID: " + target_battleroom_id);
    }

    return _found;
};

/// @desc Punto de entrada: intenta activar la BattleRoom objetivo.
/// Protegida contra id vacío, sala inexistente y duplicados (todo con warning,
/// nunca crashea). battleroom_start() del lado del parent también se protege
/// contra activaciones repetidas, así que esta función es segura de llamar
/// más de una vez si trigger_once == false.
battleroom_trigger_activate = function() {
    if (target_battleroom_id == "") {
        if (battleroom_trigger_is_debug()) {
            show_debug_message("[BATTLEROOM TRIGGER] warning: target_battleroom_id is empty");
        }
        return;
    }

    var _target_room = battleroom_trigger_find_room();

    if (_target_room == noone) {
        if (battleroom_trigger_is_debug()) {
            show_debug_message("[BATTLEROOM TRIGGER] warning: no BattleRoom found for ID: " + target_battleroom_id);
        }
        return;
    }

    _target_room.battleroom_start();

    if (trigger_once) {
        used = true;
    }

    if (battleroom_trigger_is_debug()) {
        show_debug_message("[BATTLEROOM TRIGGER] " + target_battleroom_id + ": activated");
    }
};

/// @desc Dibuja la zona del trigger y su estado. Llamar desde Draw (world space).
/// No dibuja nada si el debug está apagado.
battleroom_trigger_debug_draw = function() {
    if (!battleroom_trigger_is_debug()) return;

    var _x1 = x - trigger_w * 0.5;
    var _y1 = y - trigger_h;
    var _x2 = _x1 + trigger_w;
    var _y2 = y;

    draw_set_alpha(0.35);
    draw_set_color(enabled ? c_lime : c_gray);
    draw_rectangle(_x1, _y1, _x2, _y2, false);
    draw_set_alpha(1);

    draw_set_color(c_white);
    draw_text(_x1, _y1 - 34, "id: " + target_battleroom_id);
    draw_text(_x1, _y1 - 20, "used: " + string(used) + "  enabled: " + string(enabled));
};
