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
// Aplicar multiplicador de testing (global.enemy_test_hp_multiplier)
// Default: max_hp = 3, con multiplicador x2 = 6
var _base_hp = 3;
max_hp = ceil(_base_hp * global.enemy_test_hp_multiplier);
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
// Los valores base se configuran con macros de scr_config.
// Se aplican multiplicadores de dificultad si global.current_config existe.
var _diff_mult = variable_global_exists("current_config") ? global.current_config : {
	enemy_charge_time_multiplier: 1.0,
	enemy_attack_cooldown_multiplier: 1.0
};

aim_charge_time      = ceil(EARCHER_AIM_TIME * _diff_mult.enemy_charge_time_multiplier);        // 45 frames de carga (normal)
shoot_cooldown_max   = ceil(EARCHER_SHOOT_COOLDOWN * _diff_mult.enemy_attack_cooldown_multiplier);  // 90 frames entre disparos (normal)
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

// ── Offset de spawn de proyectil ───────────────────────────
// Posición relativa donde aparecen las flechas respecto al cuerpo.
// offset_x: distancia horizontal desde col_right/col_left
// offset_y: distancia vertical desde y (negativo = arriba en el sprite)
projectile_spawn_offset_x = 8;     // píxeles más allá de col_right/col_left
projectile_spawn_offset_y = -24;   // altura de pecho aproximada

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
