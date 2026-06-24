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
} else {
    draw_set_color(c_white);
    draw_text(_gw * 0.5, _gh * 0.30, "CONFIGURAR CONTROLLER");

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
