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

// ── Slow Motion centralizado (con timer) ──────────────────
// Sistema nuevo para slow motion con duración automática.
// Separa el slow motion de parry del slow motion global genérico.
global.slowmo_active      = false;       // true mientras hay efecto activo
global.slowmo_timer       = 0;           // cuenta regresiva en frames reales
global.slowmo_scale_temporary = 1.0;     // escala mientras está activo

// Valores de parry específicos (configurables)
global.parry_slowmo_scale = 0.1;         // x0.1 velocidad (mismo que slowmo_scale)
global.parry_slowmo_duration = 60;       // 60 frames reales (~1 segundo)

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
// Debug collision view — modo debug de colisión activado con tecla Y
// Muestra: tiles de colisión, bbox del player, hitboxes de enemigos, etc.
// TEMP: en true por pedido explícito — collision tiles/objetos visibles
// todo el tiempo mientras se ajustan manualmente triggers/gates en el
// Room Editor. Volver a false antes de shipping (o dejar en false y usar
// Y/I en runtime — el toggle sigue funcionando igual).
global.debug_collision_view = true;

// ── Inicializar debug collision view ──────────────────────
// Aplica la visibilidad de la capa de colisión según global.debug_
// collision_view de arriba. Se puede togglear en runtime con Y (debug
// visual completo) o I (solo la capa de colisión) — ver obj_time_manager
// Step_0.gml.
scr_hide_collision_layer();

// ── Inicializar sistema de dificultad ──────────────────────
// Configura global.difficulty, global.config y global.current_config.
// También define funciones: set_difficulty(), get_difficulty_string().
global.debug_dev = false;         // modo dev: muestra hitboxes, colisiones, datos
global.debug_difficulty = false;  // toggle HUD de dificultad
global.enemy_test_hp_multiplier = 2.0;  // multiplicador de HP para testing (x2 para probar combos)
scr_difficulty_config();
show_debug_message("[INIT] Dificultad: " + get_difficulty_string());
show_debug_message("[INIT] Enemy HP multiplier: x" + string(global.enemy_test_hp_multiplier));
show_debug_message("[INIT] DEBUG: [Y]Visual [E]Easy [R]Normal [T]Hard");
show_debug_message("[INIT] CONTROLES: [DASH]Dash | [A]Roll | [B]BeatEmUp | [Z]Espada | [X]Arco");
show_debug_message("[INIT] NOTA: Jump Back desactivado. Roll (A) es acción separada. Dash es normal.");
