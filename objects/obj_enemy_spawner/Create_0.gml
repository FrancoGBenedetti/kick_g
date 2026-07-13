// ══════════════════════════════════════════════════════════
// ENEMY SPAWNER — Create
//
// Crea UN enemigo cuando se activa (por señal genérica o manualmente),
// le pasa configuración personalizada (overrides de stats, path, facing),
// guarda la referencia y cuenta cuándo muere. Avisa opcionalmente a un
// owner_controller (típicamente un obj_battleroom_parent) cuando terminó.
//
// NO sabe nada de cámara, paredes, música ni recompensa — eso es de
// obj_battleroom_parent. Funciona perfectamente SIN BattleRoom: si no
// tiene owner_controller, simplemente se marca completed = true y no avisa
// a nadie. Reemplaza a obj_battleroom_spawn_marker (que era solo un marker
// visual sin responsabilidad real).
// ══════════════════════════════════════════════════════════

enabled = true;

spawner_id   = "";   // identidad propia, útil en debug/logs
encounter_id = "";   // agrupa este spawner con un obj_battleroom_parent

// signal_id que un obj_trigger_on_collision debe emitir para activarlo
// DIRECTAMENTE. Dejar VACÍO en spawners que pertenecen a una BattleRoom:
// la BattleRoom los activa ella misma (battleroom_register_spawners()),
// y si además tuvieran el mismo signal_id que el trigger de esa sala, el
// trigger los activaría UNA SEGUNDA VEZ en paralelo (doble spawn). Usar
// listen_signal_id solo en spawners standalone, sin BattleRoom.
listen_signal_id = "";

spawn_on_start        = false;   // true = se autoactiva en su propio Create, standalone (sin owner/señal)
spawn_on_battle_start  = true;   // true = la BattleRoom lo activa apenas lo registra (SPAWNING)

spawn_once = true;   // true = no puede volver a spawnear una vez finished
spawned    = false;   // true en cuanto creó al menos un enemigo
active     = false;   // true mientras está en su secuencia de spawn (delay/interval en curso)
finished   = false;   // true cuando ya creó TODOS los enemigos de spawn_count (o falló y abortó)
completed  = false;   // true cuando TODOS los enemigos que creó ya murieron (bookkeeping propio)

enemy_object = noone;
spawn_layer  = "Instances";

// ── Delay / count / interval ──────────────────────────────
// spawn_delay: frames antes del PRIMER spawn tras activarse.
// spawn_count: cuántos enemigos crea en total esta activación.
// spawn_interval: frames entre spawns sucesivos si spawn_count > 1.
// El spawn real SIEMPRE ocurre en Step (nunca dentro de spawner_activate()),
// tanto con spawn_delay == 0 como > 0 — así el comportamiento es consistente
// sin importar el valor configurado.
spawn_delay       = 0;
spawn_delay_timer = 0;

spawn_count         = 1;
spawned_enemy_count = 0;   // cuántos ya creó de spawn_count

spawn_interval       = 15;
spawn_interval_timer = 0;

face_player_on_spawn = true;
initial_facing       = 0;   // 0 = auto (según face_player_on_spawn), -1 = izquierda, 1 = derecha

created_enemy     = noone;   // referencia rápida al último enemigo creado
created_enemies   = [];      // historial completo de enemigos creados por este spawner
enemy_alive_count = 0;       // vivos, DE ESTE SPAWNER — bookkeeping propio, no el de la BattleRoom

owner_controller         = noone;   // typically un obj_battleroom_parent — lo asigna EL owner, no el spawner
notify_owner_on_complete = true;

debug_enabled = false;

// ── Overrides de stats del enemigo ────────────────────────
// Nombres reales de este proyecto (obj_actor_parent / obj_enemy_parent):
//   hp + max_hp            → vida
//   walk_speed             → velocidad base (patrulla)
//   attack_trigger_distance→ rango de ataque (solo existe en algunos enemigos, p.ej. swordsman)
//   detection_range        → rango de detección (legado circular, en obj_enemy_parent)
//   base_image_speed       → velocidad de animación base (se multiplica por get_time_scale()
//                             en el Step del enemigo para el sistema de slow motion — por
//                             eso overrideamos base_image_speed y NO image_speed directo)
// Todos se aplican con variable_instance_exists() — si el enemy_object no
// tiene esa variable, el override se ignora sin romper nada.
override_hp = false;
enemy_hp    = 1;

override_move_speed = false;
enemy_move_speed    = 1;

override_attack_range = false;
enemy_attack_range    = 64;

override_detection_range = false;
enemy_detection_range    = 240;

override_image_speed = false;
enemy_image_speed    = 0.12;

// ── Path opcional ──────────────────────────────────────────
// El proyecto no tiene sistema de path propio en los enemigos, así que se
// usa la función estándar de GameMaker (path_start) de forma segura.
use_path            = false;
path_asset          = noone;
path_speed          = 1;
path_end_action     = path_action_stop;
path_absolute       = false;
start_path_on_spawn = true;


// ════════════════════════════════════════════════════════════
// FUNCIONES INTERNAS
// ════════════════════════════════════════════════════════════

/// @desc true si el debug del spawner está activo (local o global, mismo
/// flag que el resto del sistema BattleRoom — F1 en obj_input).
spawner_is_debug = function() {
    return debug_enabled || (variable_global_exists("debug_battleroom") && global.debug_battleroom);
};

/// @desc Aplica dirección inicial al enemigo creado. Escribe en `facing`
/// (no en image_xscale directo) porque obj_actor_parent hace
/// image_xscale = facing cada Step y lo pisaría igual.
spawner_apply_facing = function(_enemy) {
    var _want_facing = 0;
    if (face_player_on_spawn && instance_exists(obj_player)) {
        _want_facing = (obj_player.x < x) ? -1 : 1;
    } else if (initial_facing != 0) {
        _want_facing = initial_facing;
    }
    if (_want_facing == 0) return;

    if (variable_instance_exists(_enemy, "facing")) {
        _enemy.facing = _want_facing;
    }
    _enemy.image_xscale = _want_facing;   // sync inmediato antes del primer Step del enemigo
};

/// @desc Aplica los overrides de stats activos al enemigo creado. Nunca
/// rompe si el enemy_object no tiene alguna de las variables.
spawner_apply_overrides = function(_enemy) {
    if (override_hp) {
        if (variable_instance_exists(_enemy, "hp"))     _enemy.hp     = enemy_hp;
        if (variable_instance_exists(_enemy, "max_hp")) _enemy.max_hp = enemy_hp;
    }

    if (override_move_speed && variable_instance_exists(_enemy, "walk_speed")) {
        _enemy.walk_speed = enemy_move_speed;
    }

    if (override_attack_range && variable_instance_exists(_enemy, "attack_trigger_distance")) {
        _enemy.attack_trigger_distance = enemy_attack_range;
    }

    if (override_detection_range && variable_instance_exists(_enemy, "detection_range")) {
        _enemy.detection_range = enemy_detection_range;
    }

    if (override_image_speed) {
        if (variable_instance_exists(_enemy, "base_image_speed")) {
            _enemy.base_image_speed = enemy_image_speed;
        } else if (variable_instance_exists(_enemy, "image_speed")) {
            _enemy.image_speed = enemy_image_speed;
        }
    }
};

/// @desc Configura (y opcionalmente arranca) el path del enemigo creado.
/// El enemigo no existía antes del spawn, así que el path SOLO puede
/// venir del spawner. No rompe nada si el enemy_object no usa path.
spawner_apply_path = function(_enemy) {
    if (!use_path || path_asset == noone) return;
    if (!path_exists(path_asset)) {
        if (spawner_is_debug()) {
            show_debug_message("[SPAWNER] " + spawner_id + ": warning: path_asset does not exist — skipped");
        }
        return;
    }

    // Variables propias en el enemigo (por si su IA quiere leerlas más
    // adelante, p.ej. para pausar el chase mientras sigue un path).
    _enemy.use_path        = true;
    _enemy.path_asset      = path_asset;
    _enemy.path_speed      = path_speed;
    _enemy.path_end_action = path_end_action;
    _enemy.path_absolute   = path_absolute;

    if (start_path_on_spawn) {
        with (_enemy) {
            path_start(other.path_asset, other.path_speed, other.path_end_action, other.path_absolute);
        }
    }
};

/// @desc Crea UN enemigo en la posición del spawner. Devuelve true si lo
/// creó, false si falló (enemy_object inválido y sin fallback disponible —
/// nunca crashea). No valida enabled/spawn_once/timers — eso lo maneja el
/// Step, que es el único lugar que llama a esta función durante una
/// secuencia de spawn activa.
spawner_spawn_enemy = function() {
    var _enemy_object = enemy_object;

    if (_enemy_object == noone || !object_exists(_enemy_object)) {
        // Fallback: obj_enemy_basic es el "enemigo genérico" del proyecto
        // por ahora (no hardcodeamos golem ni ningún enemigo específico).
        var _fallback = asset_get_index("obj_enemy_basic");
        if (_fallback != -1 && object_exists(_fallback)) {
            _enemy_object = _fallback;
            if (spawner_is_debug()) {
                show_debug_message("[SPAWNER] " + spawner_id + ": enemy_object not set — using obj_enemy_basic fallback");
            }
        } else {
            show_debug_message("[SPAWNER] " + spawner_id + ": ERROR: enemy_object not set");
            return false;
        }
    }

    var _layer = spawn_layer;
    if (_layer == "" || layer_get_id(_layer) == -1) {
        if (spawner_is_debug()) {
            show_debug_message("[SPAWNER] " + spawner_id + ": spawn_layer '" + string(spawn_layer) + "' not found — using spawner's own layer");
        }
        _layer = layer;   // layer builtin del propio spawner, siempre válida
    }

    var _enemy = instance_create_layer(x, y, _layer, _enemy_object);

    // Referencia al spawner en el enemigo — usado para notificar la muerte
    // AL SPAWNER (bookkeeping propio, ver spawner_on_enemy_died() más abajo).
    _enemy.spawner_owner          = id;
    _enemy.spawner_id             = spawner_id;
    _enemy.encounter_id           = encounter_id;
    _enemy.spawner_death_reported = false;

    // Variables de BattleRoom en el enemigo — SIEMPRE se asignan, aunque
    // este spawner no tenga owner_controller (uso standalone, sin
    // BattleRoom). En ese caso quedan en su default (noone/"") y no rompen
    // nada — ver obj_enemy_parent/Create_0.gml → die(). No asumimos que el
    // enemy_object ya trae estas variables desde su propio Create.
    _enemy.battleroom_owner            = owner_controller;   // noone si no hay BattleRoom
    _enemy.battleroom_id               = instance_exists(owner_controller) ? owner_controller.battleroom_id : "";
    _enemy.spawned_by_spawner          = id;   // referencia al spawner que lo creó
    _enemy.battleroom_enemy_registered = false;
    _enemy.battleroom_death_notified   = false;

    // Registrar en la BattleRoom — ÚNICO lugar que incrementa el
    // enemy_alive_count DE LA BATTLEROOM. El spawner nunca lo toca directo.
    if (instance_exists(owner_controller)) {
        owner_controller.battleroom_register_enemy(_enemy);
    }

    spawner_apply_facing(_enemy);
    spawner_apply_overrides(_enemy);
    spawner_apply_path(_enemy);

    created_enemy = _enemy;
    array_push(created_enemies, _enemy);

    enemy_alive_count++;      // conteo propio del spawner (no el de la BattleRoom)
    spawned_enemy_count++;
    spawned = true;

    if (spawner_is_debug()) {
        show_debug_message("[SPAWNER] " + spawner_id + ": spawned " + object_get_name(_enemy_object) + " at " + string(x) + "," + string(y));
    }

    return true;
};

/// @desc Marca el fin de la secuencia de spawn (ya sea porque completó
/// spawn_count o porque un intento falló y no tiene sentido seguir
/// reintentando). No dispara notificación de completed — eso es sobre
/// muertes de enemigos, no sobre haber terminado de crearlos.
spawner_finish = function() {
    finished = true;
    active   = false;

    if (spawner_is_debug()) {
        show_debug_message("[SPAWNER] " + spawner_id + ": finished ("
            + string(spawned_enemy_count) + "/" + string(spawn_count) + " spawned)");
    }
};

/// @desc Punto de entrada público. _owner_controller es opcional — pasarlo
/// cuando activa una BattleRoom (spawner_activate(id)); dejarlo default
/// para activaciones standalone (señal propia o spawn_on_start), que no
/// tocan owner_controller. No crea ningún enemigo de forma síncrona: solo
/// prepara los timers. El spawn real ocurre en Step (ver más abajo),
/// consistente sin importar si spawn_delay es 0 o mayor.
spawner_activate = function(_owner_controller = noone) {
    // Advertencia de configuración peligrosa. Se chequea acá (no en Create)
    // porque en Create la Creation Code del Room Editor todavía no corrió
    // — debug_enabled recién tiene su valor real para cuando se llama a
    // spawner_activate() (desde la BattleRoom o desde el trigger).
    spawner_warn_if_misconfigured();

    if (!enabled) return;

    if (spawn_once && finished) {
        if (spawner_is_debug()) {
            show_debug_message("[SPAWNER] " + spawner_id + ": skipped: already finished");
        }
        return;
    }

    if (active) {
        if (spawner_is_debug()) {
            show_debug_message("[SPAWNER] " + spawner_id + ": skipped: already active");
        }
        return;
    }

    if (_owner_controller != noone) {
        owner_controller = _owner_controller;
        if (spawner_is_debug()) {
            show_debug_message("[SPAWNER] " + spawner_id + ": owner_controller assigned");
        }
    }

    if (spawn_count <= 0) {
        if (spawner_is_debug()) {
            show_debug_message("[SPAWNER] " + spawner_id + ": spawn_count <= 0 — nothing to spawn");
        }
        finished = true;
        return;
    }

    active                = true;
    finished              = false;
    spawned_enemy_count   = 0;
    spawn_delay_timer     = max(0, spawn_delay);
    spawn_interval_timer  = 0;

    if (spawner_is_debug()) {
        show_debug_message("[SPAWNER] " + spawner_id + ": activated"
            + (_owner_controller != noone ? " by BattleRoom" : ""));
    }
};

/// @desc Advertencia (no bloqueante) para el caso de configuración más
/// peligroso: un spawner con encounter_id Y listen_signal_id a la vez.
/// Eso normalmente significa que el trigger de la BattleRoom (por
/// signal_id) Y la BattleRoom misma (por encounter_id, vía
/// battleroom_register_spawners()) lo van a activar por separado — doble
/// spawn. No lo bloqueamos porque en teoría podría haber un caso
/// standalone legítimo con encounter_id seteado sin usarlo, pero se avisa
/// siempre que haya debug activo.
spawner_warn_if_misconfigured = function() {
    if (!spawner_is_debug()) return;
    if (encounter_id == "" || listen_signal_id == "") return;

    show_debug_message("[SPAWNER WARNING] Spawner has both encounter_id and listen_signal_id.");
    show_debug_message("If this spawner belongs to a BattleRoom, leave listen_signal_id empty to avoid double activation.");
};

/// @desc Receptor de señal genérica de obj_trigger_on_collision. Uso
/// standalone únicamente — un spawner de BattleRoom debe tener
/// listen_signal_id vacío para que esto nunca dispare en paralelo con la
/// activación que hace battleroom_register_spawners().
on_trigger_activated = function(_trigger, _activator) {
    spawner_activate();
};

/// @desc Avisa a owner_controller que este spawner terminó, si corresponde.
/// No asume que el owner es una BattleRoom — solo llama a la función si
/// existe.
spawner_notify_complete = function() {
    if (!notify_owner_on_complete) return;
    if (!instance_exists(owner_controller)) return;

    if (variable_instance_exists(owner_controller, "battleroom_on_spawner_completed")) {
        owner_controller.battleroom_on_spawner_completed(id);
    }
};

/// @desc Llamar desde un enemigo creado por este spawner cuando muere
/// (ver obj_enemy_parent/Create_0.gml → die()). Nunca baja de 0, nunca
/// notifica dos veces. Exige `finished` además de enemy_alive_count <= 0:
/// con spawn_count > 1 y spawn_interval, el primer enemigo puede morir
/// mientras el spawner todavía espera para crear el siguiente — sin este
/// chequeo, se marcaría completed de forma prematura, a mitad de secuencia.
spawner_on_enemy_died = function(_enemy) {
    enemy_alive_count = max(0, enemy_alive_count - 1);

    if (finished && enemy_alive_count <= 0 && !completed) {
        completed = true;

        if (spawner_is_debug()) {
            show_debug_message("[SPAWNER] " + spawner_id + ": completed");
        }

        spawner_notify_complete();
    }
};

/// @desc Dibuja info de debug. Llamar desde Draw (world space). Color:
/// gris = inactivo/deshabilitado, naranja = activo (spawneando), verde =
/// finished (ya creó todo lo que tenía que crear).
spawner_debug_draw = function() {
    if (!spawner_is_debug()) return;

    var _col = c_gray;
    if (enabled) {
        _col = finished ? c_lime : (active ? c_orange : c_gray);
    }

    draw_set_alpha(0.85);
    draw_set_color(_col);
    draw_circle(x, y, 14, true);
    draw_line(x - 14, y, x + 14, y);
    draw_line(x, y - 14, x, y + 14);
    draw_set_alpha(1);

    var _enemy_name    = (enemy_object == noone) ? "none" : object_get_name(enemy_object);
    var _path_name     = (path_asset == noone) ? "none" : path_get_name(path_asset);
    var _owner_name    = instance_exists(owner_controller) ? object_get_name(owner_controller.object_index) : "none";

    draw_set_color(c_white);
    draw_text(x + 18, y - 76, "[Spawner] " + spawner_id);
    draw_text(x + 18, y - 62, "encounter: " + encounter_id + "  signal: " + listen_signal_id);
    draw_text(x + 18, y - 48, "enemy: " + _enemy_name + "  owner: " + _owner_name);
    draw_text(x + 18, y - 34, "active: " + string(active) + "  finished: " + string(finished) + "  spawn_once: " + string(spawn_once));
    draw_text(x + 18, y - 20, "spawned: " + string(spawned) + "  count: " + string(spawned_enemy_count) + "/" + string(spawn_count));
    draw_text(x + 18, y - 6,  "delay: " + string(spawn_delay) + "  interval: " + string(spawn_interval));
    draw_text(x + 18, y + 8,  "alive: " + string(enemy_alive_count) + "  completed: " + string(completed));
    draw_text(x + 18, y + 22, "path: " + _path_name);

    // Advertencia visual persistente (además del log de consola en
    // spawner_activate) — así se ve aunque el debug se haya activado
    // DESPUÉS de que el spawner ya se activó una vez.
    if (encounter_id != "" && listen_signal_id != "") {
        draw_set_color(c_red);
        draw_text(x + 18, y + 36, "⚠ encounter_id + listen_signal_id both set — possible double activation");
    }
};

if (spawn_on_start) {
    spawner_activate();
}
