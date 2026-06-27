/// obj_trap_parent
/// Base reusable para trampas: trigger -> delay -> active -> payload -> recovery.

TRAP_TRIGGER_DISTANCE = 0;
TRAP_TRIGGER_RECT     = 1;

TRAP_STATE_ARMED     = 0;
TRAP_STATE_TRIGGERED = 1;
TRAP_STATE_ACTIVE    = 2;
TRAP_STATE_RECOVERY  = 3;
TRAP_STATE_DONE      = 4;

var _default = function(_name, _value) {
    if (!variable_instance_exists(id, _name)) {
        variable_instance_set(id, _name, _value);
    }
};

_default("trigger_mode", TRAP_TRIGGER_DISTANCE);
_default("trigger_range", 320);
_default("trigger_xoff", -160);
_default("trigger_yoff", -160);
_default("trigger_w", 320);
_default("trigger_h", 320);

_default("activate_delay", 20);
_default("active_time", 12);
_default("recovery_time", 30);
_default("one_shot", true);
_default("trap_debug_draw", false);
_default("trap_force_trigger", false);

_default("cover_sprite", noone);
_default("broken_sprite", noone);
_default("broken_xoff", 0);
_default("broken_yoff", 0);
_default("trap_visual_xscale", 1);
_default("trap_visual_yscale", 1);
_default("break_sound", noone);

_default("payload_spawn_enemy", false);
_default("enemy_object", noone);
_default("enemy_spawn_xoff", 0);
_default("enemy_spawn_yoff", 0);
_default("enemy_spawn_layer", "Instances_1");
_default("enemy_face_player", true);

_default("payload_damage", false);
_default("damage", 1);
_default("hitbox_xoff", -64);
_default("hitbox_yoff", -64);
_default("hitbox_w", 128);
_default("hitbox_h", 128);

trap_state = TRAP_STATE_ARMED;
trap_timer = 0;
trap_has_fired_payload = false;
trap_has_damaged = false;

trap_check_trigger = function() {
    if (trap_force_trigger) return true;
    if (!instance_exists(obj_player)) return false;

    if (trigger_mode == TRAP_TRIGGER_RECT) {
        var _x1 = x + trigger_xoff;
        var _y1 = y + trigger_yoff;
        return collision_rectangle(_x1, _y1, _x1 + trigger_w, _y1 + trigger_h, obj_player, false, true) != noone;
    }

    return point_distance(x, y, obj_player.x, obj_player.y) <= trigger_range;
};

trap_spawn_enemy = function() {
    if (!payload_spawn_enemy || enemy_object == noone) return noone;

    var _enemy = instance_create_layer(
        x + enemy_spawn_xoff,
        y + enemy_spawn_yoff,
        enemy_spawn_layer,
        enemy_object
    );

    if (enemy_face_player && instance_exists(obj_player)) {
        var _dir = sign(obj_player.x - _enemy.x);
        if (_dir == 0) _dir = 1;
        if (variable_instance_exists(_enemy, "facing")) _enemy.facing = _dir;
        if (variable_instance_exists(_enemy, "patrol_dir")) _enemy.patrol_dir = _dir;
        if (variable_instance_exists(_enemy, "fly_dir")) _enemy.fly_dir = _dir;
    }

    return _enemy;
};

trap_apply_damage = function() {
    if (!payload_damage || trap_has_damaged || !instance_exists(obj_player)) return;

    var _x1 = x + hitbox_xoff;
    var _y1 = y + hitbox_yoff;
    var _hit = collision_rectangle(_x1, _y1, _x1 + hitbox_w, _y1 + hitbox_h, obj_player, false, true);

    if (_hit != noone) {
        obj_player.take_damage(damage, id);
        trap_has_damaged = true;
    }
};

trap_fire_payload = function() {
    if (trap_has_fired_payload) return;
    trap_spawn_enemy();
    trap_apply_damage();
    trap_has_fired_payload = true;
};
