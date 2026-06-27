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
            if (break_sound != noone) audio_play_sound(break_sound, 1, false);
            trap_state = TRAP_STATE_ACTIVE;
            trap_timer = active_time;
            trap_has_fired_payload = false;
            trap_has_damaged = false;
            trap_fire_payload();
        }
    break;

    case TRAP_STATE_ACTIVE:
        trap_apply_damage();
        trap_timer--;
        if (trap_timer <= 0) {
            trap_state = TRAP_STATE_RECOVERY;
            trap_timer = recovery_time;
        }
    break;

    case TRAP_STATE_RECOVERY:
        trap_timer--;
        if (trap_timer <= 0) {
            trap_state = one_shot ? TRAP_STATE_DONE : TRAP_STATE_ARMED;
        }
    break;
}
