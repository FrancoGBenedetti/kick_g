// ══════════════════════════════════════════════════════════
// OBJ_PROJECTILE_PARENT — Create
// Clase base para todos los proyectiles del juego.
// Hereda de obj_damage_source_parent: daño, anti-multi-hit,
// hit_list, try_hit(), on_hit() y cleanup de memoria.
//
// NO hereda de obj_actor_parent — los proyectiles no necesitan
// física de personaje (gravedad del actor, wallslide, coyote, etc.).
//
// Jerarquía:
//   obj_damage_source_parent
//       └── obj_projectile_parent
//               ├── obj_enemy_arrow          (activo)
//               ├── obj_enemy_fireball       (futuro)
//               ├── obj_enemy_magic_orb      (futuro)
//               └── obj_player_special       (futuro)
//
// Variables que el spawner DEBE asignar tras instance_create_layer():
//   owner    → instancia que disparó (para excluir owner del daño)
//   vel_x    → velocidad horizontal inicial
//   vel_y    → velocidad vertical inicial
//   damage   → daño por impacto (o dejar el default del parent: 1)
//
// Variables opcionales a sobreescribir en subclases:
//   uses_ballistic_trajectory, gravity, lifetime_max, hit_radius, target_object, team, flags
// ══════════════════════════════════════════════════════════
event_inherited();   // owner, damage, can_hit_owner, hit_source,
                     // hit_list, on_hit, try_hit — de obj_damage_source_parent

// ── Tilemap ───────────────────────────────────────────────
// Los proyectiles no heredan de obj_actor_parent, así que
// obtienen su propio acceso al mapa de colisión aquí.
collision_map = layer_tilemap_get_id(layer_get_id(COLLISION_LAYER));

// ── Movimiento ────────────────────────────────────────────
vel_x   = 0;   // px/frame — asignado por el spawner
vel_y   = 0;   // px/frame — asignado por el spawner
gravity = 0;   // px/frame² — se aplica solo si uses_ballistic_trajectory
uses_ballistic_trajectory = false; // false conserva el movimiento previo del proyectil
move_remainder_x = 0;
move_remainder_y = 0;

// ── Detección de impacto ──────────────────────────────────
// Radio del rectángulo de detección alrededor de (x, y).
// Aumentar para proyectiles grandes, reducir para balas finas.
hit_radius = 4;   // px

// ── Objetivo de impacto ───────────────────────────────────
// Índice de objeto al que este proyectil puede dañar.
//   Proyectiles enemigos  → obj_player      (no dañan a enemigos)
//   Proyectiles del jugador → obj_actor_parent (dañan a cualquier actor)
// Sobreescribir en cada subclase según la facción.
target_object = obj_player;

// ── Tipo de ataque ────────────────────────────────────────
// Los proyectiles NO noquean al owner en parry — solo se destruyen/reflejan.
attack_type = ATTACK_TYPE_PROJECTILE;

// ── Equipo / Facción ──────────────────────────────────────
// Identifica quién disparó el proyectil (TEAM_PLAYER / TEAM_ENEMY / TEAM_NEUTRAL).
// Usado como metadata — no implementa friendly-fire todavía.
// Extensión futura: proyectiles con team=TEAM_PLAYER no dañan al jugador,
// independientemente de target_object y can_hit_owner.
team = TEAM_ENEMY;

// Conserva quién lanzó el proyectil antes de que un parry cambie owner.
// Los spawners asignan este dato junto con owner cuando necesitan validar
// un retorno contra su emisor original.
original_owner = noone;

// ── Lifetime ──────────────────────────────────────────────
// Sobreescribir en subclases si el proyectil necesita duración diferente.
lifetime_max  = 180;   // ~3 s a 60 fps
lifetimeTimer = lifetime_max;

// ── Flags de comportamiento ───────────────────────────────
//
// destroy_on_tile_collision:
//   true  → el proyectil se destruye al tocar geometría sólida
//   false → sobrevive al impacto con tiles (rebote, perforación — impl. en subclase)
//
// destroys_on_hit:
//   true  → se destruye al impactar un objetivo (bala, flecha)
//   false → persiste tras impactar (proyectil perforante, explosión de área)
//
// can_be_destroyed_by_sword:
//   true  → al solapar con obj_sword_hitbox del jugador, se destruye
//   false → inmune a la espada (bola de fuego, magia, trampa, etc.)
//
// can_be_parried:
//   true  → el parry del jugador delega el resultado a on_parried()
//   false → ignora el parry y sigue el flujo normal de daño/block.
//
// can_be_blocked:
//   true  → el block normal detiene el daño
//   false → proyectil "unblockable" que atraviesa el escudo.
//
// reflect_on_parry:
//   true  → al ser parriado, el proyectil invierte vel_x y cambia team
//   false → al ser parriado, el proyectil se destruye normalmente
//   Implementación completa pendiente V2.
//
// is_unbreakable:
//   true  → ignora can_be_destroyed_by_sword; parry/block solo aplican
//            lógica de daño según diseño (flag de safety para diseñadores)
//   false → comportamiento normal de todos los flags anteriores
destroy_on_tile_collision = true;
destroys_on_hit           = true;
target_before_tile_collision = false;
ignore_tile_collision = false;
can_be_destroyed_by_sword = false;
can_be_parried            = false;
can_be_blocked            = false;
reflect_on_parry          = false;
is_unbreakable            = false;

// ── Resultado de parry ───────────────────────────────────
// reflect_on_parry queda como flag legado; parry_result es la única
// autoridad para definir la reacción del proyectil.
parry_result = PARRY_DESTROY;
parry_reflect_min_speed = 8;
parry_reflect_speed_multiplier = 1.25;
parry_ignore_player_frames = 2;
parry_ignore_player_timer = 0;
parry_damage_multiplier = 1.5;
parry_absorb_mana = 1;
was_parried = false;

// ── Hook dedicado de parry ───────────────────────────────
// El jugador llama este método después de confirmar un parry frontal.
// Retorna un HIT_RESULT_* para que el Step decida si destruye el objeto.
on_parried = function(_player) {
    switch (parry_result) {
        case PARRY_REFLECT:
            var _original_owner = owner;
            if (!instance_exists(original_owner)) original_owner = _original_owner;
            var _speed = point_distance(0, 0, vel_x, vel_y);
            _speed = max(_speed, parry_reflect_min_speed) * parry_reflect_speed_multiplier;

            var _dir;
            if (instance_exists(_original_owner)) {
                _dir = point_direction(x, y, _original_owner.x, _original_owner.y);
            } else {
                _dir = point_direction(0, 0, -vel_x, -vel_y);
                if (vel_x == 0 && vel_y == 0) _dir = (_player.facing == 1) ? 0 : 180;
            }

            vel_x = lengthdir_x(_speed, _dir);
            vel_y = lengthdir_y(_speed, _dir);
            team = TEAM_PLAYER;
            owner = _player;
            target_object = obj_enemy_parent;
            can_hit_owner = false;
            ds_list_clear(hit_list);

            if (!was_parried) {
                damage *= parry_damage_multiplier;
                was_parried = true;
            }

            // Saca el proyectil de la caja del jugador antes del próximo Step.
            x = _player.x + lengthdir_x(hit_radius + 4, _dir);
            y = _player.y + lengthdir_y(hit_radius + 4, _dir);
            parry_ignore_player_timer = parry_ignore_player_frames;
            return HIT_RESULT_PARRIED_REFLECT;

        case PARRY_ABSORB:
            // El recurso siempre pasa por el helper del jugador; el feedback
            // general de parry no entrega maná adicional a proyectiles.
            _player.grant_parry_mana(parry_absorb_mana);
            return HIT_RESULT_PARRIED_ABSORB;

        case PARRY_DESTROY:
        default:
            return HIT_RESULT_PARRIED_DESTROY;
    }
};

// Decide la destrucción sin colapsar reflect en un booleano genérico.
projectile_should_destroy_after_hit = function(_hit_result) {
    switch (_hit_result) {
        case HIT_RESULT_PARRIED_DESTROY:
        case HIT_RESULT_PARRIED_ABSORB:
            return true;

        case HIT_RESULT_DAMAGE:
        case HIT_RESULT_BLOCKED:
            return destroys_on_hit;
    }

    return false;
};

projectile_find_target = function() {
    if (parry_ignore_player_timer > 0 && target_object == obj_player) {
        return noone;
    }

    return collision_rectangle(
        x - hit_radius, y - hit_radius,
        x + hit_radius, y + hit_radius,
        target_object, false, true
    );
};

// ── Interactivos golpeados por proyectiles ────────────────
// Corre durante el pixel-step, antes de la colisión con tiles.
// Esto permite que una flecha active un target pegado a una pared
// antes de destruirse contra esa pared.
projectile_try_interactive_hit = function() {
    if (object_index != obj_player_arrow) return false;

    var _count = instance_number(obj_pivot_bridge);
    for (var _i = 0; _i < _count; _i++) {
        var _bridge = instance_find(obj_pivot_bridge, _i);
        if (!instance_exists(_bridge)) continue;
        if (_bridge.bridge_state != _bridge.BRIDGE_CLOSED) continue;

        var _range = _bridge.target_radius + hit_radius + 12;
        if (point_distance(x, y, _bridge.target_x, _bridge.target_y) <= _range) {
            with (_bridge) {
                bridge_trigger();
            }
            on_hit(_bridge);
            instance_destroy();
            return true;
        }
    }

    return false;
};
