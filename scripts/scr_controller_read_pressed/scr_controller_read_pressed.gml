// Retorna el primer boton de controller presionado este frame, o noone.
function scr_controller_read_pressed(_slot) {
    if (!gamepad_is_connected(_slot)) {
        return noone;
    }

    var _buttons = [
        gp_face1, gp_face2, gp_face3, gp_face4,
        gp_shoulderl, gp_shoulderr,
        gp_start, gp_select,
        gp_padu, gp_padd, gp_padl, gp_padr,
    ];

    for (var _i = 0; _i < array_length(_buttons); _i++) {
        var _button = _buttons[_i];
        if (gamepad_button_check_pressed(_slot, _button)) {
            return _button;
        }
    }

    return noone;
}
