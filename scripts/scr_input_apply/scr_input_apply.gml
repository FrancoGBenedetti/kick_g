// Une teclado + gamepad en el contrato global.inp que consume gameplay.
function scr_input_apply(_inp, _keyboard, _gamepad) {
    _inp.move_axis       = clamp(_keyboard.move_axis + _gamepad.move_axis, -1, 1);

    _inp.jump_pressed    = _keyboard.jump_pressed    || _gamepad.jump_pressed;
    _inp.jump_held       = _keyboard.jump_held       || _gamepad.jump_held;
    _inp.dash_pressed    = _keyboard.dash_pressed    || _gamepad.dash_pressed;

    _inp.attack_pressed  = _keyboard.attack_pressed  || _gamepad.attack_pressed;
    _inp.attack_held     = _keyboard.attack_held     || _gamepad.attack_held;

    _inp.ranged_pressed  = _keyboard.ranged_pressed  || _gamepad.ranged_pressed;
    _inp.ranged_held     = _keyboard.ranged_held     || _gamepad.ranged_held;
    _inp.ranged_released = (_keyboard.ranged_released && !_gamepad.ranged_held)
                         || (_gamepad.ranged_released  && !_keyboard.ranged_held);

    _inp.aim_up_held     = _keyboard.aim_up_held     || _gamepad.aim_up_held;
    _inp.aim_down_held   = _keyboard.aim_down_held   || _gamepad.aim_down_held;

    _inp.left_pressed    = _keyboard.left_pressed    || _gamepad.left_pressed;
    _inp.right_pressed   = _keyboard.right_pressed   || _gamepad.right_pressed;
    _inp.up_pressed      = _keyboard.up_pressed      || _gamepad.up_pressed;
    _inp.down_pressed    = _keyboard.down_pressed    || _gamepad.down_pressed;

    _inp.block_pressed   = _keyboard.block_pressed   || _gamepad.block_pressed;
    _inp.block_held      = _keyboard.block_held      || _gamepad.block_held;

    _inp.pause_pressed   = _keyboard.pause_pressed   || _gamepad.pause_pressed;
}
