// OBJ_ENEMY_SPIDER
// Enemigo de emboscada: espera en su escondite, se lanza al player y vuelve.
event_inherited(); // obj_enemy_parent -> obj_actor_parent

SPIDER_HIDDEN = 0;
SPIDER_LUNGE  = 1;
SPIDER_RETURN = 2;
SPIDER_WAIT   = 3;

spider_state = SPIDER_HIDDEN;
home_x = x;
home_y = y;

// Hitbox fisica: baja y mas chica que el arte completo.
col_left   = -56;
col_right  = 56;
col_top    = -50;
col_bottom = -2;

max_hp = 3;
hp = max_hp;

contact_damage_enabled = true;
contact_damage = 1;
contact_damage_cooldown_max = 35;

can_patrol = false;
can_chase = false;
can_drop_down = false;

spider_detect_range_x = 420;
spider_detect_range_y = 190;
spider_lunge_speed = 7;
spider_return_speed = 3;
spider_attack_hold = 22;
spider_recover_wait = 34;
spider_home_tolerance = 8;
spider_target_x = x;
spider_target_y = y;
spider_timer = 0;

// Ajustable por Creation Code para cada instancia del room.
spider_debug_draw = false;

base_image_speed = 0.18;
enemy_separation_radius = 36;
enemy_separation_strength = 2.0;
blocks_other_enemies = true;
blocked_by_other_enemies = false;

parent_on_damage = on_damage;
on_damage = function(_amount, _source) {
    parent_on_damage(_amount, _source);
    spider_state = SPIDER_RETURN;
    spider_timer = 0;
};
