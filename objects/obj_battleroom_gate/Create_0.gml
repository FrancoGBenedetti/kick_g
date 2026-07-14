// ══════════════════════════════════════════════════════════
// BATTLEROOM GATE — Create
//
// Límite manual de BattleRoom: se coloca y escala A MANO en el Room
// Editor (sprite guía spr_battleroom_gate_debug, origin top-left — misma
// convención que obj_battleroom_wall: (x,y) es la esquina superior
// izquierda del rectángulo sólido). Empieza SIN colisión (salvo
// active_on_start); la BattleRoom con el mismo encounter_id lo activa al
// entrar y lo desactiva al terminar (ver battleroom_activate_manual_gates
// / battleroom_deactivate_manual_gates en obj_battleroom_parent).
//
// Hereda de obj_dynamic_solid_parent — el mismo sistema que ya consulta
// level_solid_at() (tilemap + dynamic solids), así que colisión
// horizontal/vertical, dash, roll, wallslide y walljump del player lo
// detectan automáticamente sin tocar nada de ese código.
// ══════════════════════════════════════════════════════════

event_inherited();   // dynamic_solid_enabled/xoff/yoff/w/h + dynamic_solid_contains_point()

// El sprite guía solo importa en el Room Editor (para posicionar/escalar
// a ojo) — en gameplay se dibuja a mano en Draw (gate_is_debug()), así
// que el draw automático del sprite queda apagado.
visible = false;

encounter_id    = "";    // debe matchear el encounter_id de la BattleRoom dueña
gate_id         = "";    // etiqueta libre para debug
active_on_start = false; // true = ya sólido desde el arranque de la room (sin esperar a la BattleRoom)
debug_enabled   = true;

is_battleroom_gate = true;   // marca de identidad, útil para queries/debug
owner_battleroom    = noone; // lo setea la BattleRoom al activarlo (informativo)

/// @desc true si el debug de este gate está activo (local o global F1 —
/// misma convención que battleroom_is_debug()).
gate_is_debug = function() {
    return debug_enabled || (variable_global_exists("debug_battleroom") && global.debug_battleroom);
};

/// @desc Recalcula dynamic_solid_xoff/yoff/w/h desde el sprite ACTUAL
/// escalado (image_xscale/image_yscale) — así la colisión coincide
/// siempre con el rectángulo que se ve en el Room Editor, incluso si se
/// escaló el objeto después. Origin del sprite es top-left (0,0), igual
/// que obj_battleroom_wall, así que xoff/yoff quedan en 0 y solo cambia
/// el tamaño.
gate_recalculate_bounds = function() {
    if (!sprite_exists(sprite_index)) {
        dynamic_solid_xoff = 0;
        dynamic_solid_yoff = 0;
        dynamic_solid_w    = 0;
        dynamic_solid_h    = 0;
        return;
    }

    dynamic_solid_xoff = 0;
    dynamic_solid_yoff = 0;
    dynamic_solid_w    = sprite_width  * abs(image_xscale);
    dynamic_solid_h    = sprite_height * abs(image_yscale);
};

/// @desc Activa la colisión real del gate. Llamado por la BattleRoom
/// (battleroom_activate_manual_gates) al entrar. Recalcula bounds primero
/// por si se escaló el objeto en el Room Editor después del último cálculo.
gate_activate = function() {
    gate_recalculate_bounds();
    gate_enabled          = true;
    dynamic_solid_enabled = true;

    if (gate_is_debug()) {
        show_debug_message("[GATE] activated " + gate_id + " " + encounter_id);
    }
};

/// @desc Desactiva la colisión real del gate. Llamado por la BattleRoom
/// (battleroom_deactivate_manual_gates) al terminar.
gate_deactivate = function() {
    gate_enabled          = false;
    dynamic_solid_enabled = false;

    if (gate_is_debug()) {
        show_debug_message("[GATE] deactivated " + gate_id + " " + encounter_id);
    }
};

gate_recalculate_bounds();

gate_enabled           = active_on_start;
dynamic_solid_enabled  = gate_enabled;
