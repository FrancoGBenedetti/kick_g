draw_self();

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

if (spider_debug_draw) {
    var _dc = draw_get_color();
    var _da = draw_get_alpha();

    draw_set_alpha(0.18);
    draw_set_color(c_red);
    draw_rectangle(
        home_x - spider_detect_range_x,
        home_y - spider_detect_range_y,
        home_x + spider_detect_range_x,
        home_y + spider_detect_range_y,
        false
    );

    draw_set_alpha(1);
    draw_set_color(c_yellow);
    draw_circle(home_x, home_y, 6, false);

    draw_set_color(_dc);
    draw_set_alpha(_da);
}

event_inherited();
