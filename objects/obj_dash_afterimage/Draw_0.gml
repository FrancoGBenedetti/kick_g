// ── Draw afterimage ───────────────────────────────────────
// Dibuja el frame exacto capturado del player con alpha decreciente.
// ghost_sprite / ghost_frame / ghost_xscale / ghost_yscale / ghost_angle
// se asignan en afterimage_spawn() y nunca cambian (imagen congelada).
//
// draw_sprite_ext(sprite, subimg, x, y, xscale, yscale, rot, col, alpha)
//   sprite  : sprite_index capturado del player
//   subimg  : frame (floor para evitar sub-frames → imagen limpia)
//   x / y   : posición congelada al momento del spawn
//   xscale  : image_xscale del player (incluye flip por facing)
//   yscale  : image_yscale del player
//   rot     : image_angle del player
//   col     : ghost_color (tinte: blanco azulado por defecto)
//   alpha   : ghost_alpha (decrementado en Step)

if (ghost_sprite < 0 || ghost_alpha <= 0) exit;

draw_sprite_ext(
    ghost_sprite,
    floor(ghost_frame),
    x,
    y,
    ghost_xscale,
    ghost_yscale,
    ghost_angle,
    ghost_color,
    ghost_alpha
);

// ── DEBUG (F11) ────────────────────────────────────────────
// Muestra el alpha actual de esta copia sobre su cabeza.
if (variable_global_exists("debug_dash_afterimage") && global.debug_dash_afterimage) {
    draw_set_halign(fa_center);
    draw_set_valign(fa_bottom);
    draw_set_color(c_black);
    draw_text(x + 1, y - 159, "a=" + string_format(ghost_alpha, 1, 2));
    draw_set_color(c_yellow);
    draw_text(x, y - 160, "a=" + string_format(ghost_alpha, 1, 2));
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
}
