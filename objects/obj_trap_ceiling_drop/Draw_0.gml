var _visual_y = y + drop_visual_yoff;
var _sprite = cover_sprite;

if (trap_state == TRAP_STATE_DONE) {
    _sprite = broken_sprite;
}

draw_sprite_ext(
    _sprite,
    0,
    x,
    _visual_y,
    image_xscale * trap_visual_xscale,
    image_yscale * trap_visual_yscale,
    image_angle,
    image_blend,
    image_alpha
);
