// Singleton: obj_input es persistent, evitar duplicados al cambiar/reiniciar rooms.
if (instance_number(obj_input) > 1) {
    instance_destroy();
    exit;
}

scr_input_ensure_globals();

// Estado previo de ejes digitales/analógicos para detectar presses one-shot.
gp_prev_move_axis = 0;
gp_prev_aim_axis  = 0;

if (!instance_exists(obj_pause_menu)) {
    instance_create_depth(0, 0, -100000, obj_pause_menu);
}
