scr_input_ensure_globals();

menu_index = 0;
menu_mode = "main";
remap_index = -1;

menu_items = [
    "Resumir",
    "Configurar controller",
];

controller_actions = [
    { label: "Saltar",       field: "gp_jump"   },
    { label: "Dash",         field: "gp_dash"   },
    { label: "Espada",       field: "gp_attack" },
    { label: "Arco",         field: "gp_ranged" },
    { label: "Block / Parry", field: "gp_block" },
    { label: "Pausa",        field: "gp_pause"  },
];

menu_up_pressed = function() {
    var _slot = global.keybinds.gp_slot;
    return keyboard_check_pressed(vk_up)
        || keyboard_check_pressed(ord("W"))
        || (gamepad_is_connected(_slot) && gamepad_button_check_pressed(_slot, gp_padu));
};

menu_down_pressed = function() {
    var _slot = global.keybinds.gp_slot;
    return keyboard_check_pressed(vk_down)
        || keyboard_check_pressed(ord("S"))
        || (gamepad_is_connected(_slot) && gamepad_button_check_pressed(_slot, gp_padd));
};

menu_accept_pressed = function() {
    var _slot = global.keybinds.gp_slot;
    return keyboard_check_pressed(vk_enter)
        || keyboard_check_pressed(vk_space)
        || keyboard_check_pressed(ord("Z"))
        || (gamepad_is_connected(_slot) && gamepad_button_check_pressed(_slot, global.keybinds.gp_jump));
};

menu_back_pressed = function() {
    var _slot = global.keybinds.gp_slot;
    return keyboard_check_pressed(vk_escape)
        || keyboard_check_pressed(ord("X"))
        || (gamepad_is_connected(_slot) && gamepad_button_check_pressed(_slot, global.keybinds.gp_pause));
};
