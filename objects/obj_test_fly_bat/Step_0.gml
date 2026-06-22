// ══════════════════════════════════════════════════════════
// OBJ_TEST_FLY_BAT — Step
//
// Flujo por frame:
//   1. Gate de time_scale (global.do_step)
//   2. Cooldown de disparo
//   3. Calcular movimiento horizontal
//   4. Calcular movimiento vertical senoidal
//   5. Detectar jugador y disparar si corresponde
//   6. event_inherited() → enemy_parent → actor_parent
//      (hitstun/knockback, tile collision, wallContact, i-frames)
//   7. Rebotar si tocó pared (solo fuera de hitstun)
//
// Ajuste de parámetros en Create_0:
//   fly_speed             → velocidad horizontal
//   fly_vertical_speed    → qué tan rápido oscila en Y
//   fly_vertical_amplitude → cuántos px sube/baja
//   shoot_range           → distancia de detección del jugador
//   shoot_cooldown_max    → frames entre disparos
//   lightning_ball_speed  → velocidad del proyectil
// ══════════════════════════════════════════════════════════
if (!global.do_step) exit;

// ── 1. Cooldown de disparo ─────────────────────────────────
if (shoot_cooldown > 0) shoot_cooldown--;

// ── 2. Movimiento horizontal ───────────────────────────────
// move_x es sobrescrito por knockback durante hitstun (en actor_parent).
// Fuera de hitstun, el bat patrulla según fly_dir.
move_x = fly_dir * fly_speed;

// ── 3. Flotación vertical senoidal ────────────────────────
// Avanzar la fase y calcular la Y objetivo.
// move_y lleva al bat gradualmente hacia esa Y, clampeado a ±2 px/frame
// para que la transición sea suave incluso si fue desplazado por knockback.
fly_vertical_phase += fly_vertical_speed;
var _target_y = base_y + sin(fly_vertical_phase) * fly_vertical_amplitude;
move_y = clamp(_target_y - y, -2, 2);

// ── 4. Detectar jugador y disparar ────────────────────────
if (shoot_cooldown <= 0 && instance_exists(obj_player)) {
    if (point_distance(x, y, obj_player.x, obj_player.y) <= shoot_range) {
        var _ang = point_direction(x, y, obj_player.x, obj_player.y);
        var _b   = instance_create_layer(x, y, "Instances_2", obj_fly_bat_lightning_ball);
        _b.owner  = id;
        _b.damage = enemy_damage;
        _b.vel_x  = lengthdir_x(lightning_ball_speed, _ang);
        _b.vel_y  = lengthdir_y(lightning_ball_speed, _ang);
        shoot_cooldown = shoot_cooldown_max;
    }
}

// ── 5. Física heredada ────────────────────────────────────
// Orden: enemy_parent (hit flash, contact damage check, separación)
//      → actor_parent (hitstun/knockback, tile collision, wallContact, i-frames)
// grav = 0 → actor_parent no aplica gravedad.
event_inherited();

// ── 6. Rebotar en muro ────────────────────────────────────
// wallContact lo setea actor_parent tras resolver colisión horizontal.
// Solo fuera de hitstun: durante knockback no queremos invertir fly_dir.
if (wallContact && hitstun_timer <= 0) {
    fly_dir *= -1;
    x += fly_dir * 2;   // pequeño empuje para despegar del muro
}
