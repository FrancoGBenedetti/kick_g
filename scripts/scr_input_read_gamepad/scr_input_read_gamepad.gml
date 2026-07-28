// Lee gamepad y devuelve el estado de input del frame actual.
function scr_input_read_gamepad(_kb, _prev_move_axis, _prev_aim_axis) {
    var _out = {
        move_axis:       0,

        jump_pressed:    false,
        jump_held:       false,
        dash_pressed:    false,

        attack_pressed:  false,
        attack_held:     false,

        ranged_pressed:  false,
        ranged_held:     false,
        ranged_released: false,

        beat_em_up_pressed: false,
        beat_heavy_pressed: false,

        aim_up_held:     false,
        aim_down_held:   false,

        left_pressed:    false,
        right_pressed:   false,
        up_pressed:      false,
        down_pressed:    false,

        block_pressed:   false,
        block_held:      false,

        pause_pressed:   false,

        next_move_axis:  0,
        next_aim_axis:   0,
    };

    var _slot = _kb.gp_slot;
    if (!gamepad_is_connected(_slot)) {
        return _out;
    }

    var _move_raw   = gamepad_axis_value(_slot, _kb.gp_move_axis);
    var _move_stick = (abs(_move_raw) > _kb.gp_deadzone) ? sign(_move_raw) : 0;
    var _move_axis  = _move_stick;

    var _aim_raw    = gamepad_axis_value(_slot, _kb.gp_aim_axis);
    var _aim_stick  = (abs(_aim_raw) > _kb.gp_deadzone) ? sign(_aim_raw) : 0;
    var _aim_axis   = _aim_stick;

    _out.move_axis       = _move_axis;
    _out.next_move_axis  = _move_axis;
    _out.next_aim_axis   = _aim_axis;

    _out.jump_pressed    = gamepad_button_check_pressed(_slot, _kb.gp_jump);
    _out.jump_held       = gamepad_button_check(_slot, _kb.gp_jump);
    _out.dash_pressed    = gamepad_button_check_pressed(_slot, _kb.gp_dash);

    _out.attack_pressed  = gamepad_button_check_pressed(_slot, _kb.gp_attack);
    _out.attack_held     = gamepad_button_check(_slot, _kb.gp_attack);

    _out.ranged_pressed  = gamepad_button_check_pressed(_slot, _kb.gp_ranged);
    _out.ranged_held     = gamepad_button_check(_slot, _kb.gp_ranged);
    _out.ranged_released = gamepad_button_check_released(_slot, _kb.gp_ranged);

    _out.beat_em_up_pressed = gamepad_button_check_pressed(_slot, _kb.gp_beat_em_up);
    _out.beat_heavy_pressed = gamepad_button_check_pressed(_slot, _kb.gp_beat_heavy);

    _out.aim_up_held     = (_aim_axis < 0);
    _out.aim_down_held   = (_aim_axis > 0);

    _out.left_pressed    = (_move_axis < 0 && _prev_move_axis >= 0);
    _out.right_pressed   = (_move_axis > 0 && _prev_move_axis <= 0);
    _out.up_pressed      = (_aim_axis < 0 && _prev_aim_axis >= 0);
    _out.down_pressed    = (_aim_axis > 0 && _prev_aim_axis <= 0);

    _out.block_pressed   = gamepad_button_check_pressed(_slot, _kb.gp_block);
    _out.block_held      = gamepad_button_check(_slot, _kb.gp_block);

    _out.pause_pressed   = gamepad_button_check_pressed(_slot, _kb.gp_pause);

    return _out;
}
