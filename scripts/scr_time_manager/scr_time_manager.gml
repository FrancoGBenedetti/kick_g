// ══════════════════════════════════════════════════════════
// scr_time_manager — API pública del sistema de tiempo global
//
// Requiere que obj_time_manager exista e inicialice:
//   global.time_scale   (1.0 = normal)
//   global.slowmo_scale (escala de cámara lenta, default 0.2)
//   global.do_step      (true si este frame ejecuta lógica de juego)
//
// USO:
//   time_set_slow()           → cámara lenta (usa global.slowmo_scale)
//   time_set_normal()         → velocidad normal
//   time_set(_scale)          → escala arbitraria [0.0–1.0]
//   time_is_slow()            → bool: ¿está en cámara lenta?
//
// CASOS DE USO PLANIFICADOS:
//   - Hit stop (0.0–0.05 por 3–5 frames) → time_set(0.0), restaurar con timer
//   - Carga de arco en el aire           → time_set_slow() / time_set_normal()
//   - Habilidades especiales             → time_set(_scale_especifica)
//   - Cinemáticas                        → time_set(0.0) + control manual
// ══════════════════════════════════════════════════════════

// ── Activar cámara lenta ──────────────────────────────────
// Usa global.slowmo_scale (configurable en obj_time_manager Create).
function time_set_slow() {
    global.time_scale = global.slowmo_scale;
}

// ── Restaurar velocidad normal ────────────────────────────
function time_set_normal() {
    global.time_scale = 1.0;
}

// ── Escala arbitraria ─────────────────────────────────────
// @param {real} _scale   0.0 = congelado | 1.0 = normal | >1.0 = acelerado
// Sin clamp intencional: permite aceleración para cinemáticas.
function time_set(_scale) {
    global.time_scale = _scale;
}

// ── Consultar estado ──────────────────────────────────────
// @return {bool}  true si el juego está corriendo por debajo de velocidad normal
function time_is_slow() {
    return (global.time_scale < 1.0);
}
