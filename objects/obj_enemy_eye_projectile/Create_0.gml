event_inherited();

damage_type = "enemy_eye_projectile";
target_object = obj_player;
team = TEAM_ENEMY;
hit_radius = 10;
uses_ballistic_trajectory = false;
lifetime_max = 180;
lifetimeTimer = lifetime_max;
can_be_destroyed_by_sword = false;
can_be_parried = true;
can_be_blocked = true;
parry_result = PARRY_REFLECT;
parry_reflect_min_speed = 8;
parry_damage_multiplier = 1;

parent_on_parried = on_parried;
on_parried = function(_player) {
    var _result = parent_on_parried(_player);

    // El reflect de este proyectil siempre vuelve a su ojo emisor, sin poder
    // golpear a otros enemigos en el trayecto.
    if (_result == HIT_RESULT_PARRIED_REFLECT
    && instance_exists(original_owner)
    && original_owner.object_index == obj_enemy_eye) {
        var _speed = point_distance(0, 0, vel_x, vel_y);
        var _target_y = original_owner.y + original_owner.projectile_target_yoff;
        var _direction = point_direction(x, y, original_owner.x, _target_y);
        vel_x = lengthdir_x(_speed, _direction);
        vel_y = lengthdir_y(_speed, _direction);
        target_object = obj_enemy_eye;
        target_before_tile_collision = true;
        ignore_tile_collision = true;
    }

    return _result;
};
