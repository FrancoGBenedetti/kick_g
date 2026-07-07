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

// ── Detección del rectángulo de ataque ────────────────────
// Calcula si el player toca parcialmente el hitbox de ataque.
// Esto reemplaza la verificación de distancia lineal.
var _attack_rect = scr_enemy_get_attack_rect(id);
var _player_in_attack_rect = (_player_exists
                              && collision_rectangle(_attack_rect.left, _attack_rect.top,
                                                     _attack_rect.right, _attack_rect.bottom,
                                                     obj_player, false, true) != noone);

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
        // Transición a WINDUP cuando:
        //   • el jugador toca el hitbox de ataque (cualquier parte)
        //   • tolerancia vertical OK — el jugador no está demasiado arriba/abajo
        //   • cooldown disponible
        if (_player_in_attack_rect
        &&  abs(_dy) <= attack_vertical_tolerance
        &&  attack_cooldown_timer <= 0) {
            estate              = ESTATE_ATTACK_WINDUP;
            attack_windup_timer = attack_windup;
            show_debug_message("[SWORDSMAN] CHASE → WINDUP: player en hitbox");
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
        // Forzar facing hacia el jugador SOLO si no hay lock de ataque previo
        // Una vez que decide atacar, mantiene esa dirección todo el ataque
        if (!attack_facing_locked && _chase_dir != 0) {
            facing = _chase_dir;
        }

        // Fase de avance: si el jugador aún está fuera del hitbox,
        // seguir caminando para cerrar la distancia.
        // El timer BAJA SIEMPRE cada frame (no depende de distancia).
        if (!_player_in_attack_rect) {
            move_x = _chase_dir * chase_speed;
        } else {
            move_x = 0;
        }

        // ── Timer de windup: baja siempre ─────────────────
        attack_windup_timer--;

        // ── Transición a ACTIVE: solo si timer llega a 0 y player está en rango ──
        if (attack_windup_timer <= 0 && _player_in_attack_rect) {
            // ── Transición a ataque activo: guardar facing y bloquear giros ────
            attack_facing_locked = true;  // El enemigo NO puede girarse más
            attack_facing        = facing; // Guardar dirección de ataque

            // ── Spawnar hitbox ────
            estate              = ESTATE_ATTACK_ACTIVE;
            attack_active_timer = attack_active_time;
            show_debug_message("[SWORDSMAN] WINDUP → ACTIVE: spawning hitbox, facing locked at " + string(attack_facing));

            var _enemy_id = id;
            // Usar attack_facing en lugar de facing para que el hitbox salga
            // en la dirección decidida al iniciar el ataque, no la actual
            sword_hitbox_id = instance_create_layer(
                x + attack_facing * esword_hitbox_offset_x,
                y + esword_hitbox_offset_y,
                (layer_get_id("Instances_2") != -1 ? "Instances_2" : layer_get_name(layer)),
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
                attack_facing   = _enemy_id.attack_facing;  // dirección del ataque (bloqueada)
            }
        } else if (attack_windup_timer <= 0) {
            // ── Timer llegó a 0 pero player se alejó demasiado ────
            // Volver a CHASE para perseguir
            show_debug_message("[SWORDSMAN] WINDUP timeout: player se alejó, volviendo a CHASE");
            estate              = ESTATE_CHASE;
            attack_windup_timer = 0;
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

        // ── Timer de cooldown, luego volver a CHASE ───────────────
        attack_cooldown_timer--;
        if (attack_cooldown_timer <= 0) {
            // ── Liberar bloqueo de facing al terminar cooldown ────
            attack_facing_locked = false;
            estate = ESTATE_CHASE;
            show_debug_message("[SWORDSMAN] COOLDOWN → CHASE: facing unlocked");
        }
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

// ══════════════════════════════════════════════════════════
// ANIMACIÓN VISUAL (sprites de prueba)
// ══════════════════════════════════════════════════════════
// Prioridad: Attack > Walk > Idle
// Reemplazar spr_test* por los sprites definitivos cuando estén listos.
// La lógica de prioridad y los estados FSM no cambian — solo sprite_index.
//
// ATTACK: windup + ataque activo + cooldown (recovery post-golpe)
// WALK:   hay movimiento horizontal real y no está bloqueado
// IDLE:   todo lo demás (parado, esperando, bloqueado)
//
// hitstun: el bloque de exit arriba ya salió antes de llegar aquí,
//          así que sprite_index queda en el valor del frame anterior
//          (comportamiento correcto — no mostrar walk/idle durante knockback).
// WINDUP: aviso visual antes del golpe (jugador puede preparar parry)
// ACTIVE: golpe real — hitbox viva, parry window abierta
// COOLDOWN/IDLE/CHASE: sprite neutro — no debe verse atacando
if (estate == ESTATE_ATTACK_WINDUP
||  estate == ESTATE_ATTACK_ACTIVE) {

    sprite_index = spr_test_atk;   // sin sprite de golem de ataque por ahora

} else if (abs(move_x) > 0.1 && !is_blocked_by_enemy) {

    sprite_index = spr_test_walk;

} else {

    sprite_index = spr_test_golem;  // idle — cubre COOLDOWN, PATROL parado, CHASE parado

}
