// ══════════════════════════════════════════════════════════
// OBJ_ENEMY_SWORDSMAN — Step
// FSM de cinco estados: PATROL → CHASE → ATTACK_WINDUP →
//                       ATTACK_ACTIVE → COOLDOWN → CHASE/PATROL
//
// Flujo por frame:
//   1. Gate global.do_step
//   2. Hitstun gate → física pura, sin IA
//   3. Detección del jugador (una sola vez)
//   4. Timers de ataque
//   5. Transiciones de estado
//   6. IA por estado → decide move_x
//   7. event_inherited() → física (enemy_parent → actor_parent)
//   8. Post-física → flip de patrulla por pared
// ══════════════════════════════════════════════════════════
if (!global.do_step) exit;

// ── HITSTUN: bypass de IA ─────────────────────────────────
if (hitstun_timer > 0) {
    event_inherited();   // enemy_parent → actor_parent: knockback + física
    exit;
}

// ══════════════════════════════════════════════════════════
// DETECCIÓN DEL JUGADOR
// ══════════════════════════════════════════════════════════
var _player_exists = instance_exists(obj_player);
var _dist          = 0;
var _dx            = 0;
var _dy            = 0;   // Y positivo = jugador más abajo
var _chase_dir     = 0;

// Detección 2D separada: abs(_dx) y abs(_dy) para rangos rectangulares.
// _dist conservado por si se necesita comparación circular futura.
if (_player_exists) {
    _dx        = obj_player.x - x;
    _dy        = obj_player.y - y;
    _dist      = point_distance(x, y, obj_player.x, obj_player.y);
    _chase_dir = sign(_dx);
    if (_chase_dir == 0) _chase_dir = patrol_dir;
}

// Helpers de rango (usados en transiciones)
var _in_aggro_range  = _player_exists
                       && abs(_dx) < aggro_range_x
                       && abs(_dy) < aggro_range_y;

var _lost_aggro      = !_player_exists
                       || abs(_dx) >= lose_aggro_range_x
                       || abs(_dy) >= lose_aggro_range_y;

// Jugador está debajo y es candidato para drop-down
var _player_is_below = (can_drop_down && _dy > player_below_threshold
                        && abs(_dx) < drop_down_x_tolerance);

// ── TIMERS ────────────────────────────────────────────────
if (attack_cooldown_timer > 0) attack_cooldown_timer--;
if (reacquire_timer       > 0) reacquire_timer--;

// ══════════════════════════════════════════════════════════
// TRANSICIONES DE ESTADO
// ══════════════════════════════════════════════════════════
switch (estate) {

    case ESTATE_PATROL:
        // Activar CHASE cuando el jugador entra en rango 2D
        if (_in_aggro_range) {
            estate = ESTATE_CHASE;
        }
    break;

    case ESTATE_CHASE:
        // Perder al jugador → volver a patrulla (rango de pérdida de aggro)
        if (_lost_aggro) {
            estate     = ESTATE_PATROL;
            patrol_dir = facing;
            break;
        }
        // Transición a WINDUP solo cuando:
        //   • el jugador está dentro del alcance real de la hitbox en X
        //   • el jugador no está demasiado arriba/abajo (vertical tolerance)
        //   • el cooldown está disponible
        // Usando abs(_dx) en lugar de _dist circular evita ataques fallidos
        // causados por diferencia de altura (el jugador a 80px diagonal puede
        // estar fuera del alcance horizontal aunque _dist < melee_range antiguo).
        if (abs(_dx) <= attack_stop_distance
        &&  abs(_dy) <= attack_vertical_tolerance
        &&  attack_cooldown_timer <= 0) {
            estate              = ESTATE_ATTACK_WINDUP;
            attack_windup_timer = attack_windup;
        }
    break;

    case ESTATE_ATTACK_WINDUP:
        // Cancelar si el jugador sale completamente del aggro range
        if (_lost_aggro) {
            estate              = ESTATE_PATROL;
            attack_windup_timer = 0;
            patrol_dir          = facing;
            break;
        }
        // Cancelar si el jugador se alejó demasiado durante la carga
        // (p.ej. dash hacia atrás). Vuelve a CHASE para perseguirlo.
        if (abs(_dx) > attack_cancel_dist) {
            estate              = ESTATE_CHASE;
            attack_windup_timer = 0;
        }
    break;

    case ESTATE_ATTACK_ACTIVE:
        // El timer se consume en la sección IA (abajo).
    break;

    case ESTATE_COOLDOWN:
        if (attack_cooldown_timer <= 0) {
            estate = _in_aggro_range ? ESTATE_CHASE : ESTATE_PATROL;
            if (estate == ESTATE_PATROL) patrol_dir = facing;
        }
    break;
}

// ══════════════════════════════════════════════════════════
// IA POR ESTADO — decide move_x (pre-física)
// ══════════════════════════════════════════════════════════
switch (estate) {

    case ESTATE_PATROL:
        // Detectar borde de plataforma (solo en suelo)
        if (isGrounded) {
            var _probe_x = x + patrol_dir * (abs(col_right) + 1);
            var _probe_y = y + col_bottom + 1;
            if (!tile_solid_at(collision_map, _probe_x, _probe_y)) {
                patrol_dir = -patrol_dir;
            }
        }
        move_x = patrol_dir * walk_speed;
    break;

    case ESTATE_CHASE:
        if (reacquire_timer > 0) {
            // Post-daño: pausar antes de reanudar
            move_x = 0;

        } else if (!can_drop_down && isGrounded) {
            // ── Borde de plataforma (solo si NO puede caer) ──────
            // Verifica si hay suelo adelante. Si no hay, frenar.
            var _probe_x = x + _chase_dir * (abs(col_right) + 1);
            var _probe_y = y + col_bottom + 1;
            if (!tile_solid_at(collision_map, _probe_x, _probe_y)) {
                // Borde detectado y no puede caer: parar
                move_x = 0;
            } else {
                // Suelo adelante: perseguir
                move_x     = _chase_dir * chase_speed;
                patrol_dir = _chase_dir;
            }

        } else if (!_player_is_below && _player_exists && abs(_dx) < stop_distance) {
            // ── Stop distance (solo si el jugador NO está debajo) ─
            // Si el jugador está debajo y el enemigo puede caer,
            // ignorar stop_distance para que avance hasta el borde.
            move_x = 0;
            if (_chase_dir != 0) patrol_dir = _chase_dir;

        } else {
            // ── Persecución directa ───────────────────────────────
            // Incluye el caso de drop-down: el enemigo avanza hacia
            // el borde y la física del actor lo hace caer.
            move_x     = _chase_dir * chase_speed;
            patrol_dir = _chase_dir;
        }
    break;

    case ESTATE_ATTACK_WINDUP:
        // Parado, mirando al jugador durante la anticipación
        move_x = 0;
        // Forzar facing hacia el jugador (el parent solo lo cambia si move_x != 0)
        if (_chase_dir != 0) facing = _chase_dir;

        attack_windup_timer--;
        if (attack_windup_timer <= 0) {
            // ── Transición a ataque activo: spawnar hitbox ────
            estate              = ESTATE_ATTACK_ACTIVE;
            attack_active_timer = attack_active_time;

            var _enemy_id = id;
            sword_hitbox_id = instance_create_layer(
                x + facing * esword_hitbox_offset_x,
                y + esword_hitbox_offset_y,
                "Instances_2",
                obj_enemy_sword_hitbox
            );
            with (sword_hitbox_id) {
                owner           = _enemy_id;
                hit_source      = _enemy_id;   // knockback desde el enemigo (no desde la hitbox)
                damage          = _enemy_id.enemy_damage;
                lifetime        = _enemy_id.attack_active_time;
                hitbox_offset_x = _enemy_id.esword_hitbox_offset_x;
                hitbox_offset_y = _enemy_id.esword_hitbox_offset_y;
                hitbox_w        = _enemy_id.esword_hitbox_w;
                hitbox_h        = _enemy_id.esword_hitbox_h;
            }
        }
    break;

    case ESTATE_ATTACK_ACTIVE:
        move_x = 0;
        attack_active_timer--;
        if (attack_active_timer <= 0) {
            // Destruir hitbox si aún existe
            if (instance_exists(sword_hitbox_id)) {
                with (sword_hitbox_id) instance_destroy();
                sword_hitbox_id = noone;
            }
            attack_cooldown_timer = attack_cooldown_max;
            estate = ESTATE_COOLDOWN;
        }
    break;

    case ESTATE_COOLDOWN:
        move_x = 0;
    break;
}

// ── FÍSICA ────────────────────────────────────────────────
// Gravedad, colisiones de tile, hitstun/knockback, facing, i-frames.
// Cadena: obj_enemy_parent.Step (vacío) → obj_actor_parent.Step.
event_inherited();

// ══════════════════════════════════════════════════════════
// POST-FÍSICA
// ══════════════════════════════════════════════════════════
// Cambio de dir al chocar con pared (solo en PATROL).
// En CHASE el enemigo presiona contra la pared — comportamiento agresivo.
if (estate == ESTATE_PATROL && wallContact && wallSide == patrol_dir) {
    patrol_dir = -patrol_dir;
}
