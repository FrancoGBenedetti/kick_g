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
//   gravity, lifetime_max, hit_radius, target_object, team, flags
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
gravity = 0;   // px/frame² — 0 = recto; > 0 = arco parabólico

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
//   true  → intención: el parry del jugador neutraliza este proyectil
//   false → intención: el parry no tiene efecto
//   NOTA V1: la distinción can_be_parried=false aún no está implementada
//   en el override take_damage del jugador — todos los proyectiles son
//   parriables si el jugador tiene parry activo. Implementar en V2:
//     en player.take_damage: if (is_parrying && _source.can_be_parried) ...
//
// can_be_blocked:
//   true  → intención: el block detiene el daño
//   false → intención: proyectil "unblockable" que atraviesa el escudo
//   NOTA V1: igual que can_be_parried — semántica pendiente de V2.
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
can_be_destroyed_by_sword = false;
can_be_parried            = false;
can_be_blocked            = false;
reflect_on_parry          = false;
is_unbreakable            = false;
