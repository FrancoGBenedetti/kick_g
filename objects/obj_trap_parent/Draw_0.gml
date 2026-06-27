var _spr = cover_sprite;
var _dx = x;
var _dy = y;

if (trap_state == TRAP_STATE_ACTIVE
||  trap_state == TRAP_STATE_RECOVERY
||  trap_state == TRAP_STATE_DONE) {
    if (broken_sprite != noone) {
        _spr = broken_sprite;
        _dx += broken_xoff;
        _dy += broken_yoff;
    }
}

if (_spr != noone) {
    draw_sprite_ext(
        _spr,
        0,
        _dx,
        _dy,
        image_xscale * trap_visual_xscale,
        image_yscale * trap_visual_yscale,
        image_angle,
        image_blend,
        image_alpha
    );
}

if (trap_debug_draw) {
    draw_set_alpha(0.35);
    draw_set_colour(c_yellow);
    if (trigger_mode == TRAP_TRIGGER_RECT) {
        draw_rectangle(
            x + trigger_xoff,
            y + trigger_yoff,
            x + trigger_xoff + trigger_w,
            y + trigger_yoff + trigger_h,
            false
        );
    } else {
        draw_circle(x, y, trigger_range, false);
    }

    if (payload_damage) {
        draw_set_colour(c_red);
        draw_rectangle(
            x + hitbox_xoff,
            y + hitbox_yoff,
            x + hitbox_xoff + hitbox_w,
            y + hitbox_yoff + hitbox_h,
            false
        );
    }
    draw_set_alpha(1);
    draw_set_colour(c_white);
}
