// ══════════════════════════════════════════════════════════
// OBJ_ENEMY_BASIC — Step
// FSM de dos estados: PATROL y CHASE.
//
// Flujo por frame:
//   1. Gate global.do_step
//   2. Hitstun gate → física pura, sin IA
//   3. Detección del jugador (distancia)
//   4. Transición de estado (PATROL ↔ CHASE)
//   5. IA por estado → decide move_x pre-física
//   6. event_inherited() → gravedad + colisiones de tile
//   7. Post-física → cambio de dir por pared, daño por contacto
// ══════════════════════════════════════════════════════════
if (!global.do_step) exit;

// ── HITSTUN: bypass de IA ─────────────────────────────────
// El parent sobreescribirá move_x con knockback_x.
// La FSM no corre durante el stun; el estado se conserva.
if (hitstun_timer > 0) {
    event_inherited();
    exit;
}

// ══════════════════════════════════════════════════════════
// DETECCIÓN DEL JUGADOR
// ══════════════════════════════════════════════════════════
// Se comprueba UNA SOLA VEZ por frame y se almacena en vars
// locales para no repetir llamadas costosas en cada bloque.

var _player_exists = instance_exists(obj_player);
var _dist          = 0;
var _chase_dir     = 0;   // dirección hacia el jugador (+1 / -1)

if (_player_exists) {
    _dist      = point_distance(x, y, obj_player.x, obj_player.y);
    _chase_dir = sign(obj_player.x - x);
    if (_chase_dir == 0) _chase_dir = patrol_dir;   // misma X → mantener dir actual
}

// ══════════════════════════════════════════════════════════
// TRANSICIÓN DE ESTADO
// ══════════════════════════════════════════════════════════

if (state == STATE_PATROL) {

    // Activar CHASE si el jugador entra en rango de detección.
    if (_player_exists && _dist < detection_range) {
        state = STATE_CHASE;
    }

} else if (state == STATE_CHASE) {

    // Volver a PATROL si el jugador desaparece o sale del rango.
    if (!_player_exists || _dist >= detection_range) {
        state = STATE_PATROL;
        // Sincronizar patrol_dir con la última dirección de movimiento
        // para que la patrulla reanude de forma coherente.
        // (facing fue actualizado por el parent en el frame anterior.)
        patrol_dir = facing;
    }

}

// ══════════════════════════════════════════════════════════
// IA POR ESTADO — decide move_x (pre-física)
// ══════════════════════════════════════════════════════════

if (state == STATE_PATROL) {

    // ── Detección de borde de plataforma ─────────────────
    // Solo en suelo — en el aire no hay borde que esquivar.
    // Corre PRE-física para que el giro influya en este frame.
    if (isGrounded) {
        var _probe_x = x + patrol_dir * (abs(col_right) + 1);
        var _probe_y = y + col_bottom + 1;
        if (!tile_solid_at(collision_map, _probe_x, _probe_y)) {
            patrol_dir = -patrol_dir;
        }
    }

    move_x = patrol_dir * walk_speed;

} else if (state == STATE_CHASE) {

    // ── Pausa de readquisición post-daño ──────────────────
    // Activo tras recibir daño (on_damage). Durante estos frames
    // el enemigo no se mueve horizontalmente, evitando que vibre
    // cuando el jugador rebota sobre él (pogo attack).
    if (reacquire_timer > 0) {
        reacquire_timer--;
        move_x = 0;

    // ── Distancia mínima horizontal ────────────────────────
    // Si el jugador está directamente encima (dx pequeño),
    // detenerse en vez de oscilar entre +1 y -1 cada frame.
    } else if (_player_exists && abs(obj_player.x - x) < chase_min_dx) {
        move_x = 0;
        // Actualizar patrol_dir para que si el jugador se aleja,
        // la persecución retome la dirección correcta.
        if (_chase_dir != 0) patrol_dir = _chase_dir;

    // ── Persecución directa ────────────────────────────────
    // Sin detección de bordes: el enemigo puede caer si el
    // jugador está en una plataforma inferior (comportamiento
    // agresivo — ajustar si se prefiere patrulla conservadora).
    } else {
        move_x     = _chase_dir * chase_speed;
        patrol_dir = _chase_dir;
    }

}

// ── FÍSICA ────────────────────────────────────────────────
// Gravedad, colisiones de tile, knockback (si hitstun > 0),
// actualización de wallContact, isGrounded, facing, etc.
event_inherited();

// ══════════════════════════════════════════════════════════
// POST-FÍSICA — wallContact actualizado por event_inherited
// ══════════════════════════════════════════════════════════

// ── Cambio de dirección por pared (solo en PATROL) ────────
// En CHASE el enemigo presiona contra la pared — es intencional.
// Si se prefiere que en CHASE también gire, eliminar la condición.
if (state == STATE_PATROL && wallContact && wallSide == patrol_dir) {
    patrol_dir = -patrol_dir;
}

// ── Daño por contacto al jugador ──────────────────────────
if (contact_cooldown_timer > 0) {
    contact_cooldown_timer--;
} else if (_player_exists) {
    if (bbox_right  > obj_player.bbox_left
    &&  bbox_left   < obj_player.bbox_right
    &&  bbox_bottom > obj_player.bbox_top
    &&  bbox_top    < obj_player.bbox_bottom) {
        obj_player.take_damage(contact_damage, id);
        contact_cooldown_timer = contact_cooldown_max;
    }
}
