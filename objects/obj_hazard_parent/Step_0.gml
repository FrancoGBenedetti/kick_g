if (!global.do_step || !hazard_enabled) exit;

var _x1 = x + hazard_xoff;
var _y1 = y + hazard_yoff;
var _player = collision_rectangle(
    _x1,
    _y1,
    _x1 + hazard_w,
    _y1 + hazard_h,
    obj_player,
    false,
    true
);

if (_player != noone) {
    hazard_apply_to_player(_player);
}
