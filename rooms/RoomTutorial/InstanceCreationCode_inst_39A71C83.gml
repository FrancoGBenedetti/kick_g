spawner_id = "spawner_bt_archer_castle_demo";
encounter_id = "bt_archer_castle_demo";       // debe matchear encounter_id de arriba
listen_signal_id = "";

enemy_object = obj_enemy_archer;
// Los actores se dibujan en la capa foreground. El puente visual vive
// en `Instances` (depth 100) y debe quedar detrás del combate.
spawn_layer = "bt_archer";

spawn_once = true;
spawn_delay = 0;
spawn_count = 1;
spawn_interval = 15;

debug_enabled = true;
