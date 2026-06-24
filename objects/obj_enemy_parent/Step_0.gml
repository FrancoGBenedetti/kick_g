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

// ── Hit flash: parpadeo visual al recibir daño ────────────
// Corre cada frame gated para decrementar el timer y actualizar image_alpha.
// image_alpha es leído por draw_self() y draw_sprite_ext() en los Draw events.
if (enemy_hit_flash_timer > 0) {
    enemy_hit_flash_timer--;
    image_alpha = ((enemy_hit_flash_timer div enemy_hit_blink_interval) mod 2 == 0) ? 0.3 : 1.0;
    if (enemy_hit_flash_timer <= 0) {
        enemy_hit_flash = false;
        image_alpha     = 1.0;
    }
} else {
    image_alpha = 1.0;
}

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

// ── Ventana de vulnerabilidad al counter ──────────────────
// Decrementada en gated junto con el hitstun (ambos respetan time_scale).
// Al expirar: el enemigo ya no es vulnerable al counter.
if (parried_vulnerable_timer > 0) {
    parried_vulnerable_timer--;
    if (parried_vulnerable_timer <= 0) {
        parried_vulnerable = false;
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

// ══════════════════════════════════════════════════════════
// SEPARACIÓN Y BLOQUEO ENTRE ENEMIGOS
// ══════════════════════════════════════════════════════════
// Dos mecanismos en un único loop with:
//
//   1. Soft push — empuje cuadrático cuando dos enemigos se solapan.
//      Resuelve solapamientos residuales suavemente.
//      Fórmula: push = sign(dx) × t² × strength × 2   (t = 1 − dist/combined_r)
//
//   2. Hard block — detención dura cuando el enemigo se mueve hacia
//      otro que tiene blocks_other_enemies = true y está a < enemy_block_distance
//      px de gap entre sus bordes de bbox. Fuerza move_x = 0.
//
// Condición compartida:
//   • vecino tiene blocks_other_enemies = true
//   • caller tiene blocked_by_other_enemies = true
//   • mismo piso: abs(vecino.y - caller.y) ≤ enemy_same_floor_tolerance
//
// Precedencia de aplicación:
//   hard blocked → move_x = soft_push_only (push separa overlap, chase cancelado)
//   solo overlap → move_x += soft_push
//   ninguno      → move_x sin cambios
//
// 'self'  dentro del with = vecino (instancia iterada)
// 'other' dentro del with = caller (instancia cuyo Step corre)
// ══════════════════════════════════════════════════════════
is_blocked_by_enemy = false;
blocking_enemy_id   = noone;
var _sep_x          = 0;
var _hard_blocked   = false;

if (enemy_separation_enabled && hitstun_timer <= 0 && blocked_by_other_enemies) {

    with (obj_enemy_parent) {
        if (id == other.id) continue;           // saltar a sí mismo
        if (!blocks_other_enemies) continue;    // vecino no bloquea

        // ── Mismo piso ────────────────────────────────────
        if (abs(y - other.y) > other.enemy_same_floor_tolerance) continue;

        var _dist_x   = abs(x - other.x);
        var _combined = enemy_separation_radius + other.enemy_separation_radius;

        // ── Soft push: solo si se solapan ─────────────────
        if (_dist_x < _combined && _dist_x >= 1) {
            // _dx_nc: vector del vecino → caller (positivo = caller está a la derecha)
            var _dx_nc = other.x - x;
            var _t     = 1 - (_dist_x / _combined);
            _sep_x += sign(_dx_nc) * _t * _t * (other.enemy_separation_strength * 2);
        }

        // ── Hard block: caller avanza hacia este vecino ───
        // Solo cuando el caller tiene velocidad intencional (move_x != 0).
        if (!_hard_blocked && other.move_x != 0) {
            var _mdir = sign(other.move_x);

            // ¿El vecino está en la dirección de movimiento del caller?
            // (x - other.x): vector caller → vecino; si coincide con _mdir, el vecino está adelante
            if (sign(x - other.x) == _mdir) {

                // Gap entre bordes frontales de bbox (negativo = ya se solapan)
                var _edge_gap;
                if (_mdir > 0) {
                    // caller mueve derecha; vecino a la derecha:
                    //   gap = vecino_left_edge - caller_right_edge
                    _edge_gap = (x + col_left) - (other.x + other.col_right);
                } else {
                    // caller mueve izquierda; vecino a la izquierda:
                    //   gap = caller_left_edge - vecino_right_edge
                    _edge_gap = (other.x + other.col_left) - (x + col_right);
                }

                if (_edge_gap < other.enemy_block_distance) {
                    _hard_blocked           = true;
                    other.blocking_enemy_id = id;   // guardar quién bloquea (debug)
                }
            }
        }
    }

    // ── Clamp del soft push ───────────────────────────────
    _sep_x = clamp(_sep_x, -enemy_separation_strength * 3, enemy_separation_strength * 3);

    // ── Aplicar ───────────────────────────────────────────
    if (_hard_blocked) {
        is_blocked_by_enemy = true;
        // Cancelar movimiento intencional.
        // Conservar soft push si hay solapamiento (para separar el overlap residual).
        move_x = (abs(_sep_x) > 0.5) ? _sep_x : 0;
    } else if (abs(_sep_x) > 0.5) {
        is_blocked_by_enemy = true;
        move_x += _sep_x;
    }
}

// ── Física / actor parent ─────────────────────────────────
event_inherited();   // → obj_actor_parent.Step: gravedad, colisiones, i-frames, etc.

// ── SLOW MOTION: actualizar image_speed con multiplicador global ─
// Permite que las animaciones del enemigo respondan a parry slow-mo
image_speed = base_image_speed * get_time_scale();
