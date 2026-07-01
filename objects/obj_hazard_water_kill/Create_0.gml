// Preset de agua letal. El visual del agua debe ir en Tile Layer.
if (!variable_instance_exists(id, "hazard_w")) hazard_w = 512;
if (!variable_instance_exists(id, "hazard_h")) hazard_h = 96;
if (!variable_instance_exists(id, "hazard_kill_player")) hazard_kill_player = true;
if (!variable_instance_exists(id, "hazard_debug_draw")) hazard_debug_draw = true;
if (!variable_instance_exists(id, "hazard_debug_color")) hazard_debug_color = c_aqua;

event_inherited();
