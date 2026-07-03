// ══════════════════════════════════════════════════════════
// OBJ_PROJECTILE_PARENT — Step
// Lógica compartida de movimiento, colisión y lifetime para
// todos los proyectiles del juego.
//
// Flujo por frame:
//   1. Gate time_scale
//   2. Gravedad opcional (vel_y += gravity)
//   3. Orientación visual (image_angle según trayectoria)
//   4. Movimiento horizontal con pixel-stepping + colisión tile + hit objetivo
//   5. Movimiento vertical  con pixel-stepping + colisión tile + hit objetivo
//   6. Destrucción por espada (si can_be_destroyed_by_sword)
//   7. Lifetime countdown
//   8. Out-of-bounds check
//
// Extensión en subclases:
//   • Lógica ANTES de event_inherited() → pre-step (p.ej. homing, oscilación)
//   • Lógica DESPUÉS de event_inherited() → post-step (p.ej. trail de partículas)
//   • Sobreescribir on_hit() para efectos de impacto específicos
// ══════════════════════════════════════════════════════════
if (!global.do_step) exit;

// ── Gravedad ──────────────────────────────────────────────
// Añade arco parabólico natural. Máximo 20 px/frame (evita tunneling).
if (gravity != 0) {
    vel_y = min(vel_y + gravity, 20);
}

// ── Orientación visual ────────────────────────────────────
// Rota el sprite para que apunte en la dirección de vuelo.
// Estándar GML: 0° = derecha, ángulo antihorario.
// Correcto para sprites con el frente mirando a la derecha.
// Ignorado si el proyectil no tiene sprite asignado.
image_angle = point_direction(0, 0, vel_x, vel_y);

// ── Movimiento horizontal + colisión ─────────────────────
// Pixel-stepping: avanza 1 px por iteración. Garantiza que
// ningún objeto fino es atravesado aunque la velocidad sea alta.
if (vel_x != 0) {
    var _hstep = sign(vel_x);
    repeat (ceil(abs(vel_x))) {
        x += _hstep;

        if (projectile_try_interactive_hit()) exit;

        // Colisión con tile sólido
        if (tile_solid_at(collision_map, x, y)) {
            on_hit(noone);
            if (destroy_on_tile_collision) {
                instance_destroy();
                exit;
            }
            vel_x = 0;
            break;
        }

        // Colisión con objetivo
        // try_hit maneja: owner-exclusion, anti-multi-hit, take_damage + on_hit
        var _found = collision_rectangle(
            x - hit_radius, y - hit_radius,
            x + hit_radius, y + hit_radius,
            target_object, false, true
        );
        if (try_hit(_found)) {
            if (destroys_on_hit) {
                instance_destroy();
                exit;
            }
            break;
        }
    }
}

// ── Movimiento vertical + colisión ───────────────────────
if (vel_y != 0) {
    var _vstep = sign(vel_y);
    repeat (ceil(abs(vel_y))) {
        y += _vstep;

        if (projectile_try_interactive_hit()) exit;

        if (tile_solid_at(collision_map, x, y)) {
            on_hit(noone);
            if (destroy_on_tile_collision) {
                instance_destroy();
                exit;
            }
            vel_y = 0;
            break;
        }

        var _found = collision_rectangle(
            x - hit_radius, y - hit_radius,
            x + hit_radius, y + hit_radius,
            target_object, false, true
        );
        if (try_hit(_found)) {
            if (destroys_on_hit) {
                instance_destroy();
                exit;
            }
            break;
        }
    }
}

// ── Destrucción por espada ────────────────────────────────
// Detecta si obj_sword_hitbox del jugador solapa el proyectil.
// El radio de detección es ligeramente mayor que hit_radius
// para compensar la ausencia de pixel-stepping en esta verificación.
//
// Condición: can_be_destroyed_by_sword && !is_unbreakable
//
// NOTA: no se verifica el owner de la espada porque en el juego
// actual solo el jugador genera obj_sword_hitbox. Si en el futuro
// los enemigos también tienen espadas, agregar:
//   if (_sword.owner.object_index == obj_player)
if (can_be_destroyed_by_sword && !is_unbreakable) {
    var _r = hit_radius + 2;
    var _sword = collision_rectangle(
        x - _r, y - _r,
        x + _r, y + _r,
        obj_sword_hitbox, false, true
    );
    if (instance_exists(_sword)) {
        on_hit(noone);   // hook de efectos (partículas, sonido, etc.)
        instance_destroy();
        exit;
    }
}

// ── Lifetime ──────────────────────────────────────────────
if (--lifetimeTimer <= 0) {
    instance_destroy();
    exit;
}

// ── Fuera de bounds ───────────────────────────────────────
// Margen de 64 px para proyectiles que van lentos o en diagonal.
if (x < -64 || x > room_width + 64 || y < -64 || y > room_height + 64) {
    instance_destroy();
}
