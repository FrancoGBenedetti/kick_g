// ══════════════════════════════════════════════════════════
// TRIGGER ON COLLISION — Create
//
// Trigger completamente genérico. Su única responsabilidad: detectar
// colisión con un activador (por defecto obj_player) y emitir una señal
// (signal_id) cuando eso pasa. No sabe qué es una BattleRoom, un spawner,
// cámara, música ni recompensa — nada de eso.
//
// Cualquier instancia que tenga listen_signal_id == signal_id Y un método
// on_trigger_activated(_trigger, _activator) recibe el aviso. Hoy los
// receptores existentes son obj_battleroom_parent y obj_enemy_spawner,
// listados en signal_target_objects — agregar más ahí si aparecen otros
// receptores en el futuro (el trigger sigue sin conocer sus detalles).
//
// Reemplaza conceptualmente a obj_battleroom_trigger (que quedó atado a
// battleroom_id + battleroom_start() directo). obj_battleroom_trigger no
// se borró — sigue funcionando para lo que ya esté armado con él.
// ══════════════════════════════════════════════════════════

enabled      = true;
trigger_once = true;
used         = false;

activator_object = obj_player;

signal_id = "";

// Tipos de objeto que pueden estar escuchando señales. El trigger no
// necesita saber nada de ellos más que "puede que tengan
// listen_signal_id y on_trigger_activated".
signal_target_objects = [obj_battleroom_parent, obj_enemy_spawner];

// ── Zona de detección ─────────────────────────────────────
// Sin sprite/mask propio: rectángulo manual (mismo patrón que
// obj_trap_parent / obj_battleroom_trigger). (x, y) = punto base/pies.
trigger_w = 80;
trigger_h = 160;

was_touching_activator = false;   // activa solo al ENTRAR en contacto, no cada frame que se solapan

debug_enabled = false;


// ════════════════════════════════════════════════════════════
// FUNCIONES INTERNAS
// ════════════════════════════════════════════════════════════

/// @desc true si el debug del trigger está activo (local o global, mismo
/// flag que el resto del sistema — F1 en obj_input).
trigger_is_debug = function() {
    return debug_enabled || (variable_global_exists("debug_battleroom") && global.debug_battleroom);
};

/// @desc Devuelve la instancia del activador tocando el trigger, o noone.
trigger_find_activator = function() {
    if (activator_object == noone || !object_exists(activator_object)) return noone;

    var _x1 = x - trigger_w * 0.5;
    var _y1 = y - trigger_h;
    var _x2 = _x1 + trigger_w;
    var _y2 = y;

    return collision_rectangle(_x1, _y1, _x2, _y2, activator_object, false, true);
};

/// @desc Emite signal_id a todas las instancias de signal_target_objects
/// que estén escuchando esa señal (listen_signal_id == signal_id) y
/// tengan el método on_trigger_activated. Nunca crashea si un receptor
/// no existe o no implementa el método.
trigger_emit_signal = function(_activator) {
    if (signal_id == "") {
        if (trigger_is_debug()) {
            show_debug_message("[TRIGGER] warning: signal_id is empty");
        }
        return;
    }

    var _notified = 0;
    var _self_id  = id;

    for (var i = 0; i < array_length(signal_target_objects); i++) {
        var _obj = signal_target_objects[i];
        if (_obj == noone || !object_exists(_obj)) continue;

        with (_obj) {
            if (!variable_instance_exists(id, "listen_signal_id")) continue;
            if (listen_signal_id != other.signal_id) continue;
            if (!variable_instance_exists(id, "on_trigger_activated")) continue;

            on_trigger_activated(_self_id, _activator);
            _notified++;
        }
    }

    if (trigger_is_debug()) {
        show_debug_message("[TRIGGER] signal emitted: " + signal_id + " (" + string(_notified) + " listener(s))");
    }
};

/// @desc Dibuja la zona del trigger y su estado. Llamar desde Draw (world space).
trigger_debug_draw = function() {
    if (!trigger_is_debug()) return;

    var _x1 = x - trigger_w * 0.5;
    var _y1 = y - trigger_h;
    var _x2 = _x1 + trigger_w;
    var _y2 = y;

    draw_set_alpha(0.35);
    draw_set_color(enabled ? c_lime : c_gray);
    draw_rectangle(_x1, _y1, _x2, _y2, false);
    draw_set_alpha(1);

    var _activator_name = (activator_object == noone) ? "none" : object_get_name(activator_object);

    draw_set_color(c_white);
    draw_text(_x1, _y1 - 48, "[Trigger] signal: " + signal_id);
    draw_text(_x1, _y1 - 34, "activator: " + _activator_name);
    draw_text(_x1, _y1 - 20, "used: " + string(used) + "  enabled: " + string(enabled));
};
