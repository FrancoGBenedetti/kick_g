event_inherited();

EYE_STATE_IDLE = 0;
EYE_STATE_ATTACK = 1;
EYE_STATE_CLOSED = 2;
EYE_STATE_DAMAGE = 3;
EYE_STATE_DEAD = 4;

eye_state = EYE_STATE_IDLE;
eye_timer = 0;
eye_direction = -1;
eye_visual_scale = 0.25;

attack_range = 640;
attack_cooldown = 75;
attack_cooldown_timer = 0;
attack_windup = 24;
projectile_speed = 16;
projectile_damage = 1;
projectile_spawn_distance = 72;
projectile_spawn_yoff = -70;
projectile_target_yoff = -70;
projectile_layer = "Instances";

arrow_close_duration = 25;
damage_duration = 15;
death_duration = 15;
blink_interval_min = 90;
blink_interval_max = 180;
blink_duration = 8;
blink_timer = irandom_range(blink_interval_min, blink_interval_max);
eye_max_hp = 1;
eye_hp = eye_max_hp;
eye_config_applied = false;
max_hp = eye_max_hp;
hp = eye_hp;

grav = 0;
max_fall = 0;
move_x = 0;
move_y = 0;
can_patrol = false;
can_chase = false;
can_drop_down = false;
contact_damage_enabled = false;
enemy_separation_enabled = false;
blocks_other_enemies = false;
blocked_by_other_enemies = false;
show_world_healthbar = false;
base_image_speed = 0;
image_speed = 0;
// El PNG base mira a la izquierda; invertir eye_direction solo para el arte.
image_xscale = -eye_visual_scale * eye_direction;
image_yscale = eye_visual_scale;

// El ojo es fijo: esta caja representa su zona de impacto, no su arte completo.
// Creation Code puede cambiar eye_direction, eye_max_hp y los timings.
col_left = -45;
col_right = 45;
col_top = -130;
col_bottom = -10;

take_damage = function(_amount, _source) {
    if (eye_state == EYE_STATE_DEAD) return HIT_RESULT_NONE;

    var _owner_is_player = instance_exists(_source)
        && instance_exists(_source.owner)
        && _source.owner.object_index == obj_player;

    var _is_own_reflect = instance_exists(_source)
        && _source.object_index == obj_enemy_eye_projectile
        && _source.was_parried
        && _source.team == TEAM_PLAYER
        && _owner_is_player
        && _source.original_owner == id;

    if (_is_own_reflect) {
        eye_hp = max(eye_hp - _amount, 0);
        hp = eye_hp;
        eye_state = EYE_STATE_DAMAGE;
        eye_timer = (eye_hp <= 0) ? death_duration : damage_duration;
        sprite_index = spr_enemy_eye_damage;
        return HIT_RESULT_DAMAGE;
    }

    // La flecha directa sí impacta y se destruye, pero enseña que no hace daño.
    if (instance_exists(_source) && _source.object_index == obj_player_arrow) {
        eye_state = EYE_STATE_CLOSED;
        eye_timer = arrow_close_duration;
        sprite_index = spr_enemy_eye_closed;
    }

    return HIT_RESULT_DAMAGE;
};
