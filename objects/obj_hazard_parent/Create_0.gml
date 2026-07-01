// OBJ_HAZARD_PARENT
// Zona reusable: agua, lava, void, pinchos u otros peligros del room.

var _default = function(_name, _value) {
    if (!variable_instance_exists(id, _name)) {
        variable_instance_set(id, _name, _value);
    }
};

_default("hazard_enabled", true);
_default("hazard_w", 256);
_default("hazard_h", 64);
_default("hazard_xoff", 0);
_default("hazard_yoff", 0);
_default("hazard_kill_player", true);
_default("hazard_damage", 999);
_default("hazard_debug_draw", true);
_default("hazard_debug_color", c_aqua);

hazard_apply_to_player = function(_player) {
    if (!instance_exists(_player)) return;

    if (hazard_kill_player) {
        with (_player) {
            hp = 0;
            die();
        }
    } else {
        _player.take_damage(hazard_damage, id);
    }
};
