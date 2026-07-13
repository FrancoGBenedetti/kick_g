// ══════════════════════════════════════════════════════════
// ENEMY SPAWNER — Step
//
// Maneja spawn_delay_timer / spawn_interval_timer. El spawn real SIEMPRE
// pasa por acá (nunca de forma síncrona dentro de spawner_activate()), así
// que el comportamiento es consistente sin importar si spawn_delay es 0 o
// mayor a 0.
// ══════════════════════════════════════════════════════════

if (!global.do_step) exit;
if (!active || finished) exit;

if (spawn_delay_timer > 0) {
    spawn_delay_timer--;
    exit;
}

if (spawn_interval_timer > 0) {
    spawn_interval_timer--;
    exit;
}

var _ok = spawner_spawn_enemy();

if (!_ok || spawned_enemy_count >= spawn_count) {
    // Falló (sin enemy_object ni fallback) o ya completó spawn_count —
    // en ambos casos, terminar la secuencia. Nunca reintenta en loop.
    spawner_finish();
} else {
    spawn_interval_timer = max(1, spawn_interval);   // al menos 1 frame, nunca 0 (evita loop en el mismo frame)
}
