// Draw — invisible en gameplay normal. Se dibuja solo si el debug de
// colisión del proyecto (Y → global.debug_collision_view) o el debug de
// BattleRoom (F1 → global.debug_battleroom) están activos, para no atarlo
// a una sola tecla que el usuario pueda no recordar.
if (!debug_visible) exit;

var _view_debug       = variable_global_exists("debug_collision_view") && global.debug_collision_view;
var _battleroom_debug = variable_global_exists("debug_battleroom") && global.debug_battleroom;

if (!_view_debug && !_battleroom_debug) exit;

draw_set_alpha(0.35);
draw_set_color(c_red);
draw_rectangle(x, y, x + wall_width, y + wall_height, false);

draw_set_alpha(1);
draw_set_color(c_red);
draw_rectangle(x, y, x + wall_width, y + wall_height, true);

var _owner_name = instance_exists(owner_battleroom) ? object_get_name(owner_battleroom.object_index) : "none";

draw_set_color(c_white);
draw_text(x, y - 30, "BATTLEROOM WALL " + wall_id);
draw_text(x, y - 16, "owner: " + _owner_name + "  " + string(wall_width) + "x" + string(wall_height));
