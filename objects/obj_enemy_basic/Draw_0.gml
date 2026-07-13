// Draw — dibuja el sprite normal (default draw ya lo hacía; ahora que hay
// Draw event propio hay que llamarlo a mano) + overlay opcional de debug
// de BattleRoom (F1 → global.debug_battleroom). Solo se muestra si este
// enemigo fue creado por obj_enemy_spawner (tiene battleroom_owner).
draw_self();

if (!(variable_global_exists("debug_battleroom") && global.debug_battleroom)) exit;
if (!variable_instance_exists(id, "battleroom_owner")) exit;

var _dc = draw_get_color();
var _da = draw_get_alpha();

draw_set_alpha(1);
draw_set_halign(fa_center);
draw_set_valign(fa_bottom);
draw_set_color(c_aqua);

var _owner_txt   = instance_exists(battleroom_owner) ? object_get_name(battleroom_owner.object_index) : "none";
var _spawner_txt = (variable_instance_exists(id, "spawned_by_spawner") && instance_exists(spawned_by_spawner))
    ? spawned_by_spawner.spawner_id : "none";

draw_text(x, y - 90, "[BR] owner:" + _owner_txt + "  id:" + string(battleroom_id));
draw_text(x, y - 76, "spawner:" + _spawner_txt
    + "  reg:" + string(battleroom_enemy_registered)
    + "  died:" + string(battleroom_death_notified));

draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(_dc);
draw_set_alpha(_da);
