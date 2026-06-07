// ══════════════════════════════════════════════════════════
// OBJ_ENEMY_ARROW — Create
// Proyectil disparado por obj_enemy_archer.
// Hereda de obj_projectile_parent → obj_damage_source_parent.
//
// Lógica genérica (gravedad, pixel-stepping, colisión, lifetime,
// destrucción por espada, bounds check) delegada al parent.
//
// Variables asignadas por el arquero tras instance_create_layer():
//   owner   → id del arquero (excluido del daño por can_hit_owner=false)
//   damage  → EARCHER_DAMAGE (típico: 1)
//   vel_x   → facing * arrow_speed * cos(aim_angle)
//   vel_y   → arrow_speed * sin(aim_angle)
// ══════════════════════════════════════════════════════════
event_inherited();   // obj_projectile_parent → obj_damage_source_parent

// ── Tipo de daño ──────────────────────────────────────────
damage_type = "enemy_arrow";

// ── Objetivo ──────────────────────────────────────────────
// Solo puede impactar al jugador — no daña a otros enemigos.
// target_object = obj_player ya es el default del parent;
// se explicita aquí por claridad de intención.
target_object = obj_player;

// ── Equipo ────────────────────────────────────────────────
team = TEAM_ENEMY;   // default del parent; explícito por claridad

// ── Gravedad del proyectil ────────────────────────────────
// Arco suave natural. Sobreescribir para flechas balísticas o mágicas.
// La variable 'gravity' la procesa obj_projectile_parent/Step.
gravity = 0.12;   // px/frame²

// ── Lifetime ──────────────────────────────────────────────
// Sobreescribe el default de 180f del parent.
lifetime_max  = 150;   // ~2.5 s a 60 fps
lifetimeTimer = lifetime_max;

// ── Flags de comportamiento ───────────────────────────────
can_be_destroyed_by_sword = true;    // la espada del jugador la destruye
can_be_parried            = true;    // el parry la neutraliza
can_be_blocked            = true;    // el block detiene el daño
reflect_on_parry          = false;   // futuro: reflect_on_parry = true (flecha robada)
is_unbreakable            = false;

// ── Hook de impacto ───────────────────────────────────────
// Sobreescribe el stub del parent.
// _target: actor golpeado, o noone si el impacto fue en un tile.
on_hit = function(_target) {
    // Futuro: partículas de impacto (tierra/madera según superficie)
    // Futuro: audio_play_sound(snd_arrow_hit, 0, false)
};
