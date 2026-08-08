if (!global.do_step) exit;

move_x = 0;
move_y = 0;

// Creation Code corre después de Create; sincronizar su override de HP una sola vez.
if (!eye_config_applied) {
    eye_hp = eye_max_hp;
    hp = eye_hp;
    max_hp = eye_max_hp;
    eye_config_applied = true;
}

if (attack_cooldown_timer > 0) attack_cooldown_timer--;

switch (eye_state) {
    case EYE_STATE_IDLE:
        sprite_index = spr_enemy_eye_open;
        if (--blink_timer <= 0) {
            eye_state = EYE_STATE_CLOSED;
            eye_timer = blink_duration;
            sprite_index = spr_enemy_eye_closed;
        } else if (instance_exists(obj_player)
        && point_distance(x, y, obj_player.x, obj_player.y) <= attack_range
        && attack_cooldown_timer <= 0) {
            eye_state = EYE_STATE_ATTACK;
            eye_timer = attack_windup;
        }
    break;

    case EYE_STATE_ATTACK:
        if (--eye_timer <= 0) {
            var _origin_x = x;
            var _origin_y = y + projectile_spawn_yoff;
            var _target_y = instance_exists(obj_player)
                ? obj_player.bbox_top + (obj_player.bbox_bottom - obj_player.bbox_top) * 0.45
                : _origin_y;
            var _direction = instance_exists(obj_player)
                ? point_direction(_origin_x, _origin_y, obj_player.x, _target_y)
                : (eye_direction == 1 ? 0 : 180);
            var _spawn_x = _origin_x + lengthdir_x(projectile_spawn_distance, _direction);
            var _spawn_y = _origin_y + lengthdir_y(projectile_spawn_distance, _direction);
            var _layer_name = layer_get_id(projectile_layer) != -1 ? projectile_layer : layer_get_name(layer);
            var _projectile = instance_create_layer(_spawn_x, _spawn_y, _layer_name, obj_enemy_eye_projectile);

            with (_projectile) {
                owner = other.id;
                original_owner = other.id;
                damage = other.projectile_damage;
                vel_x = lengthdir_x(other.projectile_speed, _direction);
                vel_y = lengthdir_y(other.projectile_speed, _direction);
            }

            attack_cooldown_timer = attack_cooldown;
            eye_state = EYE_STATE_IDLE;
        }
    break;

    case EYE_STATE_CLOSED:
        if (--eye_timer <= 0) {
            eye_state = EYE_STATE_IDLE;
            blink_timer = irandom_range(blink_interval_min, blink_interval_max);
        }
    break;

    case EYE_STATE_DAMAGE:
        if (--eye_timer <= 0) {
            if (eye_hp <= 0) {
                eye_state = EYE_STATE_DEAD;
                instance_destroy();
                exit;
            } else {
                eye_state = EYE_STATE_IDLE;
            }
        }
    break;
}

event_inherited();

// obj_actor_parent restaura image_xscale a facing durante su Step.
// Aplicar la escala después conserva la proporción del arte importado.
image_xscale = -eye_visual_scale * eye_direction;
image_yscale = eye_visual_scale;
