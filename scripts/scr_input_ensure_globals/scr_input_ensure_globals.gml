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
            kb_beat_em_up: vk_down,
            kb_beat_heavy: ord("X"),
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
            gp_jump:       gp_face2,      // B / Círculo
            gp_dash:       gp_shoulderrb, // RT / R2
            gp_attack:     gp_face4,      // Y / Triángulo
            gp_ranged:     gp_shoulderr,  // RB / R1
            gp_block:      gp_shoulderl,  // LB / L1
            gp_beat_em_up: gp_padd,       // Cruceta abajo
            gp_beat_heavy: gp_face3,      // X / Cuadrado
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
        };
    }

    // Compatibilidad con sesiones que ya tenían globales creados antes de
    // agregar la acción Beat 'em Up; no pisa remaps existentes.
    if (!variable_struct_exists(global.keybinds, "kb_beat_em_up")) {
        global.keybinds.kb_beat_em_up = vk_down;
    }
    if (!variable_struct_exists(global.keybinds, "gp_beat_em_up")) {
        global.keybinds.gp_beat_em_up = gp_padd;
    }
    if (!variable_struct_exists(global.keybinds, "kb_beat_heavy")) {
        global.keybinds.kb_beat_heavy = ord("X");
    }
    if (!variable_struct_exists(global.keybinds, "gp_beat_heavy")) {
        global.keybinds.gp_beat_heavy = gp_face3;
    }
    if (!variable_struct_exists(global.inp, "beat_em_up_pressed")) {
        global.inp.beat_em_up_pressed = false;
    }
    if (!variable_struct_exists(global.inp, "beat_heavy_pressed")) {
        global.inp.beat_heavy_pressed = false;
    }

    if (!variable_global_exists("game_paused")) {
        global.game_paused = false;
    }

    if (!variable_global_exists("pause_prev_time_scale")) {
        global.pause_prev_time_scale = 1.0;
    }
}
