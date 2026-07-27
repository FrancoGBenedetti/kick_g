spawner_id = "spawner_camera_center_test_01";
encounter_id = "camera_center_test_01";       // debe matchear encounter_id de arriba
listen_signal_id = "";

enemy_object = obj_enemy_swordsman;
// Los actores se dibujan en la capa foreground. El puente visual vive
// en `Instances` (depth 100) y debe quedar detrás del combate.
spawn_layer = "Instances_1";

spawn_once = true;
spawn_delay = 0;
spawn_count = 1;
spawn_interval = 15;

debug_enabled = true;
