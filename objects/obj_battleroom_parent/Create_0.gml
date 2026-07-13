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
use_temp_walls     = true;
wall_left_enabled  = true;
wall_right_enabled = true;
wall_instances      = [];

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

arena_left   = 0;
arena_right  = 0;
arena_top    = 0;
arena_bottom = 0;

// ── Push del player hacia dentro de la arena (ENTERING) ───────
// Corre ANTES de battleroom_lock_player_progress() — si las walls ya
// existieran, podrían bloquear este mismo movimiento. Por defecto está
// apagado (push_player_inside = false), así que no cambia nada para
// BattleRooms que no lo configuren.
push_player_inside = false;

entry_target_x = 0;   // 0 = usar el centro de la arena como fallback
entry_target_y = 0;   // 0 = no tocar la Y del player (solo empuja en X por defecto)

push_duration = 20;   // frames — con <= 0 se fuerza a 1 (ver battleroom_start_push_player)
push_timer    = 0;

push_player_active = false;   // true mientras el push está en curso
push_start_x  = 0;
push_start_y  = 0;
push_target_x = 0;   // target resuelto (clamp aplicado) — distinto de entry_target_x, que es config cruda
push_target_y = 0;

push_lock_input        = true;   // bloquea input del player durante el push (reusa damage_recovery_lock)
push_arrival_threshold = 4;      // px — considerar "llegó" si está a esta distancia o menos del target
push_safe_margin       = 96;     // px — margen desde los bordes de arena para considerar "ya adentro"
force_entry_push       = false;  // true = empujar igual aunque el player ya esté dentro del margen seguro

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
/// enemigos en un estado limpio y válido antes de spawnear, y prepara
/// cámara/push/bloqueos/música.
///
/// ORDEN ACTUAL: apply_camera → push_player_inside (si aplica) →
/// lock_player_progress → start_music.
///
/// A diferencia del resto de los estados transitorios (que duran 1 frame),
/// ENTERING puede durar varios frames si push_player_active queda true —
/// el resto del estado (paredes/música/pasar a SPAWNING) espera a que el
/// push termine, para que las paredes nunca se creen mientras el player
/// todavía se está moviendo hacia dentro de la arena. Si
/// push_player_inside == false, el comportamiento es idéntico al de antes
/// (todo en el mismo frame, sin cambios).
battleroom_state_entering = function() {
    if (state_timer == 1) {
        active            = true;
        enemy_alive_count = 0;
        enemy_total_count = 0;
        active_enemies    = [];

        battleroom_apply_camera();
        battleroom_start_push_player();   // deja push_player_active en true solo si corresponde empujar
    }

    if (push_player_active) {
        battleroom_update_push_player();
    }

    if (push_player_active) return;   // seguir esperando — no crear paredes ni pasar a SPAWNING todavía

    battleroom_lock_player_progress();
    battleroom_start_music();
    battleroom_set_state(BattleRoomState.SPAWNING);
};

/// @desc Decide si corresponde empujar al player en este ENTERING. Solo
/// lee estado, no lo modifica — battleroom_start_push_player() es quien
/// actúa según lo que esta función devuelva. Loguea el motivo del skip.
battleroom_should_push_player = function() {
    if (!push_player_inside) {
        if (battleroom_is_debug()) {
            show_debug_message("[BATTLEROOM PUSH] skipped: disabled");
        }
        return false;
    }

    if (!instance_exists(obj_player)) return false;   // sin player no hay nada que empujar

    if (arena_right <= arena_left || arena_bottom <= arena_top) {
        show_debug_message("[BATTLEROOM PUSH WARNING] Invalid arena bounds. Push skipped.");
        return false;
    }

    var _player = instance_find(obj_player, 0);
    var _already_inside = (_player.x >= arena_left + push_safe_margin)
                        && (_player.x <= arena_right - push_safe_margin);

    if (_already_inside && !force_entry_push) {
        if (battleroom_is_debug()) {
            show_debug_message("[BATTLEROOM PUSH] skipped: player already inside");
        }
        return false;
    }

    return true;
};

/// @desc Arranca el push (llamar una sola vez, en state_timer == 1 de
/// ENTERING). Calcula el target real (con fallbacks y clamp a la arena),
/// guarda la posición inicial del player, y si push_lock_input, bloquea
/// su input reusando damage_recovery_lock/damage_recovery_lock_timer —
/// el mecanismo de lock que YA existe en obj_player (el mismo que usa
/// cuando el player recibe daño), en vez de crear un lock paralelo. Ese
/// mismo timer se autolimpia solo en obj_player/Step_0.gml, y además lo
/// forzamos explícito en battleroom_finish_push_player() por las dudas.
battleroom_start_push_player = function() {
    push_player_active = false;

    if (!battleroom_should_push_player()) return;

    var _player = instance_find(obj_player, 0);

    var _target_x = (entry_target_x != 0) ? entry_target_x : (arena_left + arena_right) * 0.5;
    _target_x = clamp(_target_x, arena_left + push_safe_margin, arena_right - push_safe_margin);

    // Por defecto NO se toca la Y (arena_top/arena_bottom no necesariamente
    // representan piso real en un platformer) — solo si se configuró
    // entry_target_y explícitamente.
    var _target_y = _player.y;
    if (entry_target_y != 0) {
        _target_y = clamp(entry_target_y, arena_top, arena_bottom);
    }

    if (push_duration <= 0) {
        show_debug_message("[BATTLEROOM PUSH WARNING] push_duration <= 0 — using 1.");
        push_duration = 1;
    }

    push_start_x  = _player.x;
    push_start_y  = _player.y;
    push_target_x = _target_x;
    push_target_y = _target_y;
    push_timer    = 0;
    push_player_active = true;

    if (push_lock_input && variable_instance_exists(_player, "damage_recovery_lock")) {
        _player.damage_recovery_lock       = true;
        _player.damage_recovery_lock_timer = push_duration;
    }

    if (battleroom_is_debug()) {
        show_debug_message("[BATTLEROOM PUSH] started");
        show_debug_message("[BATTLEROOM PUSH] target x/y: " + string(push_target_x) + "/" + string(push_target_y));
    }
};

/// @desc Corre cada frame mientras push_player_active. Mueve al player con
/// lerp + ease-out hacia push_target_x/y (Y solo si es distinto de
/// push_start_y, es decir, solo si entry_target_y estaba configurado).
/// Nunca teletransporta de golpe salvo el snap final al llegar.
battleroom_update_push_player = function() {
    if (!instance_exists(obj_player)) {
        battleroom_finish_push_player();
        return;
    }

    var _player = instance_find(obj_player, 0);

    push_timer++;

    var _t = clamp(push_timer / push_duration, 0, 1);
    _t = 1 - power(1 - _t, 2);   // ease-out simple

    _player.x = lerp(push_start_x, push_target_x, _t);
    if (push_target_y != push_start_y) {
        _player.y = lerp(push_start_y, push_target_y, _t);
    }

    var _arrived = (_t >= 1) || (abs(_player.x - push_target_x) <= push_arrival_threshold);
    if (_arrived) {
        _player.x = push_target_x;
        if (push_target_y != push_start_y) _player.y = push_target_y;
        battleroom_finish_push_player();
    }
};

/// @desc Termina el push: devuelve el control al player. Limpia
/// damage_recovery_lock explícitamente (no depender solo de que su timer
/// llegue a 0 por su cuenta) y resetea velocidad acumulada para que no
/// arranque con impulso residual.
battleroom_finish_push_player = function() {
    push_player_active = false;

    if (instance_exists(obj_player)) {
        var _player = instance_find(obj_player, 0);

        if (push_lock_input && variable_instance_exists(_player, "damage_recovery_lock")) {
            _player.damage_recovery_lock       = false;
            _player.damage_recovery_lock_timer = 0;
        }

        if (variable_instance_exists(_player, "move_x")) _player.move_x = 0;
        if (variable_instance_exists(_player, "move_y")) _player.move_y = 0;
    }

    if (battleroom_is_debug()) {
        show_debug_message("[BATTLEROOM PUSH] finished");
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
            show_debug_message("[BATTLEROOM] CLEARING — BattleRoom: " + battleroom_id);
        }
        battleroom_set_state(BattleRoomState.CLEARING);
    }
};

/// @desc ACTIVE — combate en curso. Cámara y paredes se mantienen
/// bloqueadas. Chequeo de respaldo (battleroom_on_enemy_died ya transiciona
/// de inmediato al morir el último enemigo); esto solo cubre el caso raro
/// de entrar a ACTIVE con enemy_alive_count ya en 0.
battleroom_state_active = function() {
    if (enemy_alive_count <= 0) {
        battleroom_set_state(BattleRoomState.CLEARING);
    }
};

/// @desc Acción de limpieza: libera bloqueos, cámara y música. Idempotente.
/// Todavía no hay paredes/cámara/reward/music reales — battleroom_unlock_
/// player_progress/restore_camera/restore_music son stubs seguros (no
/// hacen nada si no hay nada que deshacer), así que esto es seguro tal
/// cual está para este paso.
battleroom_clear = function() {
    cleared = true;
    active  = false;
    battleroom_unlock_player_progress();
    battleroom_restore_camera();
    battleroom_restore_music();

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
/// bordes de la arena. Valida los bounds antes de crear nada — con
/// arena_left/right/top/bottom en su default (0), NO crea paredes (evita
/// atrapar al player en x=0 de cualquier room). El grosor de pared es
/// TILE_SIZE (scr_config.gml) — misma unidad que usa obj_battleroom_wall
/// como su propio default, así que la pared izquierda queda pegada por
/// fuera de arena_left (no invade la arena) y la derecha arranca justo en
/// arena_right.
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

    if (arena_right <= arena_left || arena_bottom <= arena_top) {
        show_debug_message("[BATTLEROOM WARNING] Invalid arena bounds. Configure arena_left/right/top/bottom before enabling temp walls.");
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
    }

    var _height = arena_bottom - arena_top;

    wall_instances = [];

    if (wall_left_enabled) {
        var _wl = instance_create_layer(arena_left - TILE_SIZE, arena_top, _use_layer, _wall_obj);
        _wl.wall_configure(TILE_SIZE, _height);
        _wl.owner_battleroom = id;
        _wl.wall_id = battleroom_id + "_wall_left";
        array_push(wall_instances, _wl);

        if (battleroom_is_debug()) {
            show_debug_message("[BATTLEROOM WALL] created left wall");
        }
    }

    if (wall_right_enabled) {
        var _wr = instance_create_layer(arena_right, arena_top, _use_layer, _wall_obj);
        _wr.wall_configure(TILE_SIZE, _height);
        _wr.owner_battleroom = id;
        _wr.wall_id = battleroom_id + "_wall_right";
        array_push(wall_instances, _wr);

        if (battleroom_is_debug()) {
            show_debug_message("[BATTLEROOM WALL] created right wall");
        }
    }
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

/// @desc Aplica camera_mode (zoom) siempre, y si camera_bounds_mode !=
/// DEFAULT, además bloquea el ÁREA visible de la cámara a la arena vía
/// obj_camera_controller.camera_set_bounds_override(). La BattleRoom NO
/// mueve la cámara cuadro a cuadro — solo le pasa configuración al
/// controller real, que sigue siendo el único que la mueve (su propio
/// Step_2). CENTER_ON_ARENA todavía no tiene comportamiento propio — cae
/// a la misma lógica de LOCK_TO_ARENA (bounds limitados) sin romper nada
/// mientras no se implemente el centrado real.
battleroom_apply_camera = function() {
    if (!lock_camera) return;
    if (!instance_exists(obj_camera_controller)) return;

    with (obj_camera_controller) {
        camera_set_view_mode(other.camera_mode, true);
    }

    if (camera_bounds_mode == BattleRoomCameraBoundsMode.DEFAULT) return;

    if (arena_right <= arena_left || arena_bottom <= arena_top) {
        show_debug_message("[BATTLEROOM CAMERA WARNING] Invalid arena bounds. Camera lock skipped.");
        return;
    }

    if (battleroom_is_debug()) {
        show_debug_message("[BATTLEROOM CAMERA] applying " + battleroom_get_camera_bounds_mode_name());
        show_debug_message("[BATTLEROOM CAMERA] bounds: " + string(arena_left) + "/" + string(arena_top)
            + "/" + string(arena_right) + "/" + string(arena_bottom));
    }

    with (obj_camera_controller) {
        camera_set_bounds_override(other.arena_left, other.arena_top, other.arena_right, other.arena_bottom);
    }
};

/// @desc Restaura la cámara a su modo/bounds normales (limpia el override
/// de obj_camera_controller). Solo actúa si camera_restore_on_finish ==
/// true — si es false, la cámara queda con el bounds override puesto
/// (uso avanzado, p.ej. encadenar varias BattleRooms sin parpadeo).
battleroom_restore_camera = function() {
    if (!lock_camera) return;
    if (!camera_restore_on_finish) return;
    if (!instance_exists(obj_camera_controller)) return;

    with (obj_camera_controller) {
        zoom_reset();
        camera_clear_bounds_override();
    }

    if (battleroom_is_debug()) {
        show_debug_message("[BATTLEROOM CAMERA] restored default camera bounds");
    }
};

/// @desc Nombre legible de camera_bounds_mode, para debug.
battleroom_get_camera_bounds_mode_name = function() {
    switch (camera_bounds_mode) {
        case BattleRoomCameraBoundsMode.LOCK_TO_ARENA:   return "LOCK_TO_ARENA";
        case BattleRoomCameraBoundsMode.CENTER_ON_ARENA: return "CENTER_ON_ARENA";
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

    var _lines = [
        "BattleRoom: " + battleroom_id + "  (encounter: " + encounter_id + ")",
        "Listen signal: " + listen_signal_id,
        "State: " + battleroom_get_state_name(battleroom_state) + "  (prev: " + battleroom_get_state_name(previous_state) + ")",
        "State timer: " + string(state_timer),
        "Active: " + string(active) + "  Completed: " + string(completed) + "  Cleared: " + string(cleared),
        "Spawners: " + string(battleroom_count_spawners_finished()) + " finished / " + string(spawner_total_count) + " registered",
        "Enemies: " + string(enemy_alive_count) + " alive / " + string(enemy_total_count) + " total  (active_enemies: " + string(array_length(active_enemies)) + ")",
        "Camera mode: " + string(camera_mode) + "  Bounds mode: " + battleroom_get_camera_bounds_mode_name()
            + "  Restore on finish: " + string(camera_restore_on_finish),
        "Arena: L" + string(arena_left) + " R" + string(arena_right) + " T" + string(arena_top) + " B" + string(arena_bottom),
        "Push: enabled=" + string(push_player_inside) + "  active=" + string(push_player_active)
            + "  " + string(push_timer) + "/" + string(push_duration) + "f",
        "Push target: " + string(entry_target_x) + "," + string(entry_target_y)
            + "  start: " + string(round(push_start_x)) + "," + string(round(push_start_y)),
    ];

    var _sx = 20;
    var _sy = 20;
    var _line_h = 18;

    draw_set_alpha(0.6);
    draw_set_color(c_black);
    draw_rectangle(_sx - 6, _sy - 6, _sx + 280, _sy + _line_h * array_length(_lines), false);
    draw_set_alpha(1);
    draw_set_color(c_yellow);
    for (var i = 0; i < array_length(_lines); i++) {
        draw_text(_sx, _sy + i * _line_h, _lines[i]);
    }
    draw_set_color(c_white);
};
