var _sprite = bridge_current_sprite;

if (sprite_exists(_sprite)) {
    var _scale = bridge_visual_width / max(sprite_get_width(_sprite), 1);
    draw_sprite_ext(
        _sprite,
        0,
        x,
        y + bridge_visual_yoff,
        _scale,
        _scale,
        0,
        c_white,
        1
    );
}

trigger_debug_draw();
