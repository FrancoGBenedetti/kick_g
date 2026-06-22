// ══════════════════════════════════════════════════════════
// obj_time_manager — End Step
//
// Corre DESPUÉS de todos los Step events del frame.
// Aplica global.time_scale a image_speed de todos los actores
// para que las animaciones de sprites también se vean en cámara lenta.
//
// Por qué aquí y no en cada actor:
//   • El gate do_step hace que el Step de cada actor no ejecute
//     durante los frames "lentos" → image_speed no se actualiza
//     y la animación corre a velocidad normal aunque el juego esté lento.
//   • El End Step siempre ejecuta (no respeta do_step), por lo que
//     puede corregir image_speed cada frame real.
//
// Reglas:
//   • image_speed = 0  → freeze intencional (apex de salto, etc.) — no tocar
//   • image_speed > 0  → animación en marcha → escalar por time_scale
//
// Ajuste de velocidad base de animaciones:
//   Si un sprite necesita reproducirse más rápido (ej: 2×), usar
//   base_image_speed en el actor y setear:
//       image_speed = base_image_speed * global.time_scale;
//   La lógica de cada actor puede sobrescribir image_speed en su Step;
//   este End Step lo normaliza a la escala actual de tiempo.
// ══════════════════════════════════════════════════════════

var _ts = global.time_scale;

// ── Actores (jugador + enemigos) ──────────────────────────
// obj_actor_parent es el parent común de jugador y todos los enemigos.
// Esta sola línea cubre todas las animaciones de personajes.
with (obj_actor_parent) {
    if (image_speed != 0) {
        image_speed = _ts;
    }
}

// ── Proyectiles animados ──────────────────────────────────
// obj_projectile_parent para proyectiles con sprites animados.
// Los proyectiles dibujados proceduralmente (circle, etc.) no tienen
// image_speed relevante, pero aplicar no causa daño.
with (obj_projectile_parent) {
    if (image_speed != 0) {
        image_speed = _ts;
    }
}
