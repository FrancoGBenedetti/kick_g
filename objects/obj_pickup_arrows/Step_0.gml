if (!global.do_step || !instance_exists(obj_player)) exit;

var _player = instance_find(obj_player, 0);
var _x1 = x - pickup_half_w;
var _x2 = x + pickup_half_w;
var _y1 = y - pickup_h;

if (_player.bbox_right <= _x1 || _player.bbox_left >= _x2
||  _player.bbox_bottom <= _y1 || _player.bbox_top >= y) {
    exit;
}

player_add_arrows(_player, arrow_amount);
show_debug_message("[PICKUP] +" + string(arrow_amount) + " flechas");
instance_destroy();
