if (!global.do_step || instance_exists(active_pack) || !instance_exists(obj_player)) exit;

var _player = instance_find(obj_player, 0);
if (_player.arrows > 0) exit;

// No leer y ni bbox: solo importa la distancia horizontal al spawner.
if (abs(_player.x - x) > trigger_range) exit;

var _pack = instance_create_layer(x + spawn_xoff, y + spawn_yoff,
                                  spawn_layer, obj_pickup_arrows);
if (!instance_exists(_pack)) exit;

_pack.arrow_amount = arrow_amount;
active_pack = _pack;
