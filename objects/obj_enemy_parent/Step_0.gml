// ══════════════════════════════════════════════════════════
// OBJ_ENEMY_PARENT — Step
// Lógica compartida de todos los enemigos. Corre como parte
// de la cadena event_inherited() de cada enemigo hijo.
//
// Responsabilidades:
//   • Decrementar counter_window_timer y limpiar can_be_countered
//   • Limpiar is_parried_stunned cuando hitstun termina
//   • Delegar física al parent (obj_actor_parent)
//
// Los hijos (swordsman, archer) llaman event_inherited() al
// final de su Step, lo que ejecuta este evento, que a su vez
// llama event_inherited() hacia obj_actor_parent.
//
// Flujo completo:
//   EnemyChild.Step
//     → event_inherited()
//         → OBJ_ENEMY_PARENT.Step (este archivo)
//             → event_inherited()
//                 → OBJ_ACTOR_PARENT.Step
// ══════════════════════════════════════════════════════════
if (!global.do_step) exit;

// ── Ventana de contraataque ───────────────────────────────
// Decrementada cada frame gated (respeta time_scale).
// Cuando expira: limpiar can_be_countered para que futuros
// sistemas de contraataque no actúen fuera de ventana.
if (counter_window_timer > 0) {
    counter_window_timer--;
    if (counter_window_timer <= 0) {
        can_be_countered = false;
    }
}

// ── Limpiar parry stun al terminar hitstun ────────────────
// is_parried_stunned se activa cuando un parry perfecto aplica
// hitstun extendido. Debe limpiarse al salir del hitstun para
// que el enemigo recupere su FSM normalmente.
//
// NOTA: hitstun_timer se decrementa DENTRO de event_inherited()
// (en obj_actor_parent.Step). Este check se ejecuta ANTES de esa
// llamada, así que usa el valor del frame anterior.
// Resultado: is_parried_stunned se limpia en el mismo frame en que
// hitstun_timer llegó a 0, antes del siguiente Step del enemigo.
if (is_parried_stunned && hitstun_timer <= 0) {
    is_parried_stunned = false;
}

// ── Debug: ventana de contraataque ───────────────────────
// Solo si global.debug_enemy_attacks está activo.
// El draw visual se hace en Draw_0 de cada hijo (o aquí si se agrega).

// ── Daño por contacto al jugador ─────────────────────────
// Corre cada frame gated. El cooldown interno impide daño continuo.
// take_damage() del jugador aplica i-frames → el jugador no recibe
// daño cada frame aunque el cooldown esté a 0.
// El enemigo NO se daña a sí mismo ni a otros enemigos por contacto.
if (contact_damage_enabled && hitstun_timer <= 0) {
    if (contact_damage_cooldown > 0) {
        contact_damage_cooldown--;
    } else if (instance_exists(obj_player)) {
        if (bbox_right  > obj_player.bbox_left
        &&  bbox_left   < obj_player.bbox_right
        &&  bbox_bottom > obj_player.bbox_top
        &&  bbox_top    < obj_player.bbox_bottom) {
            obj_player.take_damage(contact_damage, id);
            contact_damage_cooldown = contact_damage_cooldown_max;
        }
    }
}

// ── Separación / fila entre enemigos ─────────────────────
// La fuerza de separación SOLO se aplica cuando tiene sentido competir
// por posición frente al jugador. Dos enemigos patrullando pueden
// cruzarse libremente — no tienen razón para bloquearse.
//
// CONDICIONES para aplicar bloqueo (todas deben cumplirse):
//   1. Ambos enemigos están en chase/ataque (no patrullando).
//   2. Ambos están dentro de enemy_queue_distance_to_player del jugador.
//   3. Ambos están en el mismo piso (abs(dy) ≤ enemy_same_floor_tolerance).
//
// Si alguna condición falla: los enemigos se ignoran → pueden cruzarse.
//
// Fórmula de push cuadrático (cuando aplica):
//   t = 1 − (dist / combined_radius)   → 0 en el borde, 1 en solapado
//   push = sign(dx) × t² × strength × 2
//
// 'other' dentro del with = contexto llamante (enemigo siendo procesado)
// 'self'  dentro del with = enemigo iterado (vecino)
is_blocked_by_enemy = false;

if (enemy_separation_enabled && hitstun_timer <= 0) {
    var _sep_x         = 0;
    var _player_exists = instance_exists(obj_player);

    with (obj_enemy_parent) {
        if (id == other.id) continue;   // saltar a sí mismo

        // ── Condición 1: ambos en estado aggro (chase/ataque) ─────
        // ESTATE_PATROL = 0 → no es aggro; cualquier otro estado → aggro.
        // 'other.estate' = estado del llamante (instancia que llama el with).
        // 'estate'       = estado del vecino (instancia iterada).
        // Si alguno patrulla: se ignoran y pueden cruzarse libremente.
        if (other.estate == ESTATE_PATROL || estate == ESTATE_PATROL) continue;

        // ── Condición 2: ambos suficientemente cerca del jugador ──
        // Si alguno está lejos, no tienen razón para competir por posición.
        if (!instance_exists(obj_player)) continue;
        var _caller_dist   = point_distance(other.x, other.y, obj_player.x, obj_player.y);
        var _neighbor_dist = point_distance(x, y, obj_player.x, obj_player.y);
        if (_caller_dist   >= other.enemy_queue_distance_to_player) continue;
        if (_neighbor_dist >= enemy_queue_distance_to_player)       continue;

        // ── Condición 3: mismo piso ───────────────────────────────
        var _floor_dy = abs(other.y - y);
        if (_floor_dy > other.enemy_same_floor_tolerance) continue;

        // ── Todas las condiciones OK: calcular fuerza de separación ─
        var _dx       = other.x - x;   // vector del vecino → al llamante
        var _dist     = abs(_dx);
        var _combined = other.enemy_separation_radius + enemy_separation_radius;

        if (_dist < _combined && _dist >= 1) {
            var _t    = 1 - (_dist / _combined);
            var _push = sign(_dx) * _t * _t * (other.enemy_separation_strength * 2);
            _sep_x += _push;
        }
    }

    // Clampear para evitar explosiones con 3+ enemigos apiñados
    _sep_x = clamp(_sep_x, -enemy_separation_strength * 3, enemy_separation_strength * 3);

    if (abs(_sep_x) > 0.5) {
        is_blocked_by_enemy = true;
        move_x += _sep_x;
    }
}

// ── Física / actor parent ─────────────────────────────────
event_inherited();   // → obj_actor_parent.Step: gravedad, colisiones, i-frames, etc.
