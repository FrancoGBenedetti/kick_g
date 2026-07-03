event_inherited();

BRIDGE_CLOSED = 0;
BRIDGE_OPENING = 1;
BRIDGE_OPEN = 2;

var _default = function(_name, _value) {
    if (!variable_instance_exists(id, _name)) {
        variable_instance_set(id, _name, _value);
    }
};

// x/y es el pivote donde el puente queda anclado.
_default("bridge_state", BRIDGE_CLOSED);
_default("bridge_side", 1);              // 1 abre hacia la derecha, -1 hacia la izquierda.
_default("bridge_sprite", spr_pivot_bridge);
_default("bridge_length", 288);
_default("bridge_thickness", 48);
_default("bridge_visual_yscale", 1);
_default("bridge_visual_yoff", 0);
_default("bridge_closed_angle", 58);     // grados visuales hacia arriba.
_default("bridge_open_angle", 0);
_default("bridge_angle", bridge_closed_angle);
_default("bridge_rotate_speed", 3.5);
_default("target_radius", 18);
_default("bridge_triggered", false);
_default("bridge_debug_draw", true);
_default("bridge_collision_padding", 24);

dynamic_solid_enabled = true;
dynamic_solid_xoff = 0;
dynamic_solid_yoff = -bridge_thickness * 0.5;
dynamic_solid_w = bridge_length * bridge_side;
dynamic_solid_h = bridge_thickness;

bridge_trigger = function() {
    if (bridge_state != BRIDGE_CLOSED) return;
    bridge_triggered = true;
    bridge_state = BRIDGE_OPENING;
};

bridge_update_target = function() {
    var _draw_angle = (bridge_side == 1) ? bridge_angle : 180 - bridge_angle;
    target_x = x + lengthdir_x(bridge_length, _draw_angle);
    target_y = y + lengthdir_y(bridge_length, _draw_angle);
};

bridge_update_solid = function() {
    dynamic_solid_xoff = (bridge_side == 1) ? 0 : -bridge_length;
    dynamic_solid_yoff = -bridge_thickness * 0.5;
    dynamic_solid_w = bridge_length;
    dynamic_solid_h = bridge_thickness;
};

dynamic_solid_contains_point = function(_px, _py) {
    var _angle = (bridge_side == 1) ? bridge_angle : 180 - bridge_angle;
    var _x1 = x;
    var _y1 = y;
    var _x2 = x + lengthdir_x(bridge_length, _angle);
    var _y2 = y + lengthdir_y(bridge_length, _angle);

    var _sx = _x2 - _x1;
    var _sy = _y2 - _y1;
    var _len_sq = _sx * _sx + _sy * _sy;
    if (_len_sq <= 0) return false;

    var _t = ((_px - _x1) * _sx + (_py - _y1) * _sy) / _len_sq;
    _t = clamp(_t, 0, 1);

    var _closest_x = _x1 + _sx * _t;
    var _closest_y = _y1 + _sy * _t;
    var _radius = bridge_thickness * 0.5 + bridge_collision_padding;

    return point_distance(_px, _py, _closest_x, _closest_y) <= _radius;
};

bridge_update_target();
bridge_update_solid();
