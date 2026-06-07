// ══════════════════════════════════════════════════════════
// OBJ_ENEMY_ARCHER — Create
// Enemigo a distancia. Patrulla, detecta al jugador, se para,
// calcula un ángulo aproximado y dispara después de un tiempo
// de carga. Cooldown entre disparos.
//
// Hereda de obj_enemy_parent → obj_actor_parent.
// ══════════════════════════════════════════════════════════
event_inherited();

// ── Salud ──────────────────────────────────────────────────
max_hp = 3;
hp     = max_hp;

// ── Flags de IA ───────────────────────────────────────────
// El arquero permanece estático: no patrulla ni persigue.
// Detecta, apunta, carga y dispara desde su posición.
can_patrol    = false;   // no camina sin jugador detectado
can_chase     = false;   // no persigue al jugador
can_drop_down = false;   // no cae por bordes

// ── Detección y velocidad ────────────────────────────────
detection_range = EARCHER_AGGRO_RANGE;   // 500 px
walk_speed      = 1;                     // velocidad de patrulla (no usada — can_patrol=false)

// ── Parámetros de disparo ─────────────────────────────────
aim_charge_time      = EARCHER_AIM_TIME;        // 45 frames de carga
shoot_cooldown_max   = EARCHER_SHOOT_COOLDOWN;  // 90 frames entre disparos
aim_timer            = 0;
shoot_cooldown_timer = 0;

// ── Ángulo de apuntado ────────────────────────────────────
// Se calcula dinámicamente hacia el jugador, limitado por min/max.
// Convención: negativo = arriba, positivo = abajo (mismo que el jugador).
aim_angle     = 0;
aim_angle_min = EARCHER_AIM_MIN;   // -25 grados (arriba)
aim_angle_max = EARCHER_AIM_MAX;   //  25 grados (abajo)
arrow_speed   = 12;                // px/frame
enemy_damage  = EARCHER_DAMAGE;    //  1 de daño

// ── FSM: estados del arquero ──────────────────────────────
ESTATE_AIM      = 2;   // apuntando y cargando
ESTATE_COOLDOWN = 3;   // cooldown post-disparo

// ── Override de on_damage ────────────────────────────────
on_damage = function(_amount, _source) {
    reacquire_timer = reacquire_wait_max;
    // Interrumpir la carga si fue golpeado mientras apuntaba
    if (estate == ESTATE_AIM) {
        estate    = ESTATE_PATROL;
        aim_timer = 0;
        aim_angle = 0;
    }
    show_debug_message("[DBG] ARCHER on_damage: hp=" + string(hp));
};
