// ══════════════════════════════════════════════════════════
// OBJ_ENEMY_ARCHER — Step
// FSM: PATROL → AIM (carga 45f) → dispara → COOLDOWN → AIM/PATROL
//
// El arquero se detiene al ver al jugador, calcula un ángulo
// acotado hacia él, carga durante aim_charge_time frames y
// dispara obj_enemy_arrow. Cooldown antes del siguiente disparo.
// ══════════════════════════════════════════════════════════
if (!global.do_step) exit;

// ── HITSTUN ───────────────────────────────────────────────
if (hitstun_timer > 0) {
    event_inherited();
    exit;
}

// ── DETECCIÓN DEL JUGADOR ─────────────────────────────────
var _player_exists = instance_exists(obj_player);
var _dist          = 0;
var _chase_dir     = 0;

if (_player_exists) {
    _dist      = point_distance(x, y, obj_player.x, obj_player.y);
    _chase_dir = sign(obj_player.x - x);
}

// ── TIMERS ────────────────────────────────────────────────
if (shoot_cooldown_timer > 0) shoot_cooldown_timer--;

// ─────────────────────────────────────────────────────────
// Helper local: calcular ángulo limitado hacia el jugador.
// Negativo = arriba, positivo = abajo. Acotado a aim_angle_min/max.
// ─────────────────────────────────────────────────────────
var _calc_aim = function() {
    if (!instance_exists(obj_player)) return 0;
    var _dy  = obj_player.y - y;
    var _adx = abs(obj_player.x - x);
    if (_adx < 1) _adx = 1;   // evitar arctan2(dy, 0) inestable
    var _raw = radtodeg(arctan2(_dy, _adx));
    return clamp(_raw, aim_angle_min, aim_angle_max);
};

// ══════════════════════════════════════════════════════════
// TRANSICIONES DE ESTADO
// ══════════════════════════════════════════════════════════
switch (estate) {

    case ESTATE_PATROL:
        if (_player_exists && _dist < detection_range) {
            estate    = ESTATE_AIM;
            aim_timer = aim_charge_time;
            // Orientarse hacia el jugador
            if (_chase_dir != 0) facing = _chase_dir;
            aim_angle = _calc_aim();
        }
    break;

    case ESTATE_AIM:
        if (!_player_exists || _dist >= detection_range * 1.3) {
            // Jugador desapareció o salió del rango ampliado → cancelar
            estate    = ESTATE_PATROL;
            aim_timer = 0;
            aim_angle = 0;
            patrol_dir = facing;
        }
    break;

    case ESTATE_COOLDOWN:
        if (shoot_cooldown_timer <= 0) {
            if (_player_exists && _dist < detection_range) {
                estate    = ESTATE_AIM;
                aim_timer = aim_charge_time;
                if (_chase_dir != 0) facing = _chase_dir;
                aim_angle = _calc_aim();
            } else {
                estate     = ESTATE_PATROL;
                patrol_dir = facing;
            }
        }
    break;
}

// ══════════════════════════════════════════════════════════
// IA POR ESTADO
// ══════════════════════════════════════════════════════════
switch (estate) {

    case ESTATE_PATROL:
        if (can_patrol) {
            // Patrulla activa: detectar borde y caminar
            if (isGrounded) {
                var _probe_x = x + patrol_dir * (abs(col_right) + 1);
                var _probe_y = y + col_bottom + 1;
                if (!tile_solid_at(collision_map, _probe_x, _probe_y)) {
                    patrol_dir = -patrol_dir;
                }
            }
            move_x = patrol_dir * walk_speed;
        } else {
            // IDLE: estático, mirando al jugador si lo ve
            move_x = 0;
            if (_player_exists && _chase_dir != 0) {
                facing = _chase_dir;
            }
        }
    break;

    case ESTATE_AIM:
        // Parado, actualizando ángulo y facing
        move_x = 0;
        if (_player_exists) {
            if (_chase_dir != 0) facing = _chase_dir;
            aim_angle = _calc_aim();
        }

        aim_timer--;
        if (aim_timer <= 0) {
            // ── DISPARO ───────────────────────────────────────
            var _enemy_id = id;
            var _spawn_x  = x + (facing > 0 ? col_right + 8 : col_left - 8);
            var _spawn_y  = y - 24;   // altura aproximada de pecho — ajustar con sprite

            var _arrow = instance_create_layer(_spawn_x, _spawn_y, "Instances_2", obj_enemy_arrow);
            with (_arrow) {
                owner   = _enemy_id;
                damage  = _enemy_id.enemy_damage;
                var _rad = degtorad(_enemy_id.aim_angle);
                // vel_x: dirección del facing × velocidad × cos(ángulo)
                // vel_y: velocidad × sin(ángulo)  (negativo = arriba en coords de pantalla)
                vel_x = _enemy_id.facing * _enemy_id.arrow_speed * cos(_rad);
                vel_y = _enemy_id.arrow_speed * sin(_rad);
            }

            show_debug_message("[DBG] ARCHER disparó: angle=" + string(aim_angle)
                + "  facing=" + string(facing));

            shoot_cooldown_timer = shoot_cooldown_max;
            aim_angle = 0;
            estate = ESTATE_COOLDOWN;
        }
    break;

    case ESTATE_COOLDOWN:
        move_x = 0;
    break;
}

// ── FÍSICA ────────────────────────────────────────────────
event_inherited();

// ── POST-FÍSICA ───────────────────────────────────────────
if (estate == ESTATE_PATROL && wallContact && wallSide == patrol_dir) {
    patrol_dir = -patrol_dir;
}
