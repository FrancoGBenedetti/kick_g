event_inherited();

// ══════════════════════════════════════════════════════════
// OBJ_ENEMY_BASIC — Create
// Enemigo con FSM de dos estados: PATROL y CHASE.
//
// Hereda de obj_actor_parent:
//   gravedad, colisiones de tile, take_damage, hitstun,
//   knockback, i-frames, is_invulnerable, on_damage, die.
// ══════════════════════════════════════════════════════════

// ── I-frames desactivados ─────────────────────────────────
// Enemigos básicos no tienen invulnerabilidad post-daño.
// Para convertirlo en élite/mini-boss: invuln_on_damage = true
invuln_on_damage = false;

// ── Salud ─────────────────────────────────────────────────
max_hp = 3;
hp     = max_hp;

// ── FSM — estados ─────────────────────────────────────────
// Constantes de estado almacenadas como variables de instancia.
// Se usan en Step_0 para las transiciones y la lógica de IA.
// Extensible: añadir STATE_STUN, STATE_ATTACK, STATE_DEAD, etc.
STATE_PATROL = 0;   // patrulla horizontal sin objetivo
STATE_CHASE  = 1;   // persecución activa del jugador

state = STATE_PATROL;

// ── Patrulla ──────────────────────────────────────────────
// Velocidades calibradas para mundo con tiles 64px y cámara 960×540.
// Un enemigo que camina 2px/frame cruza 960px en 8 segundos (correcto).
walk_speed = 2;     // px/frame — era 1 (parecía inmóvil con tiles 64px)
patrol_dir = 1;     // +1 derecha | -1 izquierda

// ── Persecución ───────────────────────────────────────────
// detection_range: el jugador mide ~170px → 400px da ~2.4 "cuerpos" de distancia.
// chase_speed 4px/frame crea una amenaza real sin ser injusto.
detection_range = 400;  // px — era 200 (activaba muy tarde en pantalla grande)
chase_speed     = 4;    // px/frame — era 2 (casi igual que la patrulla)

// ── Contacto con el jugador ───────────────────────────────
contact_damage         = 1;
contact_cooldown_max   = 30;  // frames entre intentos de daño por toque
contact_cooldown_timer = 0;

// ── Pausa de readquisición post-daño ─────────────────────
// Cuando el enemigo recibe daño (ej: pogo del jugador),
// espera reacquire_wait_max frames antes de reanudar la persecución.
// Evita el temblor cuando el jugador rebota directamente encima.
// También define un umbral mínimo de distancia horizontal:
// si el jugador está más cerca que chase_min_dx, el enemigo
// se detiene en vez de oscilar izquierda-derecha.
reacquire_timer    = 0;    // cuenta regresiva activa; 0 = persiguiendo
reacquire_wait_max = 20;   // frames de pausa (~0.33s a 60fps) — configurable
chase_min_dx       = 16;   // px — era 8 (muy pequeño con sprites HD, causaba vibración)

// ── Hooks de reacción ─────────────────────────────────────
on_damage = function(_amount, _source) {
    // Iniciar pausa de readquisición: previene el temblor cuando el
    // jugador rebota directamente sobre el enemigo (pogo attack).
    reacquire_timer = reacquire_wait_max;
    show_debug_message("[DBG] ENEMY_BASIC on_damage: amount=" + string(_amount)
        + "  hp=" + string(hp)
        + "  state=" + string(state)
        + "  hitstun=" + string(hitstun_timer));
};

die = function() {
    show_debug_message("[DBG] ENEMY_BASIC die()");

    // Mismo protocolo de notificación que obj_enemy_parent/Create_0.gml →
    // die(). obj_enemy_basic hereda de obj_actor_parent directo (no de
    // obj_enemy_parent), así que necesita su propia copia de este bloque.
    if (variable_instance_exists(id, "spawner_owner")
    && !spawner_death_reported
    && instance_exists(spawner_owner)) {
        spawner_death_reported = true;
        spawner_owner.spawner_on_enemy_died(id);
    }

    if (variable_instance_exists(id, "battleroom_owner")
    && !battleroom_death_notified
    && instance_exists(battleroom_owner)) {
        battleroom_death_notified = true;
        battleroom_owner.battleroom_on_enemy_died(id);
    }

    instance_destroy();
};
