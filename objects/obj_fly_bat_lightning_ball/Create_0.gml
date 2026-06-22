// ══════════════════════════════════════════════════════════
// OBJ_FLY_BAT_LIGHTNING_BALL — Create
// Proyectil disparado por obj_test_fly_bat.
// Hereda de obj_projectile_parent → obj_damage_source_parent.
//
// El Step y la colisión con tiles/jugador están completamente
// delegados al parent (pixel-stepping, lifetime, bounds check).
//
// Variables asignadas por el bat tras instance_create_layer():
//   owner  → id del bat (excluido del daño)
//   damage → enemy_damage del bat (default 1)
//   vel_x  → componente X de la dirección al jugador
//   vel_y  → componente Y de la dirección al jugador
//
// Ajustables desde el bat (Create_0 del bat):
//   lightning_ball_speed → velocidad del proyectil (px/frame)
// ══════════════════════════════════════════════════════════
event_inherited();   // obj_projectile_parent → obj_damage_source_parent

// ── Tipo de daño ──────────────────────────────────────────
damage_type = "enemy_lightning";

// ── Objetivo: solo el jugador ─────────────────────────────
target_object = obj_player;   // ya es el default del parent; explícito por claridad

// ── Equipo ────────────────────────────────────────────────
team = TEAM_ENEMY;   // default del parent; explícito por claridad

// ── Sin gravedad: viaja en línea recta ────────────────────
gravity = 0;

// ── Lifetime ──────────────────────────────────────────────
lifetime_max  = 240;   // ~4 s a 60 fps
lifetimeTimer = lifetime_max;

// ── Radio de impacto ──────────────────────────────────────
// Ligeramente más grande que el radio visual (8 px) para que
// el hit sea generoso y no se sienta injusto.
hit_radius = 8;

// ── Flags de comportamiento ───────────────────────────────
can_be_destroyed_by_sword = true;    // la espada del jugador la destruye
can_be_parried            = true;    // parry perfecto la neutraliza
can_be_blocked            = true;    // block normal detiene el daño
reflect_on_parry          = false;   // futuro: reflect_on_parry = true
destroys_on_hit           = true;    // se destruye al impactar
destroy_on_tile_collision = true;    // se destruye al tocar tile sólido
is_unbreakable            = false;

// ── Hook de impacto ───────────────────────────────────────
on_hit = function(_target) {
    // Futuro: partículas eléctricas, flash amarillo, sonido de rayo
};
