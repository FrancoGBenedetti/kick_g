// Inicializa contratos globales de input sin pisar remaps existentes.
function scr_input_ensure_globals() {
    if (!variable_global_exists("keybinds")) {
        global.keybinds = {
            // Teclado
            kb_move_left:  vk_left,
            kb_move_right: vk_right,
            kb_jump:       vk_space,
            kb_dash:       vk_shift,
            kb_attack:     ord("Z"),
            kb_ranged:     ord("X"),
            kb_aim_up:     vk_up,
            kb_aim_down:   vk_down,
            kb_block:      ord("C"),
            kb_pause:      vk_escape,

            // Gamepad
            gp_slot:       0,
            gp_move_axis:  gp_axislh,
            gp_move_left:  gp_padl,
            gp_move_right: gp_padr,
            gp_aim_axis:   gp_axisrv,
            gp_aim_up:     gp_padu,
            gp_aim_down:   gp_padd,
            gp_jump:       gp_face1,
            gp_dash:       gp_face3,
            gp_attack:     gp_face2,
            gp_ranged:     gp_shoulderr,
            gp_block:      gp_shoulderl,
            gp_pause:      gp_start,

            gp_deadzone:   0.25,
        };
    }

    if (!variable_global_exists("inp")) {
        global.inp = {
            move_axis:       0,

            jump_pressed:    false,
            jump_held:       false,
            dash_pressed:    false,

            attack_pressed:  false,
            attack_held:     false,

            ranged_pressed:  false,
            ranged_held:     false,
            ranged_released: false,

            aim_up_held:     false,
            aim_down_held:   false,

            left_pressed:    false,
            right_pressed:   false,
            up_pressed:      false,
            down_pressed:    false,

            block_pressed:   false,
            block_held:      false,

            pause_pressed:   false,
        };
    }

    if (!variable_global_exists("game_paused")) {
        global.game_paused = false;
    }

    if (!variable_global_exists("pause_prev_time_scale")) {
        global.pause_prev_time_scale = 1.0;
    }
}
