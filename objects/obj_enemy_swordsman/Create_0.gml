// ══════════════════════════════════════════════════════════
// OBJ_ENEMY_SWORDSMAN — Create
// Enemigo melee. Patrulla, detecta al jugador, se acerca
// y ataca con un golpe de espada precedido de un windup.
//
// Hereda de obj_enemy_parent → obj_actor_parent:
//   gravedad, colisiones, take_damage, hitstun, knockback, facing,
//   on_damage, die, ESTATE_PATROL, ESTATE_CHASE, detection_range,
//   reacquire_timer, walk_speed, patrol_dir, attack_cooldown_timer.
// ══════════════════════════════════════════════════════════
event_inherited();   // obj_enemy_parent → obj_actor_parent

// ── Salud ──────────────────────────────────────────────────
max_hp = 4;
hp     = max_hp;

// ── Flags de IA ───────────────────────────────────────────
can_patrol    = true;    // patrulla cuando no hay jugador
can_chase     = true;    // persigue al jugador
can_drop_down = true;    // puede caer por bordes buscando al jugador

// ── Rango y velocidad ─────────────────────────────────────
detection_range = ESWORDSMAN_AGGRO_RANGE;   // px circular — legado
chase_speed     = 3;     // px/frame — más rápido que la patrulla

// Distancia horizontal a la que el enemigo se detiene y ataca.
// Calculada para que la hitbox real conecte: offset_x + w/2 - margen = 60 px.
// Si se ajusta la hitbox (esword_hitbox_offset_x / esword_hitbox_w), recalcular aquí.
attack_stop_distance     = ESWORDSMAN_ATTACK_STOP_DIST;   // px horizontal
attack_vertical_tolerance = ESWORDSMAN_ATTACK_VERT_TOL;   // px vertical

// stop_distance: usado en CHASE para no empujar al jugador.
// Igual a attack_stop_distance para que el enemigo siempre se acerque a rango válido.
stop_distance = ESWORDSMAN_ATTACK_STOP_DIST;

// ── Rangos de aggro 2D (sobreescriben defaults del parent) ────
aggro_range_x      = ESWORDSMAN_AGGRO_RANGE;   // px — mismo que circular para consistencia
aggro_range_y      = 160;   // px vertical — detecta si el jugador está arriba/abajo
lose_aggro_range_x = ESWORDSMAN_AGGRO_RANGE + 128;  // px — pierde aggro algo más lejos
lose_aggro_range_y = 240;

// ── FSM: estados adicionales del espadachín ───────────────
// Amplían el ESTATE_ATTACK base con tres sub-fases distintas.
ESTATE_ATTACK_WINDUP = 2;   // anticipa el ataque (sin hitbox)
ESTATE_ATTACK_ACTIVE = 3;   // hitbox activa
ESTATE_COOLDOWN      = 4;   // recuperación post-ataque

// ── Parámetros de ataque ──────────────────────────────────
attack_windup        = ESWORDSMAN_WINDUP;    // frames de anticipación
attack_windup_timer  = 0;
attack_active_time   = ESWORDSMAN_ACTIVE;    // frames de hitbox activa
attack_active_timer  = 0;
attack_cooldown_max  = ESWORDSMAN_COOLDOWN;  // frames entre ataques
enemy_damage         = ESWORDSMAN_DAMAGE;    // daño por golpe

// Ajuste fino: si el enemigo entró en WINDUP pero el jugador se alejó
// más de esta distancia durante el windup, cancelar el ataque.
// Evita que el golpe salga en el aire si el jugador retrocede rápido.
attack_cancel_dist = attack_stop_distance + 24;   // px — margen generoso

// ── Hitbox de espada ──────────────────────────────────────
// Posición relativa al origen del enemigo (afectada por facing).
// Ajustar tras asignar el sprite definitivo.
sword_hitbox_id       = noone;
esword_hitbox_offset_x = 44;   // px hacia adelante (× facing al reposicionar)
esword_hitbox_offset_y = -18;  // px hacia arriba del origen
esword_hitbox_w        = 52;   // ancho del área de golpe
esword_hitbox_h        = 42;   // alto del área de golpe

// ── Override de on_damage ─────────────────────────────────
on_damage = function(_amount, _source) {
    reacquire_timer = reacquire_wait_max;
    // Destruir hitbox activa si el enemigo es golpeado durante el ataque
    if (instance_exists(sword_hitbox_id)) {
        with (sword_hitbox_id) instance_destroy();
        sword_hitbox_id = noone;
    }
    // Interrumpir windup/ataque activo → volver a CHASE
    if (estate == ESTATE_ATTACK_WINDUP || estate == ESTATE_ATTACK_ACTIVE) {
        estate              = ESTATE_CHASE;
        attack_windup_timer = 0;
        attack_active_timer = 0;
    }
    show_debug_message("[DBG] SWORDSMAN on_damage: hp=" + string(hp)
        + "  hitstun=" + string(hitstun_timer));
};
