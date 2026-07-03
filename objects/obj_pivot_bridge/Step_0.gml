if (!global.do_step) exit;

if (bridge_state == BRIDGE_CLOSED) {
    var _arrow = collision_circle(target_x, target_y, target_radius, obj_player_arrow, false, true);
    if (instance_exists(_arrow)) {
        with (_arrow) instance_destroy();
        bridge_trigger();
    }
}

if (bridge_state == BRIDGE_OPENING) {
    bridge_angle = max(bridge_open_angle, bridge_angle - bridge_rotate_speed);
    if (bridge_angle <= bridge_open_angle) {
        bridge_angle = bridge_open_angle;
        bridge_state = BRIDGE_OPEN;
    }
}

bridge_update_target();
bridge_update_solid();
