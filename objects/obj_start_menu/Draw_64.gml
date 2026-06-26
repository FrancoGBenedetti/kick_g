var _gw = display_get_gui_width();
var _gh = display_get_gui_height();

draw_set_alpha(1);
draw_set_color(c_black);
draw_rectangle(0, 0, _gw, _gh, false);

draw_set_halign(fa_center);
draw_set_valign(fa_middle);

draw_set_color(c_white);
draw_text(_gw * 0.5, _gh * 0.24, "KICK_G");

if (menu_mode == "main") {
    var _start_y = _gh * 0.46;
    for (var _i = 0; _i < array_length(menu_items); _i++) {
        draw_set_color(_i == menu_index ? c_yellow : c_white);
        draw_text(_gw * 0.5, _start_y + _i * 44, menu_items[_i]);
    }
} else if (menu_mode == "stage") {
    draw_set_color(c_white);
    draw_text(_gw * 0.5, _gh * 0.16, "ETAPA A JUGAR");

    var _stage = stage_items[menu_index];
    var _preview = _stage.preview;
    var _box_w = min(_gw * 0.72, 760);
    var _box_h = min(_gh * 0.48, 420);
    var _box_x = (_gw - _box_w) * 0.5;
    var _box_y = _gh * 0.24;

    draw_set_color(make_color_rgb(18, 18, 22));
    draw_rectangle(_box_x - 4, _box_y - 4, _box_x + _box_w + 4, _box_y + _box_h + 4, false);

    var _scale = min(_box_w / sprite_get_width(_preview), _box_h / sprite_get_height(_preview));
    var _draw_w = sprite_get_width(_preview) * _scale;
    var _draw_h = sprite_get_height(_preview) * _scale;
    draw_sprite_ext(
        _preview, 0,
        _box_x + (_box_w - _draw_w) * 0.5,
        _box_y + (_box_h - _draw_h) * 0.5,
        _scale, _scale, 0, c_white, 1
    );

    var _stage_y = _box_y + _box_h + 48;
    for (var _s = 0; _s < array_length(stage_items); _s++) {
        draw_set_color(_s == menu_index ? c_yellow : c_white);
        draw_text(_gw * 0.5, _stage_y + _s * 44, stage_items[_s].label);
    }
} else {
    draw_set_color(c_white);
    draw_text(_gw * 0.5, _gh * 0.30, "CONFIGURAR CONTROL");

    var _slot = global.keybinds.gp_slot;
    var _connected = gamepad_is_connected(_slot);
    draw_set_color(_connected ? c_lime : c_red);
    draw_text(_gw * 0.5, _gh * 0.36, _connected ? "Controller conectado" : "Controller no conectado");

    var _start = _gh * 0.46;
    for (var _j = 0; _j < array_length(controller_actions); _j++) {
        var _action = controller_actions[_j];
        var _button = variable_struct_get(global.keybinds, _action.field);
        var _line = _action.label + ": " + scr_controller_button_name(_button);
        draw_set_color(_j == menu_index ? c_yellow : c_white);
        draw_text(_gw * 0.5, _start + _j * 36, _line);
    }

    if (remap_index >= 0) {
        draw_set_alpha(0.92);
        draw_set_color(c_black);
        draw_rectangle(_gw * 0.18, _gh * 0.42, _gw * 0.82, _gh * 0.58, false);
        draw_set_alpha(1);
        draw_set_color(c_yellow);
        draw_text(_gw * 0.5, _gh * 0.48, "Presiona un boton del controller");
        draw_set_color(c_white);
        draw_text(_gw * 0.5, _gh * 0.54, controller_actions[remap_index].label);
    }
}

draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_alpha(1);
