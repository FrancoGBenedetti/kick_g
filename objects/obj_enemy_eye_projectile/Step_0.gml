// Tras un parry perfecto, mantener el retorno fijado al ojo que lo disparó.
if (was_parried
&& instance_exists(original_owner)
&& original_owner.object_index == obj_enemy_eye) {
    var _speed = point_distance(0, 0, vel_x, vel_y);
    var _target_y = original_owner.y + original_owner.projectile_target_yoff;
    var _direction = point_direction(x, y, original_owner.x, _target_y);
    vel_x = lengthdir_x(_speed, _direction);
    vel_y = lengthdir_y(_speed, _direction);
}

event_inherited();
