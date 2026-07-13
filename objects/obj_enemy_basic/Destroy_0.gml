// Destroy — red de seguridad. En el camino normal, die() ya deja
// spawner_death_reported/battleroom_death_notified en true ANTES de llamar
// instance_destroy(), así que estos bloques no hacen nada (ya reportado).
// Pero si algo destruye al enemigo directamente (instance_destroy() desde
// otro lado, sin pasar por die()), esto asegura que igual se avise al
// spawner/BattleRoom — sin duplicar, y sin romper enemigos que no
// pertenecen a ninguno de los dos. Ver obj_enemy_parent/Destroy_0.gml
// (obj_enemy_basic no hereda de obj_enemy_parent, así que necesita su
// propia copia).

if (variable_instance_exists(id, "spawner_owner")
&& !spawner_death_reported
&& instance_exists(spawner_owner)) {
    spawner_death_reported = true;
    spawner_owner.spawner_on_enemy_died(id);
}

if (variable_instance_exists(id, "battleroom_owner")
&& !battleroom_death_notified
&& instance_exists(battleroom_owner)) {
    battleroom_death_notified = true;
    battleroom_owner.battleroom_on_enemy_died(id);
}
