if (!global.do_step) exit;

move_x = 0;

if (hitstun_timer <= 0) {
    switch (spider_state) {
        case SPIDER_HIDDEN:
            sprite_index = spr_enemy_spider_standing;
            image_speed = 0;

            if (spider_timer > 0) {
                spider_timer--;
            } else if (instance_exists(obj_player)) {
                var _dx = obj_player.x - x;
                var _dy = obj_player.y - y;

                if (abs(_dx) <= spider_detect_range_x && abs(_dy) <= spider_detect_range_y) {
                    spider_target_x = obj_player.x;
                    spider_target_y = obj_player.y;
                    facing = sign(_dx);
                    if (facing == 0) facing = 1;
                    spider_state = SPIDER_LUNGE;
                }
            }
        break;

        case SPIDER_LUNGE:
            sprite_index = spr_enemy_spider_attack;
            image_speed = base_image_speed;

            var _dir = sign(spider_target_x - x);
            if (_dir == 0) _dir = facing;
            facing = _dir;
            move_x = _dir * spider_lunge_speed;

            if (abs(spider_target_x - x) <= spider_lunge_speed + 4 || wallContact) {
                spider_state = SPIDER_WAIT;
                spider_timer = spider_attack_hold;
                move_x = 0;
            }
        break;

        case SPIDER_WAIT:
            sprite_index = spr_enemy_spider_attack;
            image_speed = 0;
            spider_timer--;

            if (spider_timer <= 0) {
                spider_state = SPIDER_RETURN;
            }
        break;

        case SPIDER_RETURN:
            sprite_index = spr_enemy_spider_walk;
            image_speed = base_image_speed;

            var _home_dir = sign(home_x - x);
            if (_home_dir != 0) {
                facing = _home_dir;
                move_x = _home_dir * spider_return_speed;
            }

            if (abs(home_x - x) <= spider_home_tolerance || wallContact) {
                x = home_x;
                move_x = 0;
                spider_state = SPIDER_HIDDEN;
                spider_timer = spider_recover_wait;
            }
        break;
    }
}

event_inherited();
