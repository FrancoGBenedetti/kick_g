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

// ── BASE IMAGE SPEED — ajustado para este enemigo ──────────
// Sobrescribir el valor del parent (0.2) si es necesario
base_image_speed = 0.2;

// ── Salud ──────────────────────────────────────────────────
// Aplicar multiplicador de testing (global.enemy_test_hp_multiplier)
// Default: max_hp = 4, con multiplicador x2 = 8
var _base_hp = 4;
max_hp = ceil(_base_hp * global.enemy_test_hp_multiplier);
hp     = max_hp;

// ── Flags de IA ───────────────────────────────────────────
can_patrol    = true;    // patrulla cuando no hay jugador
can_chase     = true;    // persigue al jugador
can_drop_down = true;    // puede caer por bordes buscando al jugador

// El swordsman daña con su arma (hitbox), no con el cuerpo.
// Desactivar para evitar daño por colisión corporal antes/durante el ataque.
contact_damage_enabled = false;

// ── Rango y velocidad ─────────────────────────────────────
detection_range = ESWORDSMAN_AGGRO_RANGE;   // px circular — legado
chase_speed     = 3;     // px/frame — más rápido que la patrulla

// Rango de ataque en dos fases:
//   attack_trigger_distance: el enemigo "decide" atacar y entra en WINDUP.
//                            Si el jugador sigue lejos, avanza mientras anima el windup.
//   attack_stop_distance:    se detiene aquí para contar el timer y disparar la hitbox.
//                            La hitbox llega a ~76 px — asegura que el golpe conecta.
attack_trigger_distance  = ESWORDSMAN_ATTACK_TRIGGER_DIST; // px horizontal — detección
attack_stop_distance     = ESWORDSMAN_ATTACK_STOP_DIST;    // px horizontal — hitbox range
attack_vertical_tolerance = ESWORDSMAN_ATTACK_VERT_TOL;    // px vertical

// stop_distance: CHASE no empuja al jugador cuando llega a rango de hitbox.
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
// Los valores base se configuran con macros de scr_config.
// Se aplican multiplicadores de dificultad si global.current_config existe.
var _diff_mult = variable_global_exists("current_config") ? global.current_config : {
	enemy_attack_windup_multiplier: 1.0,
	enemy_attack_cooldown_multiplier: 1.0
};

attack_windup        = ceil(ESWORDSMAN_WINDUP * _diff_mult.enemy_attack_windup_multiplier);    // frames de anticipación
attack_windup_timer  = 0;
attack_active_time   = ESWORDSMAN_ACTIVE;    // frames de hitbox activa (no multiplicado)
attack_active_timer  = 0;
attack_cooldown_max  = ceil(ESWORDSMAN_COOLDOWN * _diff_mult.enemy_attack_cooldown_multiplier);  // frames entre ataques
enemy_damage         = ESWORDSMAN_DAMAGE;    // daño por golpe

// Ajuste fino: si el enemigo entró en WINDUP pero el jugador se alejó
// más de esta distancia durante el windup, cancelar el ataque.
// Evita que el golpe salga en el aire si el jugador retrocede rápido.
attack_cancel_dist = attack_trigger_distance + 32; // px — cancela si el jugador se aleja mucho durante el windup

// ── Hitbox de espada ──────────────────────────────────────
// Se extiende desde el origen del enemigo hasta attack_trigger_distance.
// Centrado en offset_x para cubrir el rango completo de ataque.
// Cuando facing=1: [0, trigger_dist]
// Cuando facing=-1: [-trigger_dist, 0]
sword_hitbox_id        = noone;
esword_hitbox_offset_x = ESWORDSMAN_HITBOX_OFFSET_X;  // centro del hitbox = trigger_dist / 2
esword_hitbox_offset_y = ESWORDSMAN_HITBOX_OFFSET_Y;  // altura media del enemigo
esword_hitbox_w        = ESWORDSMAN_HITBOX_W;         // ancho = trigger_dist (cubre todo el rango)
esword_hitbox_h        = ESWORDSMAN_HITBOX_H;         // alto = torso + piernas jugador

// ── Bloqueo de facing durante ataque ──────────────────────
// Cuando el enemigo inicia un ataque, guarda la dirección y no se gira durante
// todo el ataque (windup + active + cooldown).
// Esto permite que el player esquive detrás del enemigo sin que el ataque lo siga.
attack_facing_locked   = false;  // true = el enemigo NO puede cambiar facing
attack_facing          = 1;      // dirección guardada cuando inicia ataque

// ── Override de on_damage ─────────────────────────────────
// Captura el método del parent (blink, knockback, hitstun, i-frames)
// como variable de instancia antes de reemplazarlo, para poder encadenarlo.
// Se usa variable de instancia (no var) porque los closures de GML no capturan
// vars locales del evento Create de forma confiable.
parent_on_damage = on_damage;

on_damage = function(_amount, _source) {
    // ── Lógica compartida del parent ──────────────────────
    // Activa blink, ajusta knockback/hitstun/i-frames, reacquire_timer.
    parent_on_damage(_amount, _source);

    // ── Swordsman: limpiar hitbox activa ──────────────────
    // Si el enemigo recibe daño mientras su hitbox está activa,
    // destruirla para evitar que el jugador reciba daño durante el knockback.
    if (instance_exists(sword_hitbox_id)) {
        with (sword_hitbox_id) instance_destroy();
        sword_hitbox_id = noone;
    }

    // ── Swordsman: cancelar windup/ataque activo ──────────
    // Interrumpir ataque si el enemigo fue golpeado durante la animación.
    // Vuelve a CHASE para que la IA retome persecución al salir del hitstun.
    if (estate == ESTATE_ATTACK_WINDUP || estate == ESTATE_ATTACK_ACTIVE) {
        estate              = ESTATE_CHASE;
        attack_windup_timer = 0;
        attack_active_timer = 0;
    }
};
