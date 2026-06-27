if (!variable_instance_exists(id, "cover_sprite")) cover_sprite = spr_trap_wall_panel;
if (!variable_instance_exists(id, "broken_sprite")) broken_sprite = spr_trap_wall_panel_broken;

if (!variable_instance_exists(id, "trigger_mode")) trigger_mode = 1; // TRAP_TRIGGER_RECT, definido por obj_trap_parent.
if (!variable_instance_exists(id, "trigger_xoff")) trigger_xoff = -96;
if (!variable_instance_exists(id, "trigger_yoff")) trigger_yoff = -96;
if (!variable_instance_exists(id, "trigger_w")) trigger_w = 420;
if (!variable_instance_exists(id, "trigger_h")) trigger_h = 320;

if (!variable_instance_exists(id, "payload_spawn_enemy")) payload_spawn_enemy = true;
if (!variable_instance_exists(id, "enemy_object")) enemy_object = obj_test_fly_bat;
if (!variable_instance_exists(id, "enemy_spawn_xoff")) enemy_spawn_xoff = 128;
if (!variable_instance_exists(id, "enemy_spawn_yoff")) enemy_spawn_yoff = 96;

if (!variable_instance_exists(id, "payload_damage")) payload_damage = false;

event_inherited();
