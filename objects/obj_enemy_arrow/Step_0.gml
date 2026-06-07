// ══════════════════════════════════════════════════════════
// OBJ_ENEMY_ARROW — Step
// Toda la física (gravedad, movimiento, colisión de tiles,
// hit al jugador, destrucción por espada, lifetime y bounds)
// la maneja obj_projectile_parent.
//
// Este Step es minimal — delega completamente al parent.
//
// Para agregar comportamiento específico de la flecha enemiga:
//   • Lógica PRE-física : añadir ANTES de event_inherited()
//     Ejemplo: cambio de dirección, homing hacia el jugador
//   • Lógica POST-física: añadir DESPUÉS de event_inherited()
//     Ejemplo: trail de partículas, sonido de vuelo por frame
// ══════════════════════════════════════════════════════════
event_inherited();
