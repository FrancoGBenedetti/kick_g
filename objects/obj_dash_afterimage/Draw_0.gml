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
