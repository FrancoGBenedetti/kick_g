var _draw_angle = (bridge_side == 1) ? bridge_angle : 180 - bridge_angle;
var _end_x = x + lengthdir_x(bridge_length, _draw_angle);
var _end_y = y + lengthdir_y(bridge_length, _draw_angle);

var _dc = draw_get_color();
var _da = draw_get_alpha();

draw_set_alpha(1);

if (sprite_exists(bridge_sprite)) {
    var _sprite_w = max(sprite_get_width(bridge_sprite), 1);
    var _sprite_scale = bridge_length / _sprite_w;
    draw_sprite_ext(
        bridge_sprite,
        0,
        x,
        y + bridge_visual_yoff,
        _sprite_scale,
        _sprite_scale * bridge_visual_yscale,
        _draw_angle,
        c_white,
        1
    );
} else {
    draw_set_color(make_color_rgb(115, 74, 38));
    draw_line_width(x, y, _end_x, _end_y, bridge_thickness);
    draw_set_color(make_color_rgb(194, 137, 72));
    draw_line_width(x, y - 2, _end_x, _end_y - 2, 3);
}

// Pivote.
draw_set_color(make_color_rgb(70, 70, 70));
draw_circle(x, y, 13, false);
draw_set_color(c_white);
draw_circle(x, y, 5, false);

// Target de flecha.
draw_set_color(c_red);
draw_circle(target_x, target_y, target_radius, false);
draw_set_color(c_white);
draw_circle(target_x, target_y, target_radius * 0.58, false);
draw_set_color(c_red);
draw_circle(target_x, target_y, target_radius * 0.25, false);

if (bridge_debug_draw) {
    draw_set_alpha(0.25);
    draw_set_color(c_lime);
    draw_line_width(x, y, _end_x, _end_y, bridge_thickness + bridge_collision_padding * 2);
}

draw_set_color(_dc);
draw_set_alpha(_da);
