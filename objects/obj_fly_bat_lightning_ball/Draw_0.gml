// ══════════════════════════════════════════════════════════
// OBJ_FLY_BAT_LIGHTNING_BALL — Draw
// Visual de la bola rayo: círculo amarillo con borde naranja.
// No usa sprite — se dibuja enteramente por código.
// El parent (obj_projectile_parent) dibuja overlays de debug
// al final (vector de velocidad, hit_radius, flags).
// ══════════════════════════════════════════════════════════

var _r = 8;   // radio visual (coincidir con hit_radius del Create)

// ── Núcleo amarillo ───────────────────────────────────────
draw_set_color(c_yellow);
draw_set_alpha(0.9);
draw_circle(x, y, _r, false);

// ── Borde naranja ─────────────────────────────────────────
draw_set_color(c_orange);
draw_set_alpha(1.0);
draw_circle(x, y, _r, true);

// ── Brillo interior (halo suave) ──────────────────────────
draw_set_color(c_white);
draw_set_alpha(0.35);
draw_circle(x, y, _r * 0.45, false);

draw_set_alpha(1.0);
draw_set_color(c_white);

// ── Overlays de debug del parent ──────────────────────────
// Muestra hit_radius, vector de velocidad y flags [P][B][S]
// cuando global.debug_projectiles o global.debug_hitboxes estén activos.
event_inherited();
