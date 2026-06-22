// ── Singleton ─────────────────────────────────────────────
// Si ya existe una instancia, esta es un duplicado → destruir.
// Esto protege contra carga múltiple de rooms con el objeto.
if (instance_number(obj_time_manager) > 1) {
    instance_destroy();
    exit;
}

// ── Escala de tiempo global ───────────────────────────────
// 1.0  = velocidad normal
// 0.0  = congelado
// >1.0 = acelerado (para cinemáticas)
global.time_scale   = 1.0;

// Escala para cámara lenta (usada por time_set_slow()).
// Ajustar aquí para cambiar la intensidad de la cámara lenta.
// TEMP DEBUG VALUE (normal: 0.2) ← cambiar a 0.2 para producción
// 0.1 = 10% de velocidad → slow-mo muy visible para testear parry timing.
global.slowmo_scale = 0.1;   // TEMP DEBUG: más lento para visualizar parry

// ── Frame-skip accumulator ────────────────────────────────
// Mecanismo: cada Begin Step se suma time_scale al acumulador.
// Cuando llega a 1.0, se "consume" un game-step (do_step = true).
// Al 1.0×: do_step = true cada frame (60fps).
// Al 0.2×: do_step = true cada ~5 frames (12fps equivalente).
// Al 0.0×: do_step = false siempre (congelado).
global.step_accum = 0.0;
global.do_step    = true;   // true en el primer frame para inicio limpio

// ── Debug flags ───────────────────────────────────────────
// F3 → alternar visualización de hitboxes/líneas de ataque enemigo.
// true por defecto para facilitar pruebas; cambiar a false antes de shipping.
global.debug_enemy_attacks = true;
// Knockback debug — muestra hsp/vsp/hitstun sobre jugador y enemigos
global.debug_knockback     = false;   // activar en runtime o setear true aquí
// Counter attack debug — muestra ventana de counter y estado del target sobre jugador/enemigos
global.debug_counterattack = false;   // activar en runtime o setear true aquí
// Air sword bounce debug — muestra cooldown, speed, flash de impacto aéreo
global.debug_air_sword_bounce = false; // activar en runtime o setear true aquí
// Super energy debug — muestra medidor, ganancias y flags de habilidad
global.debug_super_energy    = false;  // activar en runtime o setear true aquí
// Debug collision view — modo debug de colisión activado con tecla H
// Muestra: tiles de colisión, bbox del player, hitboxes de enemigos, etc.
global.debug_collision_view = false; // false = normal gameplay (default)

// ── Inicializar debug collision view ──────────────────────
// La capa de colisión se oculta al inicio del room.
// Se puede mostrar/ocultar durante gameplay con tecla H.
global.debug_collision_view = false;
scr_hide_collision_layer();
