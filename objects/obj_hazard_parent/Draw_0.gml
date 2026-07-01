if (!hazard_debug_draw) exit;

var _dc = draw_get_color();
var _da = draw_get_alpha();

draw_set_color(hazard_debug_color);
draw_set_alpha(0.28);
draw_rectangle(
    x + hazard_xoff,
    y + hazard_yoff,
    x + hazard_xoff + hazard_w,
    y + hazard_yoff + hazard_h,
    false
);

draw_set_alpha(0.8);
draw_rectangle(
    x + hazard_xoff,
    y + hazard_yoff,
    x + hazard_xoff + hazard_w,
    y + hazard_yoff + hazard_h,
    true
);

draw_set_color(_dc);
draw_set_alpha(_da);
