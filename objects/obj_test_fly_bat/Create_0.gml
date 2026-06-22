// ══════════════════════════════════════════════════════════
// OBJ_TEST_FLY_BAT — Create
// Enemigo volador de prueba. Hereda de obj_enemy_parent para
// recibir el sistema completo de daño, blink, hitstun, knockback
// y barra de vida. NO usa gravedad.
//
// Herencia:
//   obj_actor_parent
//     └─ obj_enemy_parent
//          └─ obj_test_fly_bat   (este objeto)
//
// Comportamiento:
//   • Flota con movimiento senoidal en Y.
//   • Patrulla horizontalmente y rebota en muros.
//   • Al detectar al jugador en shoot_range, dispara
//     obj_fly_bat_lightning_ball hacia él.
// ══════════════════════════════════════════════════════════
event_inherited();   // obj_enemy_parent → obj_actor_parent

// ── Anular gravedad ───────────────────────────────────────
// obj_actor_parent inicializa grav = 0.5; en 0 el bat no cae.
grav = 0;

// ── Salud ─────────────────────────────────────────────────
max_hp = 3;
hp     = max_hp;

// ── Desactivar comportamientos terrestres del parent ──────
contact_damage_enabled   = false;   // daño de contacto: usa proyectil
enemy_separation_enabled = false;   // sin separación; vuela solo
blocks_other_enemies     = false;   // no actúa como pared para otros
blocked_by_other_enemies = false;   // no se detiene ante otros enemigos

// ── Flotación horizontal ──────────────────────────────────
fly_dir   = choose(-1, 1);   // dirección inicial aleatoria
fly_speed = 1.5;             // px/frame horizontal

// ── Flotación vertical senoidal ───────────────────────────
base_y                = y;     // posición Y de referencia (nunca cambia)
fly_vertical_phase    = random(360);  // radianes — fase inicial aleatoria
fly_vertical_speed    = 0.05;         // radianes/frame — velocidad de oscilación
fly_vertical_amplitude = 8;           // px de amplitud arriba/abajo

// ── Knockback ajustado para volador ──────────────────────
// El actor_parent aplica knockback_y_force al recibir daño.
// Valor más suave para que el bat no salte demasiado.
knockback_y_force = -2;

// ── Disparo ───────────────────────────────────────────────
shoot_range        = 260;   // px (point_distance al jugador)
shoot_cooldown     = 30;    // frames de gracia inicial (no dispara de inmediato)
shoot_cooldown_max = 90;    // frames entre disparos (~1.5 s a 60 fps)

// ── Datos del proyectil ───────────────────────────────────
enemy_damage         = 1;   // daño de la bola rayo
lightning_ball_speed = 4;   // px/frame del proyectil
