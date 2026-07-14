// ══════════════════════════════════════════════════════════
// BATTLEROOM PARENT — Create
//
// Núcleo lógico reutilizable de una BattleRoom normal (no boss).
// Controla: estado, activación, spawn, conteo de enemigos, bloqueo
// de avance, comunicación con cámara, recompensa opcional, música
// opcional y debug.
//
// Este objeto NO tiene configuración de una sala concreta (ids,
// enemy_object, camera_mode específico, etc). Eso lo define el
// hijo/template en su propio Create Event, DESPUÉS de llamar a
// event_inherited().
//
// Jerarquía prevista:
//   obj_battleroom_parent
//     ↓ hereda
//   obj_battleroom_template
//     ↓ se clona
//   obj_battleroom_<sala_concreta>
// ══════════════════════════════════════════════════════════

// ── Identidad ──────────────────────────────────────────────
battleroom_id    = "";
encounter_id     = "";   // agrupa obj_enemy_spawner que pertenecen a esta sala
listen_signal_id = "";   // signal_id que un obj_trigger_on_collision debe emitir para activarla

// ── Estado ─────────────────────────────────────────────────
// El flujo principal de la BattleRoom depende de battleroom_state,
// no de booleanos sueltos. started/completed/cleared son auxiliares
// de consulta rápida (p.ej. desde un trigger), no controlan el switch.
battleroom_state  = BattleRoomState.WAITING;
previous_state    = BattleRoomState.WAITING;
state_timer       = 0;   // frames transcurridos desde el último cambio de estado

started   = false;
active    = false;   // true entre ENTERING y CLEARING (sala "en curso") — para debug y checks externos
completed = false;
cleared   = false;

trigger_once  = true;   // no reactivar una vez completada
can_retrigger = false;  // override explícito: permite reactivar aunque trigger_once esté activo
// NOTA: can_retrigger solo afecta el chequeo de completed+trigger_once en
// battleroom_start(). No resetea battleroom_state a WAITING por sí solo —
// eso queda fuera de este paso (FINISHED es terminal para salas normales).

// ── Enemigos / Spawners ────────────────────────────────────
// La BattleRoom ya NO crea enemigos directamente — delega en
// obj_enemy_spawner (uno o más, agrupados por encounter_id). Pero SÍ es la
// fuente de verdad de enemy_alive_count: cada enemigo que un spawner crea
// para esta sala se registra acá directamente (battleroom_register_enemy),
// y avisa acá directamente al morir (battleroom_on_enemy_died). Eso es lo
// que decide la transición ACTIVE → CLEARING.
enemy_alive_count = 0;
enemy_total_count = 0;
active_enemies    = [];   // ids de enemigos vivos registrados en esta sala

// spawner_total_count/spawner_completed_count quedan como bookkeeping del
// lado de los spawners (útil para debug y para el día que haya waves/delays
// por spawner), pero NO son lo que decide CLEARING — eso lo decide
// enemy_alive_count directamente.
spawner_total_count     = 0;
spawner_completed_count = 0;
active_spawners         = [];   // ids de obj_enemy_spawner registrados para esta sala

// ── Paredes temporales / bloqueo de avance ────────────────
use_temp_walls      = true;
wall_left_enabled   = true;
wall_right_enabled  = true;
wall_top_enabled    = true;    // techo — evita salir saltando por arriba de la arena
wall_bottom_enabled = false;   // piso — apagado por default (puede romper caídas/plataformas)
wall_instances       = [];

// ── Gates manuales (obj_battleroom_gate) ──────────────────
// Alternativa a las walls generadas por código: obj_battleroom_gate se
// coloca y escala A MANO en el Room Editor (no depende de arena_*, walls
// ni cámara). battleroom_activate_manual_gates()/battleroom_deactivate_
// manual_gates() los buscan por encounter_id y prenden/apagan su colisión
// — ver esas funciones más abajo. Independiente de use_temp_walls: podés
// usar gates, walls, ninguno, o ambos.
use_manual_gates       = false;
manual_gate_instances  = [];

// ── Cámara ─────────────────────────────────────────────────
// CameraViewMode viene de scr_config.gml (CLOSE / DEFAULT / FAR) — es el
// ZOOM/tamaño de vista, ya existía desde el primer paso.
// BattleRoomCameraBoundsMode (también en scr_config.gml) es un concepto
// DISTINTO y nuevo: decide si la cámara queda limitada al ÁREA de la
// arena o no. No lo mezclamos con camera_mode para no romper el zoom.
// lock_camera ya existía como el interruptor general de "esta BattleRoom
// toca la cámara sí o no" — lo reusamos tal cual, no se agregó
// camera_lock_enabled como variable duplicada.
camera_mode        = CameraViewMode.DEFAULT;
camera_bounds_mode = BattleRoomCameraBoundsMode.DEFAULT;
lock_camera        = true;

camera_restore_on_finish = true;   // si false, la cámara queda con el bounds override puesto al llegar a FINISHED

// 0 = usar el default de obj_camera_controller (bounds_transition_duration).
// Permite que esta BattleRoom en particular pida una transición visual de
// cámara más lenta/rápida sin tocar el default global. No retrasa la
// creación de walls — walls es instantáneo, esto es solo cuánto tarda la
// cámara en ACOMODARSE VISUALMENTE a la arena (ver battleroom_apply_camera).
camera_transition_duration = 0;

// ── Bounds activos (fuente única para walls / placement / cámara) ─
// active_left/right/top/bottom es lo que REALMENTE usan battleroom_place_
// player_inside(), battleroom_lock_player_progress() y battleroom_apply_
// camera() — nunca arena_* ni camera_target_* directamente. Los llena
// battleroom_get_active_bounds() según camera_bounds_mode:
//   CENTER_ON_ARENA → camera_target_* (vista de cámara centrada en esta
//                      instancia, ver battleroom_get_target_camera_bounds)
//   cualquier otro  → arena_* (comportamiento previo, sin cambios)
// Evita que arena y cámara queden desincronizadas (esa desincronización
// era la causa de que el player pudiera salir aunque la cámara estuviera
// "lockeada": los walls se armaban con un rectángulo y la cámara mostraba
// otro).
active_left   = 0;
active_right  = 0;
active_top    = 0;
active_bottom = 0;

// Salida de battleroom_get_target_camera_bounds() — bordes de la vista de
// cámara OBJETIVO (target_camera_width/height del camera controller, no la
// vista actual en medio de un lerp) centrada en (x,y) de esta instancia.
camera_target_left   = 0;
camera_target_right  = 0;
camera_target_top    = 0;
camera_target_bottom = 0;

// ── Arena ──────────────────────────────────────────────────
// BUG CORREGIDO: el default anterior era RELATIVE_TO_OBJECT, lo que
// pisaba SILENCIOSAMENTE cualquier arena_left/right/top/bottom puesto a
// mano en Creation Code (battleroom_update_arena_bounds() los recalculaba
// desde x,y de la instancia + arena_width/height, ignorando los valores
// manuales). Eso es lo que causaba el bug real: cámara/walls se creaban
// en una zona distinta a la configurada, y el player quedaba "afuera" de
// esa zona real sin que las walls lo bloquearan (porque nunca estuvo dentro).
// Default ahora: MANUAL — si configurás arena_left/right/top/bottom a
// mano, se respetan tal cual. Usar RELATIVE_TO_OBJECT explícitamente solo
// si de verdad querés que el objeto BattleRoom sea el centro calculado.
arena_bounds_mode = BattleRoomArenaBoundsMode.MANUAL;

arena_width    = 1200;   // ancho de la arena (solo se usa en RELATIVE_TO_OBJECT)
arena_height   = 700;    // alto de la arena (solo se usa en RELATIVE_TO_OBJECT)
arena_offset_x = 0;      // desplaza el centro de la arena respecto a (x,y) de esta instancia
arena_offset_y = 0;

arena_center_x = 0;   // calculado por battleroom_update_arena_bounds() — informativo/debug
arena_center_y = 0;

// En RELATIVE_TO_OBJECT estos 4 son SALIDA calculada (no editar a mano, se
// sobreescriben cada vez que corre battleroom_update_arena_bounds()). En
// MANUAL son la config real, exactamente como funcionaban antes.
arena_left   = 0;
arena_right  = 0;
arena_top    = 0;
arena_bottom = 0;

// ── Reubicación del player dentro de la arena (ENTERING) ──────
// Reemplaza al push animado (lerp multi-frame) de la versión anterior: la
// reubicación ahora es INSTANTÁNEA, dentro del mismo frame que congela al
// player, calcula la arena, mueve, aplica cámara, crea walls y libera al
// player — todo en state_timer==1 de ENTERING. Con las walls naciendo
// inmediatamente después, animar el movimiento ya no tenía sentido: el
// player terminaba "empujando" contra una pared sólida en vez de
// deslizarse. Por defecto está apagado (push_player_inside = false), así
// que no cambia nada para BattleRooms que no lo configuren.
push_player_inside = false;

entry_target_x = 0;   // 0 = auto (borde más cercano si está afuera, o clamp si ya estaba adentro)
entry_target_y = 0;   // 0 = no tocar la Y del player, salvo que quede fuera de arena_top/bottom

// push_duration ahora es cuántos frames dura el freeze de input del player
// durante la reubicación (antes era la duración de la animación). Un
// freeze muy breve alcanza porque el movimiento ya es instantáneo — no
// hace falta mantenerlo congelado "viajando".
push_duration = 20;   // frames de freeze — con <= 0 se fuerza a 1

push_start_x  = 0;   // posición del player ANTES de reubicar — informativo/debug
push_start_y  = 0;
push_target_x = 0;   // posición final resuelta (clamp aplicado) — informativo/debug
push_target_y = 0;

push_lock_input   = true;   // congela input del player durante la reubicación (reusa damage_recovery_lock)
push_safe_margin  = 96;     // px — margen desde los bordes de arena para la posición segura
force_entry_push  = false;  // true = reubicar igual aunque el player ya esté dentro del margen seguro
// NOTA: push_lock_input/push_duration (arriba) ya NO se usan en la
// secuencia de ENTERING por defecto — el freeze real ahora lo hace
// freeze_player_on_start/freeze_player_duration (bloque de abajo), que
// corrige un bug real: antes battleroom_freeze_player_for_entry() y
// battleroom_release_player_after_entry() se llamaban ambas en el MISMO
// frame (state_timer==1), así que el freeze duraba ~0 frames efectivos —
// el player nunca quedaba realmente congelado. Quedan definidas por si
// algo las llama manualmente, pero no forman parte del flujo normal.

// ── [LEGACY] Freeze físico de entrada — YA NO se llama por defecto ────
// Estrategia anterior: cortaba velocidad y cancelaba dash/roll/estado.
// Reemplazada por el bloqueo de SOLO input de abajo (input-only lock +
// intro de cámara) porque el freeze físico dejaba al player pegado/sin
// caer en algunos casos. Las funciones (battleroom_freeze_player_for_
// start/clear_player_velocity_for_start/cancel_player_movement_states_
// for_start) siguen definidas por si algo las llama a mano, pero
// battleroom_state_entering() ya no las invoca. Defaults en false para
// que sea explícito que están apagadas.
freeze_player_on_start                  = false;
freeze_player_duration                  = 10;    // frames — con <= 0 se fuerza a 1
clear_player_velocity_on_start          = false;
cancel_player_movement_states_on_start  = false;

// Countdown PARALELO al del player, solo para poder loguear "player
// released" si algo llama al freeze legacy a mano — no controla el lock
// real, eso lo sigue haciendo el player con su propio damage_recovery_
// lock_timer.
player_freeze_debug_timer = 0;

// ── Intro de cámara + input-only lock (estrategia actual) ─────
// Al activarse la BattleRoom: gates YA se activan de una (el player no
// necesita estar "empujado" adentro, vos limitás manualmente con gates/
// colisión propia). Mientras la cámara viaja hacia el objeto BattleRoom,
// el player pierde SOLO el input (ver input_only_lock en obj_player) —
// física, gravedad, dash/roll en curso NO se tocan. Cuando la cámara
// llega (por distancia o por timeout) o si camera_center_on_start está
// apagado, la cámara vuelve a seguir al player, se libera el input, y
// recién ahí arrancan los spawners (SPAWNING).
camera_center_on_start                 = true;   // false = sin intro, ENTERING instantáneo (comportamiento viejo)
camera_return_to_player_after_intro    = true;   // false = cámara queda mirando al BattleRoom (uso avanzado)
battle_camera_intro_duration           = 45;     // frames — techo máximo del intro, aunque la cámara nunca "llegue"
battle_camera_intro_arrive_distance    = 8;      // px — distancia centro-cámara↔BattleRoom para dar el intro por terminado
lock_player_input_during_camera_intro  = true;   // false = no tocar el input del player durante el intro

intro_last_distance = -1;   // informativo/debug — última distancia medida cámara↔BattleRoom

// ── Recompensa opcional ──────────────────────────────────────
reward_enabled = false;
reward_object  = noone;
reward_x       = 0;
reward_y       = 0;
reward_given   = false;

// ── Música opcional ──────────────────────────────────────────
change_music           = false;
battle_music            = noone;
restore_previous_music  = true;

// ── Debug ──────────────────────────────────────────────────
// debug_enabled es el flag local del objeto. También se puede activar
// globalmente con F1 (ver obj_input/Step_1.gml → global.debug_battleroom),
// siguiendo la misma convención que el resto del debug del proyecto
// (F3/F5/F6/F7/F8/F9/F10/F11).
debug_enabled = false;


// ════════════════════════════════════════════════════════════
// FUNCIONES INTERNAS
// ════════════════════════════════════════════════════════════

/// @desc true si el debug de BattleRoom está activo (local o global).
battleroom_is_debug = function() {
    return debug_enabled || (variable_global_exists("debug_battleroom") && global.debug_battleroom);
};

/// @desc Nombre legible de arena_bounds_mode, para debug.
battleroom_get_arena_bounds_mode_name = function() {
    switch (arena_bounds_mode) {
        case BattleRoomArenaBoundsMode.MANUAL: return "MANUAL";
        default:                                return "RELATIVE_TO_OBJECT";
    }
};

/// @desc Recalcula arena_left/right/top/bottom. En RELATIVE_TO_OBJECT
/// (default) usa (x,y) de esta instancia + arena_width/height/offset — el
/// objeto BattleRoom ES el centro de la arena. En MANUAL no toca esos 4
/// valores (compatibilidad total con la forma anterior de configurar la
/// arena a mano); solo recalcula arena_center_x/y como el punto medio,
/// para que el debug visual siga siendo coherente en los dos modos.
///
/// Se llama: al final del Create, al entrar a ENTERING (antes de cámara/
/// push/walls), y en cada debug draw (silencioso, _log=false, solo para
/// que el panel/rectángulo de debug se vea siempre actualizado).
battleroom_update_arena_bounds = function(_log = true) {
    if (arena_bounds_mode == BattleRoomArenaBoundsMode.MANUAL) {
        arena_center_x = (arena_left + arena_right) * 0.5;
        arena_center_y = (arena_top + arena_bottom) * 0.5;
        return;
    }

    arena_center_x = x + arena_offset_x;
    arena_center_y = y + arena_offset_y;

    arena_left   = arena_center_x - arena_width  * 0.5;
    arena_right  = arena_center_x + arena_width  * 0.5;
    arena_top    = arena_center_y - arena_height * 0.5;
    arena_bottom = arena_center_y + arena_height * 0.5;

    if (_log && battleroom_is_debug()) {
        show_debug_message("[BATTLEROOM ARENA] bounds updated from object center");
        show_debug_message("[BATTLEROOM ARENA] left/top/right/bottom: "
            + string(arena_left) + "/" + string(arena_top) + "/" + string(arena_right) + "/" + string(arena_bottom));
    }
};

/// @desc Calcula camera_target_left/top/right/bottom: los bordes de la
/// vista de cámara OBJETIVO (target_camera_width/height del camera
/// controller — no la vista actual, que puede estar en medio de un lerp)
/// centrada en (x,y) de ESTA instancia de BattleRoom. No depende de que la
/// cámara ya se haya movido — es un cálculo puro a partir de constantes
/// conocidas de inmediato, por eso las walls no necesitan esperar a que la
/// cámara termine su transición visual (que sigue siendo suave, en
/// Step_2 del camera controller). Devuelve true si el resultado es válido.
battleroom_get_target_camera_bounds = function() {
    var _cw = CAM_VIEW_DEFAULT_W;
    var _ch = CAM_VIEW_DEFAULT_H;

    if (instance_exists(obj_camera_controller)) {
        with (obj_camera_controller) {
            _cw = target_camera_width;
            _ch = target_camera_height;
        }
    }

    camera_target_left   = x - _cw * 0.5;
    camera_target_right  = x + _cw * 0.5;
    camera_target_top    = y - _ch * 0.5;
    camera_target_bottom = y + _ch * 0.5;

    if (battleroom_is_debug()) {
        show_debug_message("[BATTLEROOM CAMERA] target center = BattleRoom ("
            + string(round(x)) + "," + string(round(y)) + ")");
        show_debug_message("[BATTLEROOM CAMERA] target bounds from view size: "
            + string(round(camera_target_left)) + "/" + string(round(camera_target_top)) + "/"
            + string(round(camera_target_right)) + "/" + string(round(camera_target_bottom))
            + "  (view " + string(_cw) + "x" + string(_ch) + ")");
    }

    return camera_target_right > camera_target_left && camera_target_bottom > camera_target_top;
};

/// @desc Fuente única de bounds para walls / placement / cámara —
/// battleroom_place_player_inside(), battleroom_lock_player_progress() y
/// battleroom_apply_camera() SIEMPRE leen active_left/right/top/bottom,
/// nunca arena_*/camera_target_* directamente. En CENTER_ON_ARENA usa la
/// vista de cámara (battleroom_get_target_camera_bounds); en cualquier
/// otro modo usa arena_left/right/top/bottom tal cual (comportamiento
/// previo, sin cambios). Devuelve true si el resultado es válido.
battleroom_get_active_bounds = function() {
    if (camera_bounds_mode == BattleRoomCameraBoundsMode.CENTER_ON_ARENA) {
        var _ok = battleroom_get_target_camera_bounds();
        active_left   = camera_target_left;
        active_right  = camera_target_right;
        active_top    = camera_target_top;
        active_bottom = camera_target_bottom;
        return _ok;
    }

    active_left   = arena_left;
    active_right  = arena_right;
    active_top    = arena_top;
    active_bottom = arena_bottom;
    return active_right > active_left && active_bottom > active_top;
};

/// @desc Nombre legible de un estado (para debug/HUD). Sin argumento, usa el estado actual.
battleroom_get_state_name = function(_state = battleroom_state) {
    var _names = ["WAITING", "ENTERING", "SPAWNING", "ACTIVE", "CLEARING", "REWARD", "FINISHED"];
    if (_state < 0 || _state >= array_length(_names)) return "UNKNOWN";
    return _names[_state];
};

// ── Mapa de transiciones válidas ──────────────────────────────
// Documentación EJECUTABLE del flujo (no bloquea — solo avisa por debug si
// algo se salta el grafo esperado, para no romper por error algún caso que
// esta lista no haya previsto):
//   WAITING  -> ENTERING
//   ENTERING -> SPAWNING
//   SPAWNING -> ACTIVE | CLEARING          (CLEARING directo si no hay enemigos)
//   ACTIVE   -> CLEARING
//   CLEARING -> REWARD | FINISHED          (REWARD solo si reward_enabled)
//   REWARD   -> FINISHED
//   FINISHED -> (terminal, sin salidas)
battleroom_valid_next_states = [
    [BattleRoomState.ENTERING],
    [BattleRoomState.SPAWNING],
    [BattleRoomState.ACTIVE, BattleRoomState.CLEARING],
    [BattleRoomState.CLEARING],
    [BattleRoomState.REWARD, BattleRoomState.FINISHED],
    [BattleRoomState.FINISHED],
    [],
];

/// @desc Único punto por el que cambia battleroom_state. Guarda previous_state,
/// resetea state_timer, avisa (sin bloquear) si la transición no está en
/// battleroom_valid_next_states, y loguea el cambio si el debug está activo.
battleroom_set_state = function(_new_state) {
    if (_new_state == battleroom_state) return;

    if (battleroom_is_debug()) {
        var _valid = battleroom_valid_next_states[battleroom_state];
        var _ok    = false;
        for (var i = 0; i < array_length(_valid); i++) {
            if (_valid[i] == _new_state) { _ok = true; break; }
        }
        if (!_ok) {
            show_debug_message("[BATTLEROOM WARNING] " + battleroom_id + ": unusual transition "
                + battleroom_get_state_name(battleroom_state) + " -> " + battleroom_get_state_name(_new_state));
        }
    }

    previous_state    = battleroom_state;
    battleroom_state  = _new_state;
    state_timer       = 0;

    if (battleroom_is_debug()) {
        show_debug_message("[BATTLEROOM] " + battleroom_id + ": "
            + battleroom_get_state_name(previous_state) + " -> " + battleroom_get_state_name(battleroom_state));
    }
};

/// @desc Punto de entrada público. Llamar desde un trigger para iniciar la sala.
battleroom_start = function() {
    if (battleroom_state != BattleRoomState.WAITING) return;
    if (completed && trigger_once && !can_retrigger) return;
    if (started) return;

    started   = true;
    completed = false;

    battleroom_set_state(BattleRoomState.ENTERING);
};

/// @desc Receptor de señal genérica de obj_trigger_on_collision. No duplica
/// lógica de activación — solo canaliza hacia battleroom_start().
on_trigger_activated = function(_trigger, _activator) {
    if (battleroom_is_debug()) {
        show_debug_message("[BATTLEROOM] " + battleroom_id + ": signal received");
    }
    battleroom_start();
};

// ── Funciones por estado ─────────────────────────────────────
// Cada una tiene una responsabilidad clara y es la única dueña de
// decidir cuándo avanzar al siguiente estado (siempre vía
// battleroom_set_state()). Las acciones de "entrada única" de cada
// estado están protegidas con state_timer == 1 para que no se
// repitan cada frame (p.ej. no crear paredes infinitas).

/// @desc WAITING — sala inactiva. Solo espera a battleroom_start().
battleroom_state_waiting = function() {
    // No hacer nada: ni spawn, ni cámara, ni paredes, ni música.
};

/// @desc ENTERING — marca la sala como en curso, deja los contadores de
/// enemigos en un estado limpio, activa los gates manuales y bloquea SOLO
/// el input del player mientras la cámara viaja hacia el objeto
/// BattleRoom. A diferencia de la versión anterior (todo instantáneo en
/// state_timer==1), ahora ENTERING puede durar varios frames si
/// camera_center_on_start está activo — dura hasta que la cámara llega
/// (battle_camera_intro_arrive_distance) o se cumple el techo
/// battle_camera_intro_duration, lo que pase primero. Con
/// camera_center_on_start == false, vuelve a ser instantáneo (1 frame),
/// igual que antes.
///
/// ORDEN:
///   1. (state_timer==1) update_arena_bounds — solo relevante en LOCK_TO_ARENA
///   2. (state_timer==1) activate_manual_gates — SIEMPRE, no espera a la cámara
///   3. (state_timer==1) lock_player_input_for_camera — SOLO input, física intacta
///   4. (state_timer==1) apply_camera — cambia target de cámara a esta instancia
///   5. (cada frame) esperar a que la cámara llegue o expire el timer
///   6. return_camera_to_player + release_player_input_after_camera
///   7. -> SPAWNING (ahí arrancan los spawners)
///
/// NO corta velocidad, NO cancela dash/roll, NO fuerza player_state — ver
/// battleroom_lock_player_input_for_camera() en obj_player. Gates (paso 2)
/// se activan ANTES que nada más, así que el player queda contenido desde
/// el primer frame sin depender de que termine la intro de cámara.
battleroom_state_entering = function() {
    if (state_timer == 1) {
        active            = true;
        enemy_alive_count = 0;
        enemy_total_count = 0;
        active_enemies    = [];

        battleroom_update_arena_bounds();

        if (battleroom_is_debug() && instance_exists(obj_player)) {
            var _p_dbg = instance_find(obj_player, 0);
            show_debug_message("[BATTLEROOM INTRO] battleroom center x/y: " + string(round(x)) + "," + string(round(y)));
            show_debug_message("[BATTLEROOM ENTRY] player before: " + string(round(_p_dbg.x)) + "," + string(round(_p_dbg.y))
                + "  vel=" + string(variable_instance_exists(_p_dbg, "vel_x") ? round(_p_dbg.vel_x) : 0) + ","
                          + string(variable_instance_exists(_p_dbg, "vel_y") ? round(_p_dbg.vel_y) : 0)
                + "  state=" + string(variable_instance_exists(_p_dbg, "player_state") ? _p_dbg.player_state : -1));
        }

        battleroom_activate_manual_gates();
        if (battleroom_is_debug()) {
            show_debug_message("[BATTLEROOM INTRO] gates activated");
        }

        // Compat con configuraciones viejas (arena/walls manuales) — no-ops
        // seguros si no están configuradas (push_player_inside=false,
        // use_temp_walls=false en el flujo nuevo).
        battleroom_place_player_inside();
        battleroom_lock_player_progress();

        if (camera_center_on_start) {
            battleroom_lock_player_input_for_camera();
        }

        battleroom_apply_camera();
        if (camera_center_on_start && battleroom_is_debug()) {
            show_debug_message("[BATTLEROOM INTRO] camera target = BattleRoom");
        }

        battleroom_start_music();
    }

    if (camera_center_on_start) {
        if (!battleroom_camera_intro_check()) return;   // seguir esperando — NO pasar a SPAWNING todavía

        battleroom_return_camera_to_player();
        battleroom_release_player_input_after_camera();

        if (battleroom_is_debug()) {
            show_debug_message("[BATTLEROOM INTRO] spawners activated");
        }
    }

    battleroom_set_state(BattleRoomState.SPAWNING);
};

/// @desc Bloquea SOLO el input del player (obj_player.input_only_lock) —
/// NO toca velocidad, gravedad, dash/roll en curso ni player_state. Ver el
/// bloque "INPUT-ONLY LOCK" en obj_player/Step_0.gml: neutraliza global.inp
/// antes de que el player lo lea, así que si venía cayendo/dasheando/
/// rolleando, sigue exactamente igual — el state machine del player
/// resuelve esas ramas con estado ya existente, no con input nuevo.
/// input_only_lock_timer del player es solo un techo de seguridad — el
/// release real y explícito es battleroom_release_player_input_after_camera().
battleroom_lock_player_input_for_camera = function() {
    if (!lock_player_input_during_camera_intro) return;
    if (!instance_exists(obj_player)) return;

    var _player = instance_find(obj_player, 0);
    if (variable_instance_exists(_player, "input_only_lock")) {
        _player.input_only_lock       = true;
        _player.input_only_lock_timer = battle_camera_intro_duration + 30;   // techo generoso — el release explícito llega mucho antes
    }

    if (battleroom_is_debug()) {
        show_debug_message("[BATTLEROOM INTRO] player input locked only");
    }
};

/// @desc Libera el input-only lock del player. Se llama SIEMPRE que
/// termina el intro de cámara (por distancia o por timeout) — nunca deja
/// al player sin control indefinidamente.
battleroom_release_player_input_after_camera = function() {
    if (!instance_exists(obj_player)) return;

    var _player = instance_find(obj_player, 0);
    if (variable_instance_exists(_player, "input_only_lock")) {
        _player.input_only_lock       = false;
        _player.input_only_lock_timer = 0;
    }

    if (battleroom_is_debug()) {
        show_debug_message("[BATTLEROOM INTRO] player input released");
    }
};

/// @desc true si el intro de cámara terminó este frame (por distancia O
/// por timeout — lo que pase primero, así nunca se queda esperando una
/// llegada exacta que puede no pasar por redondeo/clamp). Usa la vista
/// REAL de la cámara (camera_get_view_x/y/width/height, ya interpolada por
/// obj_camera_controller/Step_2.gml), no un valor objetivo — confirma que
/// la cámara realmente llegó, visualmente, no solo que se lo pedimos.
battleroom_camera_intro_check = function() {
    var _done_by_timer = (state_timer >= battle_camera_intro_duration);
    var _dist           = -1;

    if (instance_exists(obj_camera_controller)) {
        with (obj_camera_controller) {
            var _cx = camera_get_view_x(cam) + camera_get_view_width(cam) * 0.5;
            var _cy = camera_get_view_y(cam) + camera_get_view_height(cam) * 0.5;
            // _dist fue declarada con var afuera — accesible por nombre acá
            // adentro aunque self haya cambiado (with no crea scope nuevo).
            // other.x/other.y sí necesitan "other." — son instance vars de
            // la BattleRoom (el caller), no locals.
            _dist = point_distance(_cx, _cy, other.x, other.y);
        }
    }

    intro_last_distance = _dist;   // informativo/debug (panel + este log)

    var _done_by_distance = (_dist >= 0) && (_dist <= battle_camera_intro_arrive_distance);

    if (_done_by_timer || _done_by_distance) {
        if (battleroom_is_debug()) {
            show_debug_message("[BATTLEROOM INTRO] intro finished by " + (_done_by_distance ? "distance" : "timer")
                + "  distance=" + string(round(_dist)) + "  state_timer=" + string(state_timer));
        }
        return true;
    }

    return false;
};

/// @desc Devuelve el target de seguimiento de la cámara al player — SOLO
/// el target, no toca zoom ni bounds override (eso es responsabilidad de
/// battleroom_restore_camera(), que corre recién al TERMINAR la
/// BattleRoom, no acá). No-op si camera_return_to_player_after_intro ==
/// false (uso avanzado: dejar la cámara mirando al BattleRoom a propósito).
battleroom_return_camera_to_player = function() {
    if (!camera_return_to_player_after_intro) return;
    if (!instance_exists(obj_camera_controller)) return;

    with (obj_camera_controller) {
        camera_restore_player_target();
    }

    if (battleroom_is_debug()) {
        show_debug_message("[BATTLEROOM INTRO] camera returned to player");
    }
};

/// @desc [LEGACY] Congela el input del player al INICIO de la BattleRoom
/// (evitar escape antes de que los gates queden activos). Reusa damage_
/// recovery_lock/damage_recovery_lock_timer — mismo mecanismo que el daño,
/// no un lock paralelo. YA NO se llama desde battleroom_state_entering()
/// — ver battleroom_lock_player_input_for_camera() más arriba, que
/// reemplaza esto sin tocar velocidad/física. Queda definida por si algo
/// la usa manualmente.
battleroom_freeze_player_for_start = function() {
    if (!freeze_player_on_start) return;
    if (!instance_exists(obj_player)) return;

    var _player = instance_find(obj_player, 0);

    if (freeze_player_duration <= 0) {
        show_debug_message("[BATTLEROOM WARNING] freeze_player_duration <= 0 — using 1.");
        freeze_player_duration = 1;
    }

    if (variable_instance_exists(_player, "damage_recovery_lock")) {
        _player.damage_recovery_lock       = true;
        _player.damage_recovery_lock_timer = freeze_player_duration;
    }

    player_freeze_debug_timer = freeze_player_duration;

    if (battleroom_is_debug()) {
        show_debug_message("[BATTLEROOM START] freeze player");
    }
};

/// @desc [LEGACY] Corta toda la velocidad del player al inicio de la
/// BattleRoom — vel_x/vel_y, move_x/move_y y knockback_x. YA NO se llama
/// desde battleroom_state_entering() — la estrategia actual (input-only
/// lock) NO corta velocidad a propósito. Queda definida por si algo la usa
/// manualmente.
battleroom_clear_player_velocity_for_start = function() {
    if (!clear_player_velocity_on_start) return;
    if (!instance_exists(obj_player)) return;

    var _player = instance_find(obj_player, 0);

    if (variable_instance_exists(_player, "vel_x"))       _player.vel_x = 0;
    if (variable_instance_exists(_player, "vel_y"))       _player.vel_y = 0;
    if (variable_instance_exists(_player, "move_x"))      _player.move_x = 0;
    if (variable_instance_exists(_player, "move_y"))      _player.move_y = 0;
    if (variable_instance_exists(_player, "knockback_x")) _player.knockback_x = 0;

    if (battleroom_is_debug()) {
        show_debug_message("[BATTLEROOM START] clear player velocity");
    }
};

/// @desc [LEGACY] Cancela roll_active/dash_jump_active/hitstun_timer y
/// fuerza salida de PSTATE.DASH. YA NO se llama desde battleroom_state_
/// entering() — la estrategia actual NO cancela dash/roll a propósito
/// (deben continuar con su inercia normal). Queda definida por si algo la
/// usa manualmente.
battleroom_cancel_player_movement_states_for_start = function() {
    if (!cancel_player_movement_states_on_start) return;
    if (!instance_exists(obj_player)) return;

    var _player = instance_find(obj_player, 0);

    var _has_state   = variable_instance_exists(_player, "player_state");
    var _state_before = _has_state ? _player.player_state : -1;
    var _dash_before   = _has_state && (_player.player_state == PSTATE.DASH);
    var _roll_before   = variable_instance_exists(_player, "roll_active") ? _player.roll_active : false;
    var _vx_before      = variable_instance_exists(_player, "vel_x") ? _player.vel_x : 0;
    var _vy_before      = variable_instance_exists(_player, "vel_y") ? _player.vel_y : 0;
    var _grounded       = variable_instance_exists(_player, "isGrounded") ? _player.isGrounded : false;

    if (battleroom_is_debug()) {
        show_debug_message("[BATTLEROOM START] cancel player movement states");
        show_debug_message("[BATTLEROOM START] player state before = " + (_has_state ? string(_state_before) : "n/a"));
        show_debug_message("[BATTLEROOM START] grounded var = " + string(_grounded));
        show_debug_message("[BATTLEROOM START] dash before = " + string(_dash_before));
        show_debug_message("[BATTLEROOM START] roll before = " + string(_roll_before));
        show_debug_message("[BATTLEROOM START] velocity before = " + string(round(_vx_before)) + "," + string(round(_vy_before)));
    }

    if (variable_instance_exists(_player, "roll_active"))      _player.roll_active = false;
    if (variable_instance_exists(_player, "dash_jump_active")) _player.dash_jump_active = false;
    if (variable_instance_exists(_player, "hitstun_timer"))    _player.hitstun_timer = 0;

    // player_set_state() (scr_player_fsm.gml) es una función GLOBAL, no un
    // método de instancia — llamarla como _player.player_set_state(...)
    // hace que GML busque una VARIABLE de instancia con ese nombre en
    // _player (no existe, la función vive en el namespace global) y
    // revienta con "Variable not set before reading it". Para que corra
    // con el player como self hay que envolver la llamada en with(),
    // mismo patrón que ya usa el proyecto para funciones ajenas al self
    // actual (p.ej. with (obj_camera_controller) { camera_set_view_mode(...); }).
    if (_dash_before) {
        with (_player) {
            player_set_state(_grounded ? PSTATE.IDLE : PSTATE.FALL);
        }
    }

    if (battleroom_is_debug()) {
        var _state_after = _has_state ? _player.player_state : -1;
        var _dash_after    = _has_state && (_player.player_state == PSTATE.DASH);
        var _roll_after     = variable_instance_exists(_player, "roll_active") ? _player.roll_active : false;
        var _vx_after        = variable_instance_exists(_player, "vel_x") ? _player.vel_x : 0;
        var _vy_after        = variable_instance_exists(_player, "vel_y") ? _player.vel_y : 0;

        show_debug_message("[BATTLEROOM START] dash after = " + string(_dash_after));
        show_debug_message("[BATTLEROOM START] roll after = " + string(_roll_after));
        show_debug_message("[BATTLEROOM START] velocity after = " + string(round(_vx_after)) + "," + string(round(_vy_after)));
        show_debug_message("[BATTLEROOM START] player state after = " + (_has_state ? string(_state_after) : "n/a"));
    }
};

/// @desc Congela brevemente el input del player mientras dura la secuencia
/// de entrada (reubicación + cámara + walls), reusando damage_recovery_
/// lock/damage_recovery_lock_timer — el mismo mecanismo que ya usaba el
/// player cuando recibe daño (no es un lock paralelo). También limpia
/// move_x/move_y para no arrastrar velocidad hacia la nueva posición. No
/// hace nada si push_lock_input == false o no hay player.
/// YA NO se llama desde battleroom_state_entering() por defecto (ver
/// battleroom_freeze_player_for_start más arriba) — queda definida por si
/// algo la usa manualmente.
battleroom_freeze_player_for_entry = function() {
    if (!push_lock_input) return;
    if (!instance_exists(obj_player)) return;

    var _player = instance_find(obj_player, 0);

    if (push_duration <= 0) {
        show_debug_message("[BATTLEROOM PUSH WARNING] push_duration <= 0 — using 1.");
        push_duration = 1;
    }

    if (variable_instance_exists(_player, "damage_recovery_lock")) {
        _player.damage_recovery_lock       = true;
        _player.damage_recovery_lock_timer = push_duration;
    }
    if (variable_instance_exists(_player, "move_x")) _player.move_x = 0;
    if (variable_instance_exists(_player, "move_y")) _player.move_y = 0;

    if (battleroom_is_debug()) {
        show_debug_message("[BATTLEROOM ENTRY] player frozen");
    }
};

/// @desc Reubica al player INSTANTÁNEAMENTE a una posición segura dentro
/// de la arena. Reemplaza al push animado (lerp multi-frame) de antes:
/// con las walls naciendo inmediatamente después (mismo frame), animar el
/// movimiento no tenía sentido — el player terminaba empujando contra una
/// pared sólida en vez de deslizarse. No hace nada si push_player_inside
/// == false, si no hay player, o si los arena bounds son inválidos.
battleroom_place_player_inside = function() {
    if (!push_player_inside) {
        if (battleroom_is_debug()) {
            show_debug_message("[BATTLEROOM ENTRY] skipped: push_player_inside disabled");
        }
        return;
    }

    if (!instance_exists(obj_player)) return;   // sin player, nada que reubicar

    if (!battleroom_get_active_bounds()) {
        show_debug_message("[BATTLEROOM PUSH WARNING] Invalid bounds. Push skipped.");
        return;
    }

    var _player = instance_find(obj_player, 0);

    var _safe_left  = active_left  + push_safe_margin;
    var _safe_right = active_right - push_safe_margin;

    var _already_inside = (_player.x >= _safe_left)  && (_player.x <= _safe_right)
                        && (_player.y >= active_top)  && (_player.y <= active_bottom);

    if (_already_inside && !force_entry_push && entry_target_x == 0 && entry_target_y == 0) {
        if (battleroom_is_debug()) {
            show_debug_message("[BATTLEROOM ENTRY] skipped: player already inside");
        }
        return;
    }

    // ── Target X: entry_target_x manual, o borde seguro más cercano ──
    var _target_x;
    if (entry_target_x != 0) {
        _target_x = entry_target_x;
    } else if (_player.x < active_left) {
        _target_x = _safe_left;    // entrando desde la izquierda
    } else if (_player.x > active_right) {
        _target_x = _safe_right;   // entrando desde la derecha
    } else {
        _target_x = clamp(_player.x, _safe_left, _safe_right);   // ya estaba adentro, solo clampear al margen
    }
    _target_x = clamp(_target_x, _safe_left, _safe_right);

    // ── Target Y: por defecto NO se toca (active_top/bottom no siempre es
    // "piso" en un platformer) — solo si se configuró entry_target_y, o si
    // la Y actual quedó fuera de los bounds activos. Si el player quedó
    // fuera en ambos ejes y no hay borde claro, cae al centro (clamp ya
    // resuelve eso: clampea a active_top/active_bottom, que es el centro
    // vertical si estaba muy lejos de ambos bordes).
    var _target_y = _player.y;
    if (entry_target_y != 0) {
        _target_y = clamp(entry_target_y, active_top, active_bottom);
    } else if (_player.y < active_top || _player.y > active_bottom) {
        _target_y = clamp(_player.y, active_top, active_bottom);
    }

    var _from_x = _player.x;
    var _from_y = _player.y;

    if (battleroom_is_debug()) {
        show_debug_message("[BATTLEROOM ENTRY] placing player inside arena");
    }

    _player.x = _target_x;
    _player.y = _target_y;
    if (variable_instance_exists(_player, "move_x")) _player.move_x = 0;
    if (variable_instance_exists(_player, "move_y")) _player.move_y = 0;

    push_start_x  = _from_x;
    push_start_y  = _from_y;
    push_target_x = _target_x;
    push_target_y = _target_y;

    if (battleroom_is_debug()) {
        show_debug_message("[BATTLEROOM ENTRY] player moved from " + string(round(_from_x)) + "," + string(round(_from_y))
            + " to " + string(round(_target_x)) + "," + string(round(_target_y)));
    }
};

/// @desc Libera el control del player al final de la secuencia de entrada.
/// Limpia damage_recovery_lock explícitamente (no depende de que su timer
/// llegue a 0 solo) y resetea velocidad residual una vez más.
/// YA NO se llama desde battleroom_state_entering() por defecto — era la
/// causa de que el freeze durara ~0 frames (se llamaba en el mismo frame
/// que battleroom_freeze_player_for_entry). Queda definida por si algo la
/// usa manualmente.
battleroom_release_player_after_entry = function() {
    if (!push_lock_input) return;
    if (!instance_exists(obj_player)) return;

    var _player = instance_find(obj_player, 0);

    if (variable_instance_exists(_player, "damage_recovery_lock")) {
        _player.damage_recovery_lock       = false;
        _player.damage_recovery_lock_timer = 0;
    }
    if (variable_instance_exists(_player, "move_x")) _player.move_x = 0;
    if (variable_instance_exists(_player, "move_y")) _player.move_y = 0;

    if (battleroom_is_debug()) {
        show_debug_message("[BATTLEROOM ENTRY] player released");
    }
};

/// @desc SPAWNING — busca los obj_enemy_spawner de esta sala (mismo
/// encounter_id), les asigna owner_controller = id y los ACTIVA
/// directamente (spawner_activate()) en el mismo paso — así la BattleRoom
/// es la que dispara sus spawners, no el trigger en paralelo. Esto evita
/// una condición de carrera: si el spawner creara su enemigo por su cuenta
/// (señal del trigger) antes de que la BattleRoom lo hubiera registrado,
/// owner_controller todavía sería noone y el enemigo nunca quedaría
/// vinculado a la sala. Reemplaza a la vieja battleroom_spawn_enemies()
/// (que buscaba obj_battleroom_spawn_marker).
///
/// NOTA: un spawner que pertenece a una BattleRoom NO debería tener su
/// propio listen_signal_id configurado igual al del trigger — si lo
/// tuviera, el trigger lo activaría también por su cuenta (en paralelo,
/// vía on_trigger_activated) y con spawn_once=false podría spawnear dos
/// veces. Dejar listen_signal_id vacío en spawners de BattleRoom; usarlo
/// solo en spawners standalone, sin BattleRoom.
battleroom_register_spawners = function() {
    active_spawners         = [];
    spawner_total_count     = 0;
    spawner_completed_count = 0;

    if (encounter_id == "") {
        if (battleroom_is_debug()) {
            show_debug_message("[BATTLEROOM] " + battleroom_id + ": encounter_id is empty — no spawners registered.");
        }
        return;
    }

    var _spawner_obj = asset_get_index("obj_enemy_spawner");
    if (_spawner_obj == -1 || !object_exists(_spawner_obj)) {
        if (battleroom_is_debug()) {
            show_debug_message("[BATTLEROOM] " + battleroom_id + ": obj_enemy_spawner no existe todavía — sin spawners.");
        }
        return;
    }

    with (_spawner_obj) {
        if (encounter_id != other.encounter_id) continue;   // no es de esta sala

        owner_controller = other.id;   // asignar owner ANTES de activar
        array_push(other.active_spawners, id);
        other.spawner_total_count++;

        if (other.battleroom_is_debug()) {
            show_debug_message("[BATTLEROOM] " + other.battleroom_id + ": registered spawner " + spawner_id);
        }

        // spawn_on_battle_start permite registrar un spawner sin activarlo
        // todavía (p.ej. reservado para una wave futura) — no lo tocamos acá.
        if (spawn_on_battle_start) {
            spawner_activate(other.id);   // la BattleRoom activa a su spawner, ya con owner_controller listo
        }
    }

    if (spawner_total_count == 0) {
        if (battleroom_is_debug()) {
            show_debug_message("[BATTLEROOM WARNING] No spawners found for encounter_id " + encounter_id);
        }
    } else if (battleroom_is_debug()) {
        show_debug_message("[BATTLEROOM] " + battleroom_id + ": " + string(spawner_total_count) + " spawner(s) registered for encounter " + encounter_id);
    }
};

/// @desc true si ningún spawner registrado sigue en medio de su secuencia
/// de spawn (active && !finished). Un spawner que nunca se activó
/// (spawn_on_battle_start = false) NO bloquea — solo bloquean los que
/// están efectivamente spawneando. Sin spawners registrados, es true de
/// entrada (nada que esperar).
battleroom_all_spawners_finished = function() {
    for (var i = 0; i < array_length(active_spawners); i++) {
        var _s = active_spawners[i];
        if (!instance_exists(_s)) continue;
        if (_s.active && !_s.finished) return false;
    }
    return true;
};

/// @desc SPAWNING — registra y activa spawners una sola vez (state_timer ==
/// 1), pero AHORA puede durar más de un frame: el spawn real ocurre en el
/// Step de cada obj_enemy_spawner (respeta spawn_delay/spawn_interval), así
/// que hay que esperar a que todos terminen antes de decidir. Usar
/// enemy_alive_count (no spawner_total_count) para la decisión final evita
/// quedarse esperando para siempre si un spawner terminó pero no logró
/// crear ningún enemigo válido (enemy_object mal configurado, etc). Nunca
/// queda atrapado: sin spawners (o con todos terminados y 0 enemigos),
/// pasa directo a CLEARING.
battleroom_state_spawning = function() {
    if (state_timer == 1) {
        battleroom_register_spawners();

        if (!battleroom_all_spawners_finished() && battleroom_is_debug()) {
            show_debug_message("[BATTLEROOM] " + battleroom_id + ": waiting for spawners");
        }
    }

    if (!battleroom_all_spawners_finished()) return;   // esperar spawn_delay/spawn_interval en curso

    if (battleroom_is_debug()) {
        show_debug_message("[BATTLEROOM] " + battleroom_id + ": all spawners finished");
    }

    if (enemy_alive_count > 0) {
        battleroom_set_state(BattleRoomState.ACTIVE);
    } else {
        battleroom_set_state(BattleRoomState.CLEARING);
    }
};

/// @desc Llamar desde un obj_enemy_spawner de esta sala cuando terminó
/// (todos sus enemigos murieron). Es bookkeeping informativo del lado de
/// los spawners — NO decide la transición de estado (eso lo hace
/// battleroom_on_enemy_died() con enemy_alive_count, más abajo).
battleroom_on_spawner_completed = function(_spawner) {
    spawner_completed_count++;

    if (battleroom_is_debug()) {
        show_debug_message("[BATTLEROOM] " + battleroom_id + ": spawner completed ("
            + string(spawner_completed_count) + "/" + string(spawner_total_count) + ")");
    }
};

/// @desc Registra un enemigo creado por un spawner de esta sala. Idempotente
/// (no registra dos veces el mismo enemigo) y no asume ningún enemy_object
/// específico — funciona con cualquier hijo de obj_enemy_parent.
battleroom_register_enemy = function(_enemy) {
    if (!instance_exists(_enemy)) return;
    if (variable_instance_exists(_enemy, "battleroom_enemy_registered") && _enemy.battleroom_enemy_registered) return;

    _enemy.battleroom_owner            = id;
    _enemy.battleroom_id               = battleroom_id;
    _enemy.battleroom_enemy_registered = true;

    array_push(active_enemies, _enemy);

    enemy_alive_count++;
    enemy_total_count++;

    if (battleroom_is_debug()) {
        show_debug_message("[BATTLEROOM] REGISTER ENEMY — BattleRoom: " + battleroom_id
            + "  Enemy: " + object_get_name(_enemy.object_index)
            + "  Alive: " + string(enemy_alive_count)
            + "  Total: " + string(enemy_total_count));
    }
};

/// @desc Llamar desde un enemigo registrado en esta sala cuando muere (ver
/// obj_enemy_parent/Create_0.gml → die() / Destroy). enemy_alive_count
/// nunca baja de 0, y no descuenta dos veces: si el enemigo no está en
/// active_enemies (ya se descontó, o nunca se registró), se ignora. Solo
/// transiciona a CLEARING si la sala está ACTIVE — no si está
/// WAITING/ENTERING/FINISHED/etc.
battleroom_on_enemy_died = function(_enemy) {
    var _idx = -1;
    for (var i = 0; i < array_length(active_enemies); i++) {
        if (active_enemies[i] == _enemy) { _idx = i; break; }
    }
    if (_idx == -1) return;   // no registrado o ya descontado — ignorar, no crashea

    array_delete(active_enemies, _idx, 1);
    enemy_alive_count = max(0, enemy_alive_count - 1);

    if (battleroom_is_debug()) {
        show_debug_message("[BATTLEROOM] ENEMY DIED — BattleRoom: " + battleroom_id
            + "  Remaining: " + string(enemy_alive_count));
    }

    if (battleroom_state == BattleRoomState.ACTIVE && enemy_alive_count <= 0) {
        if (battleroom_is_debug()) {
            show_debug_message("[BATTLEROOM] enemies cleared");
            show_debug_message("[BATTLEROOM] CLEARING — BattleRoom: " + battleroom_id);
        }
        battleroom_set_state(BattleRoomState.CLEARING);
    }
};

/// @desc ACTIVE — combate en curso. Cámara y paredes se mantienen
/// bloqueadas. Chequeo de respaldo (battleroom_on_enemy_died ya transiciona
/// de inmediato al morir el último enemigo); esto solo cubre el caso raro
/// de entrar a ACTIVE con enemy_alive_count ya en 0.
///
/// NOTA — por qué esto NO puede cerrar la sala antes de que terminen los
/// spawners: la BattleRoom solo llega a ACTIVE desde battleroom_state_
/// spawning(), y esa función NO deja pasar a ACTIVE hasta que
/// battleroom_all_spawners_finished() da true (ver esa función). O sea,
/// todo el spawneo (incluidos spawn_delay/spawn_interval de cada spawner)
/// ya terminó ANTES de que este código pueda ejecutarse — no hace falta
/// re-chequear spawners acá, estructuralmente no pueden quedar pendientes.
battleroom_state_active = function() {
    if (enemy_alive_count <= 0) {
        if (battleroom_is_debug()) {
            show_debug_message("[BATTLEROOM] enemies cleared");
        }
        battleroom_set_state(BattleRoomState.CLEARING);
    }
};

/// @desc Acción de limpieza: libera bloqueos (walls + gates), cámara y
/// música. Idempotente — segura de llamar aunque no haya nada que
/// deshacer (walls/gates vacíos, cámara sin lock, música sin cambiar).
battleroom_clear = function() {
    cleared = true;
    active  = false;
    battleroom_unlock_player_progress();
    battleroom_deactivate_manual_gates();
    battleroom_restore_camera();
    battleroom_restore_music();
    // Fallback: si la BattleRoom termina/se resetea mientras el intro de
    // cámara todavía tenía el input lockeado (caso raro — normalmente ya
    // se liberó en ENTERING antes de llegar acá), liberar sí o sí. No-op
    // seguro si ya estaba liberado.
    battleroom_release_player_input_after_camera();

    if (battleroom_is_debug()) {
        show_debug_message("[BATTLEROOM] " + battleroom_id + " → CLEARED");
    }
};

/// @desc CLEARING — limpia la sala una sola vez y decide si hay recompensa.
battleroom_state_clearing = function() {
    if (state_timer == 1) {
        battleroom_clear();
    }

    battleroom_set_state(reward_enabled ? BattleRoomState.REWARD : BattleRoomState.FINISHED);
};

/// @desc Acción de recompensa. No crea nada si reward_enabled/reward_object
/// no están configurados, ni si ya se entregó (reward_given).
battleroom_give_reward = function() {
    if (!reward_enabled) return;
    if (reward_object == noone || !object_exists(reward_object)) return;
    if (reward_given) return;

    var _rx = (reward_x != 0) ? reward_x : x;
    var _ry = (reward_y != 0) ? reward_y : y;

    instance_create_layer(_rx, _ry, layer, reward_object);
    reward_given = true;

    if (battleroom_is_debug()) {
        show_debug_message("[BATTLEROOM] " + battleroom_id + " → REWARD given");
    }
};

/// @desc REWARD — entrega la recompensa una sola vez y pasa a FINISHED.
battleroom_state_reward = function() {
    if (state_timer == 1) {
        battleroom_give_reward();
    }

    battleroom_set_state(BattleRoomState.FINISHED);
};

/// @desc Acción de cierre: marca la sala como completada. enemy_alive_count
/// ya está en 0 a esta altura (es requisito para haber llegado hasta acá
/// vía CLEARING); enemy_total_count se deja intacto a propósito, como
/// registro histórico para debug.
battleroom_finish = function() {
    completed = true;
    active    = false;   // ya lo dejó en false battleroom_clear(), esto es redundante a propósito

    if (battleroom_is_debug()) {
        show_debug_message("[BATTLEROOM] " + battleroom_id + " → FINISHED");
    }
};

/// @desc FINISHED — estado terminal. No spawnea, no crea paredes, no repite
/// recompensa. battleroom_start() ya bloquea reactivación (state != WAITING).
battleroom_state_finished = function() {
    if (state_timer == 1) {
        battleroom_finish();
    }
};

/// @desc Bloquea el avance del jugador creando obj_battleroom_wall en los
/// bordes de active_left/right/top/bottom (battleroom_get_active_bounds()
/// — arena_* en LOCK_TO_ARENA, vista de cámara centrada en esta instancia
/// en CENTER_ON_ARENA). Valida los bounds antes de crear nada — inválidos
/// (0/0/0/0 o similar), NO crea paredes (evita atrapar al player en x=0 de
/// cualquier room). El grosor de pared es TILE_SIZE (scr_config.gml) —
/// misma unidad que usa obj_battleroom_wall como su propio default, así
/// que la pared izquierda queda pegada por fuera de active_left (no invade
/// el área) y la derecha arranca justo en active_right.
battleroom_lock_player_progress = function() {
    if (!use_temp_walls) return;

    // No duplicar: si ya hay walls vivas de una llamada anterior (p.ej.
    // lock llamado dos veces por error), no crear otras — preferimos
    // saltear antes que huerfanar las viejas o duplicar la colisión.
    for (var i = 0; i < array_length(wall_instances); i++) {
        if (instance_exists(wall_instances[i])) {
            if (battleroom_is_debug()) {
                show_debug_message("[BATTLEROOM WALL] skipped: walls already active");
            }
            return;
        }
    }

    if (!battleroom_get_active_bounds()) {
        show_debug_message("[BATTLEROOM WARNING] Invalid bounds. Configure arena_left/right/top/bottom (LOCK_TO_ARENA) o revisar camera view (CENTER_ON_ARENA) antes de habilitar temp walls.");
        return;
    }

    var _wall_obj = asset_get_index("obj_battleroom_wall");
    if (_wall_obj == -1 || !object_exists(_wall_obj)) {
        show_debug_message("[BATTLEROOM WARNING] obj_battleroom_wall not found — sin bloqueo de avance.");
        return;
    }

    // Preferir la layer "Instances" (convención del proyecto para
    // instancias de gameplay); si esta room no la tiene, usar la layer
    // propia de la BattleRoom como fallback seguro (siempre válida).
    var _has_instances_layer = (layer_get_id("Instances") != -1);
    var _use_layer = _has_instances_layer ? "Instances" : layer;

    if (battleroom_is_debug()) {
        show_debug_message(_has_instances_layer
            ? "[BATTLEROOM WALL] using layer: Instances"
            : "[BATTLEROOM WALL] using fallback layer");
        show_debug_message("[BATTLEROOM WALL] bounds source: "
            + (camera_bounds_mode == BattleRoomCameraBoundsMode.CENTER_ON_ARENA ? "camera view" : "arena_*"));
    }

    var _height = active_bottom - active_top;
    var _width  = active_right - active_left;

    wall_instances = [];

    if (wall_left_enabled) {
        battleroom_create_wall("left", active_left - TILE_SIZE, active_top, TILE_SIZE, _height, _wall_obj, _use_layer);
    }
    if (wall_right_enabled) {
        battleroom_create_wall("right", active_right, active_top, TILE_SIZE, _height, _wall_obj, _use_layer);
    }
    if (wall_top_enabled) {
        battleroom_create_wall("top", active_left, active_top - TILE_SIZE, _width, TILE_SIZE, _wall_obj, _use_layer);
    }
    if (wall_bottom_enabled) {
        battleroom_create_wall("bottom", active_left, active_bottom, _width, TILE_SIZE, _wall_obj, _use_layer);
    }
};

/// @desc Crea UNA pared temporal, la registra en wall_instances, y corre
/// un self-test contra level_solid_at() en el centro de la pared para
/// confirmar en consola que la colisión real coincide con lo que se acaba
/// de crear (detecta de inmediato si algo no está bien wireado, en vez de
/// descubrirlo recién cuando el player la atraviesa).
battleroom_create_wall = function(_label, _wx, _wy, _ww, _wh, _wall_obj, _use_layer) {
    var _w = instance_create_layer(_wx, _wy, _use_layer, _wall_obj);
    _w.wall_configure(_ww, _wh);
    _w.owner_battleroom = id;
    _w.wall_id = battleroom_id + "_wall_" + _label;
    array_push(wall_instances, _w);

    if (battleroom_is_debug()) {
        show_debug_message("[BATTLEROOM WALL] created " + string_upper(_label) + " at "
            + string(_wx) + "," + string(_wy) + " " + string(_ww) + "x" + string(_wh));

        var _map    = layer_tilemap_get_id(layer_get_id(COLLISION_LAYER));
        var _test_x = _wx + _ww * 0.5;
        var _test_y = _wy + _wh * 0.5;
        var _ok     = level_solid_at(_map, _test_x, _test_y);
        show_debug_message("[BATTLEROOM WALL] level_solid_at test " + string_upper(_label) + ": "
            + (_ok ? "passed" : "FAILED"));
    }

    return _w;
};

/// @desc Destruye las paredes temporales creadas por battleroom_lock_player_progress().
/// Solo destruye instancias que todavía existen (nunca crashea si alguna ya
/// fue destruida por otro motivo) y siempre limpia el array después, para
/// no dejar referencias huérfanas.
battleroom_unlock_player_progress = function() {
    var _n = 0;
    for (var i = 0; i < array_length(wall_instances); i++) {
        var _w = wall_instances[i];
        if (instance_exists(_w)) {
            instance_destroy(_w);
            _n++;
        }
    }
    wall_instances = [];

    if (_n > 0 && battleroom_is_debug()) {
        show_debug_message("[BATTLEROOM WALL] destroyed (" + string(_n) + ")");
        show_debug_message("[BATTLEROOM WALL] all walls cleared");
    }
};

/// @desc Busca todas las instancias de obj_battleroom_gate cuyo
/// encounter_id coincida con el de esta BattleRoom y las guarda en
/// manual_gate_instances. No las activa — solo las encuentra (llamado por
/// battleroom_activate_manual_gates() antes de activarlas, así siempre
/// están frescas por si se creó/destruyó algún gate entre medio). No
/// depende de arena_*/active_*/cámara — son instancias colocadas a mano en
/// el Room Editor.
battleroom_find_manual_gates = function() {
    manual_gate_instances = [];

    if (encounter_id == "") return;

    var _gate_obj = asset_get_index("obj_battleroom_gate");
    if (_gate_obj == -1 || !object_exists(_gate_obj)) {
        if (battleroom_is_debug()) {
            show_debug_message("[BATTLEROOM GATES] obj_battleroom_gate no existe todavía — sin gates.");
        }
        return;
    }

    if (battleroom_is_debug()) {
        show_debug_message("[BATTLEROOM GATES] searching gates for encounter_id=" + encounter_id);
    }

    with (_gate_obj) {
        if (encounter_id != other.encounter_id) continue;   // no es de esta sala

        array_push(other.manual_gate_instances, id);
        owner_battleroom = other.id;

        if (other.battleroom_is_debug()) {
            show_debug_message("[BATTLEROOM GATES] found gate " + gate_id);
        }
    }
};

/// @desc Activa (vuelve sólidos) todos los gates de esta BattleRoom.
/// Llamado desde battleroom_state_entering(). No hace nada si
/// use_manual_gates == false.
battleroom_activate_manual_gates = function() {
    if (!use_manual_gates) return;

    battleroom_find_manual_gates();

    for (var i = 0; i < array_length(manual_gate_instances); i++) {
        var _g = manual_gate_instances[i];
        if (instance_exists(_g)) _g.gate_activate();
    }

    if (battleroom_is_debug()) {
        show_debug_message("[BATTLEROOM GATES] activated (" + string(array_length(manual_gate_instances)) + ")");
    }
};

/// @desc Desactiva (quita la colisión de) todos los gates registrados y
/// limpia manual_gate_instances. Llamado desde battleroom_clear() — mismo
/// punto donde ya se llama battleroom_unlock_player_progress() para las
/// walls, así que corre exactamente cuando enemy_alive_count <= 0 y todos
/// los spawners terminaron (condición que ya decide la transición a
/// CLEARING). Seguro llamar aunque use_manual_gates sea false o el array
/// esté vacío (no hace nada).
battleroom_deactivate_manual_gates = function() {
    for (var i = 0; i < array_length(manual_gate_instances); i++) {
        var _g = manual_gate_instances[i];
        if (instance_exists(_g)) _g.gate_deactivate();
    }
    manual_gate_instances = [];
};

/// @desc Nombre legible de camera_mode (CameraViewMode), en la nomenclatura
/// que pide BattleRoom (CLOSE/NORMAL/FAR — NORMAL == CameraViewMode.DEFAULT).
/// No es un enum nuevo — camera_mode sigue siendo CameraViewMode tal cual
/// ya existía; esto es solo texto de debug.
battleroom_get_camera_size_name = function() {
    switch (camera_mode) {
        case CameraViewMode.CLOSE: return "CLOSE";
        case CameraViewMode.FAR:   return "FAR";
        default:                    return "NORMAL";   // CameraViewMode.DEFAULT
    }
};

/// @desc Aplica camera_mode (zoom, reusa CameraViewMode — CLOSE/DEFAULT=
/// NORMAL/FAR, ningún enum nuevo) y, según camera_bounds_mode, cambia el
/// TARGET de seguimiento de la cámara y/o bloquea su área visible. La
/// BattleRoom NO mueve la cámara cuadro a cuadro — solo le pasa
/// configuración al controller real, que sigue siendo el único que la
/// mueve (su propio Step_2).
///
/// CENTER_ON_BATTLEROOM: el modo más simple — SOLO cambia el target de la
/// cámara a esta instancia (camera_set_target). No toca bounds override,
/// no depende de arena_*/active_*, no crea nada. La cámara deja de seguir
/// al player y se centra (con el smoothing normal de Step_2: lerp_x/
/// lerp_y) en (x,y) de esta BattleRoom. Es la única lógica de este modo.
///
/// CENTER_ON_ARENA: además del target, aplica bounds override calculado
/// desde la vista de cámara (battleroom_get_active_bounds) — pensado para
/// cuando además se usan walls. No tocado en este paso.
///
/// LOCK_TO_ARENA: sin cambios — bounds = arena_*, target de cámara sin
/// tocar (sigue siendo el player).
battleroom_apply_camera = function() {
    if (!lock_camera) return;
    if (!instance_exists(obj_camera_controller)) return;

    with (obj_camera_controller) {
        camera_set_view_mode(other.camera_mode, true);
    }

    if (camera_bounds_mode == BattleRoomCameraBoundsMode.DEFAULT) return;

    // ── CENTER_ON_BATTLEROOM: solo target, nada de bounds/arena/walls ──
    if (camera_bounds_mode == BattleRoomCameraBoundsMode.CENTER_ON_BATTLEROOM) {
        with (obj_camera_controller) {
            camera_set_target(other.id);
        }
        if (battleroom_is_debug()) {
            show_debug_message("[BATTLEROOM CAMERA] mode = CENTER_ON_BATTLEROOM");
            show_debug_message("[BATTLEROOM CAMERA] target = BattleRoom " + string(round(x)) + "/" + string(round(y)));
            show_debug_message("[BATTLEROOM CAMERA] size = " + battleroom_get_camera_size_name());
        }
        return;
    }

    if (!battleroom_get_active_bounds()) {
        show_debug_message("[BATTLEROOM CAMERA WARNING] Invalid bounds. Camera lock skipped.");
        return;
    }

    if (camera_bounds_mode == BattleRoomCameraBoundsMode.CENTER_ON_ARENA) {
        with (obj_camera_controller) {
            camera_set_target(other.id);
        }
        if (battleroom_is_debug()) {
            show_debug_message("[BATTLEROOM CAMERA] camera target = BattleRoom instance (was player)");
        }
    }

    if (battleroom_is_debug()) {
        show_debug_message("[BATTLEROOM CAMERA] applying " + battleroom_get_camera_bounds_mode_name());
        show_debug_message("[BATTLEROOM CAMERA] bounds: " + string(round(active_left)) + "/" + string(round(active_top))
            + "/" + string(round(active_right)) + "/" + string(round(active_bottom)));
    }

    with (obj_camera_controller) {
        // camera_transition_duration == 0 → usar el default del controller
        // (bounds_transition_duration) sin tocarlo. Walls/player NO esperan
        // esta transición — es puramente visual, corre en paralelo en
        // Step_2 del camera controller mientras SPAWNING/ACTIVE ya siguen.
        if (other.camera_transition_duration > 0) {
            bounds_transition_duration = other.camera_transition_duration;
        }
        camera_set_bounds_override(other.active_left, other.active_top, other.active_right, other.active_bottom);
    }
};

/// @desc Restaura la cámara a su modo/bounds normales (limpia el override
/// de obj_camera_controller) y, en CENTER_ON_ARENA/CENTER_ON_BATTLEROOM,
/// devuelve el target de la cámara al player (camera_restore_player_
/// target). Solo actúa si camera_restore_on_finish == true — si es false,
/// la cámara queda con el bounds override/target puesto (uso avanzado,
/// p.ej. encadenar varias BattleRooms sin parpadeo).
battleroom_restore_camera = function() {
    if (!lock_camera) return;
    if (!camera_restore_on_finish) return;
    if (!instance_exists(obj_camera_controller)) return;

    var _used_camera_target = (camera_bounds_mode == BattleRoomCameraBoundsMode.CENTER_ON_ARENA)
        || (camera_bounds_mode == BattleRoomCameraBoundsMode.CENTER_ON_BATTLEROOM);

    with (obj_camera_controller) {
        zoom_reset();
        camera_clear_bounds_override();
        if (_used_camera_target) {
            camera_restore_player_target();
        }
    }

    if (battleroom_is_debug() && camera_bounds_mode == BattleRoomCameraBoundsMode.CENTER_ON_BATTLEROOM) {
        show_debug_message("[BATTLEROOM CAMERA] restored player follow");
    }

    if (battleroom_is_debug()) {
        show_debug_message("[BATTLEROOM CAMERA] restored default camera bounds"
            + (_used_camera_target ? " + camera target restored to player" : ""));
    }
};

/// @desc Nombre legible de camera_bounds_mode, para debug.
battleroom_get_camera_bounds_mode_name = function() {
    switch (camera_bounds_mode) {
        case BattleRoomCameraBoundsMode.LOCK_TO_ARENA:        return "LOCK_TO_ARENA";
        case BattleRoomCameraBoundsMode.CENTER_ON_ARENA:      return "CENTER_ON_ARENA";
        case BattleRoomCameraBoundsMode.CENTER_ON_BATTLEROOM: return "CENTER_ON_BATTLEROOM";
        default:                                          return "DEFAULT";
    }
};

/// @desc Inicia la música de batalla. STUB seguro — el proyecto no tiene music manager todavía.
battleroom_start_music = function() {
    if (!change_music) return;
    // STUB: cuando exista un sistema global de música (p.ej. global.music_manager
    // o un scr_music_play), conectar aquí: guardar la pista anterior si
    // restore_previous_music == true, y reproducir battle_music.
    if (battleroom_is_debug()) {
        show_debug_message("[BATTLEROOM] battleroom_start_music(): sin music manager en el proyecto — stub.");
    }
};

/// @desc Restaura la música previa. STUB seguro — ver battleroom_start_music().
battleroom_restore_music = function() {
    if (!change_music || !restore_previous_music) return;
    // STUB: ver nota en battleroom_start_music().
    if (battleroom_is_debug()) {
        show_debug_message("[BATTLEROOM] battleroom_restore_music(): sin music manager en el proyecto — stub.");
    }
};

/// @desc Saca de active_enemies cualquier referencia a una instancia ya
/// destruida. La cuenta real (enemy_alive_count) nunca depende de esto —
/// es solo higiene de la lista para que el debug no muestre basura.
battleroom_prune_dead_enemies = function() {
    for (var i = array_length(active_enemies) - 1; i >= 0; i--) {
        if (!instance_exists(active_enemies[i])) {
            array_delete(active_enemies, i, 1);
        }
    }
};

/// @desc Cuántos de los spawners registrados ya terminaron su secuencia de spawn.
battleroom_count_spawners_finished = function() {
    var _n = 0;
    for (var i = 0; i < array_length(active_spawners); i++) {
        var _s = active_spawners[i];
        if (instance_exists(_s) && _s.finished) _n++;
    }
    return _n;
};

/// @desc Dibuja info de debug. Llamar desde Draw GUI. No dibuja nada si el debug está apagado.
battleroom_debug_draw = function() {
    if (!battleroom_is_debug()) return;

    battleroom_prune_dead_enemies();
    battleroom_get_active_bounds();   // silencioso — misma fuente que walls/placement/cámara

    var _cam_line        = "Camera controller: n/a";
    var _cam_center_line = "";
    var _cam_target_line = "";
    if (instance_exists(obj_camera_controller)) {
        with (obj_camera_controller) {
            var _vx = camera_get_view_x(cam);
            var _vy = camera_get_view_y(cam);
            var _vw = camera_get_view_width(cam);
            var _vh = camera_get_view_height(cam);
            var _tname = instance_exists(target) ? object_get_name(target.object_index) : "none";
            // Las var de afuera siguen siendo accesibles por nombre acá
            // adentro aunque self haya cambiado (with no crea un scope de
            // locals nuevo).
            _cam_line = "Camera view: " + string(round(_vx)) + "," + string(round(_vy))
                + " " + string(_vw) + "x" + string(_vh);
            _cam_center_line = "Camera current center: " + string(round(_vx + _vw * 0.5)) + "," + string(round(_vy + _vh * 0.5));
            _cam_target_line = "Camera target type: " + _tname
                + (instance_exists(target) ? "  target x,y: " + string(round(target.x)) + "," + string(round(target.y)) : "");
        }
    }

    var _entry_freeze_line = "Player freeze/vel/state: n/a";
    if (instance_exists(obj_player)) {
        with (instance_find(obj_player, 0)) {
            var _lock_timer  = variable_instance_exists(id, "damage_recovery_lock_timer") ? damage_recovery_lock_timer : -1;
            var _input_lock  = variable_instance_exists(id, "input_only_lock") ? input_only_lock : false;
            var _vx          = variable_instance_exists(id, "vel_x") ? vel_x : 0;
            var _vy          = variable_instance_exists(id, "vel_y") ? vel_y : 0;
            var _roll        = variable_instance_exists(id, "roll_active") ? roll_active : false;
            var _is_dash     = variable_instance_exists(id, "player_state") && player_state == PSTATE.DASH;
            // _entry_freeze_line fue declarada con var afuera — accesible
            // por nombre acá adentro aunque self haya cambiado (with no
            // crea un scope de locals nuevo). NO usar "other." acá: eso
            // apuntaría a una instance var de la BattleRoom, no al local.
            _entry_freeze_line = "Player input_only_lock=" + string(_input_lock) + "  dmg_lock_timer=" + string(_lock_timer)
                + "  vel: " + string(round(_vx)) + "," + string(round(_vy))
                + "  roll_active=" + string(_roll) + "  dashing=" + string(_is_dash);
        }
    }

    var _lines = [
        "BattleRoom: " + battleroom_id + "  (encounter: " + encounter_id + ")  x,y: " + string(round(x)) + "," + string(round(y)),
        "Listen signal: " + listen_signal_id,
        "State: " + battleroom_get_state_name(battleroom_state) + "  (prev: " + battleroom_get_state_name(previous_state) + ")",
        "State timer: " + string(state_timer),
        "Active: " + string(active) + "  Completed: " + string(completed) + "  Cleared: " + string(cleared),
        "Spawners: " + string(battleroom_count_spawners_finished()) + " finished / " + string(spawner_total_count) + " registered",
        "Enemies: " + string(enemy_alive_count) + " alive / " + string(enemy_total_count) + " total  (active_enemies: " + string(array_length(active_enemies)) + ")",
        "Camera mode (size): " + battleroom_get_camera_size_name() + "  Bounds mode: " + battleroom_get_camera_bounds_mode_name()
            + "  Restore on finish: " + string(camera_restore_on_finish),
        _cam_line,
        _cam_center_line,
        _cam_target_line,
        "Player x,y: " + (instance_exists(obj_player) ? string(round(instance_find(obj_player, 0).x)) + "," + string(round(instance_find(obj_player, 0).y)) : "n/a"),
        "Active bounds (walls/cam): L" + string(round(active_left)) + " R" + string(round(active_right))
            + " T" + string(round(active_top)) + " B" + string(round(active_bottom)),
        "Walls: " + string(array_length(wall_instances)) + " active  use_temp_walls=" + string(use_temp_walls),
        "Gates: " + string(array_length(manual_gate_instances)) + " registered  use_manual_gates=" + string(use_manual_gates),
        "Camera intro: on=" + string(camera_center_on_start) + "  timer=" + string(state_timer) + "/" + string(battle_camera_intro_duration)
            + "  arrive_dist=" + string(battle_camera_intro_arrive_distance) + "  last_dist=" + string(round(intro_last_distance)),
        _entry_freeze_line,
        "Entry: enabled=" + string(push_player_inside) + "  freeze=" + string(push_lock_input)
            + "  freeze_frames=" + string(push_duration) + "  margin=" + string(push_safe_margin),
        "Entry target: " + string(round(push_target_x)) + "," + string(round(push_target_y))
            + "  from: " + string(round(push_start_x)) + "," + string(round(push_start_y)),
        "Camera transition: " + (camera_transition_duration > 0 ? string(camera_transition_duration) + "f" : "default"),
    ];

    var _sx = 20;
    var _sy = 20;
    var _line_h = 18;

    draw_set_alpha(0.6);
    draw_set_color(c_black);
    draw_rectangle(_sx - 6, _sy - 6, _sx + 320, _sy + _line_h * array_length(_lines), false);
    draw_set_alpha(1);
    draw_set_color(c_yellow);
    for (var i = 0; i < array_length(_lines); i++) {
        draw_text(_sx, _sy + i * _line_h, _lines[i]);
    }
    draw_set_color(c_white);
};

/// @desc Dibuja el rectángulo de bounds ACTIVOS (world space) — el mismo
/// que usan walls/placement/cámara (battleroom_get_active_bounds), no
/// arena_* directamente — más el centro del objeto BattleRoom, las walls
/// vivas (con su wall_id) y la posición del player con indicador
/// INSIDE/OUTSIDE. Llamar desde Draw (no Draw GUI). No dibuja nada si el
/// debug está apagado.
battleroom_debug_draw_arena = function() {
    if (!battleroom_is_debug()) return;

    battleroom_get_active_bounds();   // silencioso — solo para tener el rectángulo fresco

    draw_set_alpha(0.10);
    draw_set_color(c_yellow);
    draw_rectangle(active_left, active_top, active_right, active_bottom, false);
    draw_set_alpha(0.8);
    draw_rectangle(active_left, active_top, active_right, active_bottom, true);

    // Centro real del objeto BattleRoom — en CENTER_ON_ARENA, ES el centro
    // de active_left/right/top/bottom (la cámara se centra acá).
    draw_set_alpha(1);
    draw_set_color(c_red);
    draw_circle(x, y, 6, false);
    draw_set_halign(fa_center);
    draw_text(x, y - 20, "BattleRoom (x,y)");
    draw_set_halign(fa_left);

    draw_set_color(c_yellow);
    draw_text(active_left, active_top - 44,
        "mode: " + battleroom_get_camera_bounds_mode_name()
        + "  source: " + (camera_bounds_mode == BattleRoomCameraBoundsMode.CENTER_ON_ARENA ? "camera view" : "arena_*"));
    draw_text(active_left, active_top - 28,
        "bounds: " + string(round(active_left)) + "," + string(round(active_top))
        + " - " + string(round(active_right)) + "," + string(round(active_bottom)));

    // Walls vivas — rectángulo real + id, para confirmar visualmente que
    // coinciden con active_left/right/top/bottom de arriba.
    draw_set_color(c_aqua);
    for (var i = 0; i < array_length(wall_instances); i++) {
        var _w = wall_instances[i];
        if (!instance_exists(_w)) continue;
        draw_set_alpha(0.15);
        draw_rectangle(_w.x, _w.y, _w.x + _w.wall_width, _w.y + _w.wall_height, false);
        draw_set_alpha(0.9);
        draw_rectangle(_w.x, _w.y, _w.x + _w.wall_width, _w.y + _w.wall_height, true);
        draw_text(_w.x + 4, _w.y + 4, _w.wall_id);
    }

    // Posición actual del player + si está dentro o fuera de los bounds
    // activos — el chequeo más directo posible para diagnosticar "el
    // player se sale".
    if (instance_exists(obj_player)) {
        var _p = instance_find(obj_player, 0);
        var _p_inside = (_p.x >= active_left) && (_p.x <= active_right)
                      && (_p.y >= active_top)  && (_p.y <= active_bottom);

        draw_set_color(_p_inside ? c_lime : c_red);
        draw_set_alpha(1);
        draw_circle(_p.x, _p.y, 10, true);
        draw_set_halign(fa_center);
        draw_text(_p.x, _p.y - 30, _p_inside ? "player: INSIDE" : "player: OUTSIDE");
        draw_set_halign(fa_left);
    }

    draw_set_color(c_white);
};

// Calcular arena_left/right/top/bottom una vez al crear la instancia, para
// que tengan un valor válido desde el primer frame (silencioso: la
// Creation Code del Room Editor, donde normalmente se pone debug_enabled,
// corre DESPUÉS de este Create Event).
battleroom_update_arena_bounds(false);
