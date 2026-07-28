if (!global.do_step) exit;

switch (trap_state) {
    case TRAP_STATE_ARMED:
        if (trap_check_trigger()) {
            trap_state = TRAP_STATE_TRIGGERED;
            trap_timer = activate_delay;
            trap_force_trigger = false;
        }
    break;

    case TRAP_STATE_TRIGGERED:
        trap_timer--;
        if (trap_timer <= 0) {
            trap_state = TRAP_STATE_ACTIVE;
        }
    break;

    case TRAP_STATE_ACTIVE:
        var _landing_y = drop_floor_y - drop_ground_clearance;
        var _stop_y = _landing_y - drop_visual_yoff;
        y = min(y + drop_speed, _stop_y);
        drop_kill_player();

        if (y >= _stop_y) {
            trap_state = TRAP_STATE_DONE;
        }
    break;
}
