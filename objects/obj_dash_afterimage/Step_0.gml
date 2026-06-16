// ── Fade out ──────────────────────────────────────────────
// Reduce alpha cada frame. Al llegar a 0 o menos → destruir.
// ghost_fade viene de afterimage_spawn() (default 0.07 = ~9 frames de vida).
ghost_alpha -= ghost_fade;

if (ghost_alpha <= 0) {
    instance_destroy();
}
