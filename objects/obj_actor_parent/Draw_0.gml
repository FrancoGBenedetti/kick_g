// ══════════════════════════════════════════════════════════
// OBJ_ACTOR_PARENT — Draw
// Dibuja el sprite del actor y, si corresponde, una barra de
// vida flotante en world-space sobre su cabeza.
//
// Subclases que quieran suprimir la barra flotante:
//   En su Create: show_world_healthbar = false;
//
// Subclases que quieran una barra personalizada:
//   Sobreescribir hpbar_width, hpbar_height, hpbar_offset_y,
//   hpbar_col_bg, hpbar_col_fill en su Create (después de event_inherited).
//
// IMPORTANTE: este evento reemplaza el draw_self() automático.
// draw_self() debe llamarse explícitamente para que el sprite se dibuje.
// ══════════════════════════════════════════════════════════

// ── Sprite del actor ──────────────────────────────────────
// draw_sprite_ext en lugar de draw_self() para:
//   • Aplicar draw_x/y_offset  → separación visual vs física (ground embedding)
//   • Aplicar image_xscale     → flip de sprite controlado por facing
//   • Conservar image_angle, image_blend, image_alpha del objeto
draw_sprite_ext(
    sprite_index, image_index,
    x + draw_x_offset, y + draw_y_offset,
    image_xscale, image_yscale,
    image_angle, image_blend, image_alpha
);

// ── Barra de vida flotante ────────────────────────────────
// Condiciones para mostrarla:
//   • show_world_healthbar activo (false en jugador — usa barra GUI)
//   • hp estrictamente menor que max_hp (ocultarla a full de vida)
//   • actor vivo (hp > 0 — no mostrar barra en frame de muerte)
if (show_world_healthbar && hp < max_hp && hp > 0) {
    var _bar_x = x - hpbar_width * 0.5;
    var _bar_y = y + col_top + hpbar_offset_y;

    scr_draw_healthbar(
        _bar_x, _bar_y,
        hpbar_width, hpbar_height,
        hp, max_hp,
        hpbar_col_bg,
        hpbar_col_fill
    );
}
