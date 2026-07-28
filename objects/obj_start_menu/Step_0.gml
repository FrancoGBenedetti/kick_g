if (remap_index >= 0) {
    var _button = scr_controller_read_pressed(global.keybinds.gp_slot);
    if (_button != noone) {
        var _field = controller_actions[remap_index].field;
        variable_struct_set(global.keybinds, _field, _button);
        remap_index = -1;
    } else if (keyboard_check_pressed(vk_escape)) {
        remap_index = -1;
    }
    exit;
}

var _count = array_length(menu_items);
if (menu_mode == "stage") {
    _count = array_length(stage_items);
} else if (menu_mode == "config") {
    _count = array_length(controller_actions);
}

var _slot = global.keybinds.gp_slot;
var _menu_raw = gamepad_is_connected(_slot)
    ? gamepad_axis_value(_slot, gp_axislv)
    : 0;
var _menu_axis = abs(_menu_raw) > global.keybinds.gp_deadzone ? sign(_menu_raw) : 0;
var _stick_up_pressed = _menu_axis < 0 && menu_prev_axis >= 0;
var _stick_down_pressed = _menu_axis > 0 && menu_prev_axis <= 0;
menu_prev_axis = _menu_axis;

if (menu_up_pressed() || _stick_up_pressed) {
    menu_index = (menu_index + _count - 1) mod _count;
}

if (menu_down_pressed() || _stick_down_pressed) {
    menu_index = (menu_index + 1) mod _count;
}

if (menu_back_pressed() && menu_mode != "main") {
    menu_mode = "main";
    menu_index = 0;
    exit;
}

if (menu_accept_pressed()) {
    if (menu_mode == "main") {
        switch (menu_index) {
            case 0:
                menu_mode = "stage";
                menu_index = 0;
            break;
            case 1:
                menu_mode = "config";
                menu_index = 0;
            break;
        }
    } else if (menu_mode == "stage") {
        var _stage = stage_items[menu_index];
        global.game_paused = false;
        room_goto(_stage.room_id);
    } else {
        remap_index = menu_index;
    }
}
