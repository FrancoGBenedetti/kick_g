var _outer = was_parried ? c_aqua : make_color_rgb(190, 70, 220);
var _inner = was_parried ? c_white : make_color_rgb(255, 170, 255);

draw_set_alpha(0.3);
draw_set_color(_outer);
draw_circle(x, y, hit_radius + 4, false);
draw_set_alpha(1);
draw_circle(x, y, hit_radius, false);
draw_set_color(_inner);
draw_circle(x, y, hit_radius * 0.45, false);
draw_set_color(c_white);

