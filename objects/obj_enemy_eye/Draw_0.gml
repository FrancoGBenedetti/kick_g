draw_self();

if (pre_shot_count_enabled && eye_state == EYE_STATE_ATTACK) {
    var _stage_frames = max(1, attack_windup / pre_shot_count_max);
    var _elapsed = attack_windup - eye_timer;
    var _count = clamp(floor(_elapsed / _stage_frames) + 1, 1, pre_shot_count_max);
    var _stage_progress = frac(_elapsed / _stage_frames);
    var _pulse_scale = pre_shot_count_scale + sin(_stage_progress * pi) * 0.25;
    var _count_color = c_yellow;
    if (_count == 2) _count_color = make_color_rgb(255, 145, 30);
    if (_count >= 3) _count_color = c_red;

    var _old_color = draw_get_color();
    var _old_alpha = draw_get_alpha();
    var _old_halign = draw_get_halign();
    var _old_valign = draw_get_valign();

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(c_black);
    draw_set_alpha(0.65);
    draw_text_transformed(x + 2, y + pre_shot_count_yoff + 2, string(_count), _pulse_scale, _pulse_scale, 0);
    draw_set_color(_count_color);
    draw_set_alpha(1);
    draw_text_transformed(x, y + pre_shot_count_yoff, string(_count), _pulse_scale, _pulse_scale, 0);

    draw_set_color(_old_color);
    draw_set_alpha(_old_alpha);
    draw_set_halign(_old_halign);
    draw_set_valign(_old_valign);
}

event_inherited();
