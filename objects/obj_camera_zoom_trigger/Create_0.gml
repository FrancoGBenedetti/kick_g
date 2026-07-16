// ══════════════════════════════════════════════════════════
// CAMERA ZOOM TRIGGER — Create
//
// Trigger de cambio de zoom de cámara por CRUCE DE X — no colisión
// rectangular, no importa la Y del player, no hay que ajustar altura de
// sprite. Cuando el player cruza x (en cualquiera de las dos direcciones)
// llama al sistema de zoom REAL que ya existe en el proyecto
// (CameraViewMode + obj_camera_controller.camera_set_view_mode()) — no
// crea ningún enum ni sistema de cámara paralelo. La transición suave ya
// la da camera_set_view_mode() sin _instant (usa zoom_lerp del camera
// controller, el mismo smoothing que K/L ya usan) — no hace falta
// duplicar esa lógica acá.
//
// trigger_mode es informativo/debug — solo existe X_CROSS_VERTICAL, no se
// creó un enum CameraTriggerMode para un solo valor posible.
//
// last_player_x en vez de xprevious: seguimiento manual y explícito del
// x del player frame a frame, para que quede 100% claro en debug qué
// valores se están comparando (pedido explícito, además de sacarse de
// encima cualquier duda sobre xprevious).
// ══════════════════════════════════════════════════════════

enabled = true;

// CameraViewMode ya existe en scr_config.gml (CLOSE/DEFAULT/FAR) — target_
// camera_zoom guarda uno de esos valores directamente. Los hijos (obj_
// camera_zoom_trigger_far/normal/close) solo pisan esta variable.
target_camera_zoom = CameraViewMode.DEFAULT;

trigger_mode = "X_CROSS_VERTICAL";   // informativo — único modo soportado

trigger_once    = false;   // false = puede reactivarse (con cooldown) cada vez que se cruza
activated       = false;
activated_count = 0;
activated_frame = -1;      // último frame (current_time-based) en que se activó — debug
cooldown_frames = 15;
cooldown_timer  = 0;

trigger_id    = "";     // etiqueta libre para debug
debug_enabled = true;

// Seguimiento manual de la X del player — se actualiza al FINAL de cada
// Step (ver abajo), así que en el próximo Step "last_player_x" es
// confiablemente la posición de un frame atrás, sin depender de
// xprevious. -99999 = "todavía no visto al player" (no dispara cruce en
// el primer frame).
last_player_x = -99999;

/// @desc true si el debug de este trigger está activo (local o global F1 —
/// misma convención que el resto del debug del proyecto).
zoom_trigger_is_debug = function() {
    return debug_enabled || (variable_global_exists("debug_battleroom") && global.debug_battleroom);
};

/// @desc Nombre legible de target_camera_zoom, para debug.
zoom_trigger_get_target_name = function() {
    switch (target_camera_zoom) {
        case CameraViewMode.CLOSE: return "CLOSE";
        case CameraViewMode.FAR:   return "FAR";
        default:                    return "NORMAL";   // CameraViewMode.DEFAULT
    }
};

/// @desc Nombre legible del zoom ACTUAL de la cámara (camera_view_index en
/// obj_camera_controller — esa variable YA es "el zoom actual", no se
/// agregó una current_camera_zoom_mode duplicada).
zoom_trigger_get_camera_current_name = function() {
    if (!instance_exists(obj_camera_controller)) return "n/a";
    var _idx = -1;
    with (obj_camera_controller) { _idx = camera_view_index; }
    switch (_idx) {
        case CameraViewMode.CLOSE: return "CLOSE";
        case CameraViewMode.FAR:   return "FAR";
        case CameraViewMode.DEFAULT: return "NORMAL";
        default: return "unknown(" + string(_idx) + ")";
    }
};

/// @desc Aplica el zoom real vía obj_camera_controller.camera_set_view_
/// mode() — la función que YA existe y ya usan K/L y BattleRoom. Sin
/// _instant, así que respeta el smoothing normal (zoom_lerp) — sin salto
/// brusco. Esto ES lo que hace que "el último trigger cruzado manda":
/// camera_set_view_mode() escribe target_camera_width/height en el
/// camera controller (estado real, no una var temporal del trigger), y
/// nada más en el proyecto lo pisa después — el próximo trigger cruzado
/// simplemente lo vuelve a escribir.
camera_zoom_trigger_activate = function() {
    if (instance_exists(obj_camera_controller)) {
        with (obj_camera_controller) {
            camera_set_view_mode(other.target_camera_zoom);
        }
    }

    activated       = true;
    activated_count++;
    activated_frame = current_time;
    if (!trigger_once) {
        cooldown_timer = cooldown_frames;
    }

    if (zoom_trigger_is_debug()) {
        show_debug_message("[CAMERA ZOOM TRIGGER] applying zoom = " + zoom_trigger_get_target_name());
        show_debug_message("[CAMERA ZOOM TRIGGER] camera current zoom after = " + zoom_trigger_get_camera_current_name());
    }
};
