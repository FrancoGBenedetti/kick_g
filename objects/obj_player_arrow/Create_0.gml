// ══════════════════════════════════════════════════════════
// OBJ_PLAYER_ARROW — Create
// Proyectil del jugador. Hereda de obj_projectile_parent
// → obj_damage_source_parent.
//
// Cadena de herencia completa:
//   obj_damage_source_parent   → owner, damage, hit_list, try_hit, on_hit
//   obj_projectile_parent      → collision_map, vel_x/y, gravity, pixel-stepping,
//                                 hit_radius, target_object, team, lifetime,
//                                 destroy_on_tile_collision, destroys_on_hit,
//                                 can_be_destroyed_by_sword, can_be_parried, etc.
//   obj_player_arrow (este)    → overrides específicos del jugador
//
// Variables asignadas por obj_player tras instance_create_layer():
//   owner        → id del jugador (excluido del daño por can_hit_owner=false)
//   vel_x, vel_y → velocidad balística calculada desde carga y aim_angle
//   damage       → daño según carga (1/2/3)
//   charge_level → nivel de carga
//   is_aerial    → true si se disparó en el aire
//
// hit_source permanece noone → knockback desde el punto de impacto ✓
// ══════════════════════════════════════════════════════════
event_inherited();   // obj_projectile_parent → obj_damage_source_parent:
                     // inicia collision_map, vel_x/y, gravity, hit_radius,
                     // target_object, team, lifetime, todos los flags.

// ── Overrides del parent ──────────────────────────────────
// Los defaults del parent son para proyectiles enemigos (TEAM_ENEMY, target=obj_player).
// Sobreescribir aquí con los valores correctos para el jugador.
damage_type   = "arrow";
attack_type   = ATTACK_TYPE_PROJECTILE;
target_object = obj_actor_parent;   // daña a cualquier actor (enemigos, trampas futuras)
team          = TEAM_PLAYER;        // arma del jugador
can_be_parried = false;             // las flechas del jugador no se pueden parriar
can_be_blocked = false;
is_projectile  = true;
uses_ballistic_trajectory = true;   // activa gravedad y acumuladores del parent
gravity        = BOW_ARROW_GRAVITY;
lifetime_max   = 120;               // ~2 s a 60 fps
lifetimeTimer  = lifetime_max;

// ── Velocidad de flecha ───────────────────────────────────
// El player calcula vel_x/vel_y desde BOW_ARROW_MIN/MAX_SPEED tras el spawn.

// ── Datos de carga ────────────────────────────────────────
charge_level = 0;    // nivel de carga asignado por el player (0/1/2)
charge_normalized = 0;
is_aerial    = false; // true si se disparó en el aire (para mecánicas futuras)

// ── Hook de impacto ───────────────────────────────────────
on_hit = function(_target) {
    // Futuro: partículas proporcionales a charge_level
    // Futuro: audio_play_sound(snd_arrow_hit, 0, false)
};
