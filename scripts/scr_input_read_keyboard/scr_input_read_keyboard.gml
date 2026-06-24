// Lee teclado y devuelve el estado de input del frame actual.
function scr_input_read_keyboard(_kb) {
    return {
        move_axis:       keyboard_check(_kb.kb_move_right) - keyboard_check(_kb.kb_move_left),

        jump_pressed:    keyboard_check_pressed(_kb.kb_jump),
        jump_held:       keyboard_check(_kb.kb_jump),
        dash_pressed:    keyboard_check_pressed(_kb.kb_dash),

        attack_pressed:  keyboard_check_pressed(_kb.kb_attack),
        attack_held:     keyboard_check(_kb.kb_attack),

        ranged_pressed:  keyboard_check_pressed(_kb.kb_ranged),
        ranged_held:     keyboard_check(_kb.kb_ranged),
        ranged_released: keyboard_check_released(_kb.kb_ranged),

        aim_up_held:     keyboard_check(_kb.kb_aim_up),
        aim_down_held:   keyboard_check(_kb.kb_aim_down),

        left_pressed:    keyboard_check_pressed(_kb.kb_move_left),
        right_pressed:   keyboard_check_pressed(_kb.kb_move_right),
        up_pressed:      keyboard_check_pressed(_kb.kb_aim_up),
        down_pressed:    keyboard_check_pressed(_kb.kb_aim_down),

        block_pressed:   keyboard_check_pressed(_kb.kb_block),
        block_held:      keyboard_check(_kb.kb_block),

        pause_pressed:   keyboard_check_pressed(_kb.kb_pause),
    };
}
