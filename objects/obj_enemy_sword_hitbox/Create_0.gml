// ══════════════════════════════════════════════════════════
// OBJ_ENEMY_SWORD_HITBOX — Create
// Hitbox de espada de enemigo. Hereda de obj_damage_source_parent.
// Creada y configurada por obj_enemy_swordsman en ESTATE_ATTACK_WINDUP.
//
// Diferencias con obj_sword_hitbox (del jugador):
//   • Solo puede golpear a obj_player (no a otros actores).
//   • hit_source = owner (knockback desde el enemigo, no la hitbox).
//   • damage_type = "enemy_melee" (para compatibilidad futura con
//     inmunidades, resistencias, parry diferenciado, etc.)
//
// Variables configuradas por el creador tras el spawn:
//   owner, hit_source, damage, lifetime, hitbox_offset_x/y/w/h
// ══════════════════════════════════════════════════════════
event_inherited();   // owner, damage, can_hit_owner, hit_source,
                     // hit_list, on_hit, try_hit — del parent

// ── Tipo de daño ──────────────────────────────────────────
damage_type    = "enemy_melee";
attack_type    = ATTACK_TYPE_MELEE;   // activa parry stun en el swordsman owner cuando es parriado
team           = TEAM_ENEMY;          // arma del enemigo — daña al jugador
can_be_parried = true;                // parry perfecto del jugador lo neutraliza y stunnea al owner
can_be_blocked = true;                // block normal detiene el daño
is_melee       = true;

// ── Geometría (valores por defecto — sobreescritos al spawnear) ──
// El swordsman usa estos valores de config; otros enemigos pueden variar.
hitbox_offset_x = 110;  // fallback — sobreescrito por el swordsman
hitbox_offset_y = -40;  // fallback
hitbox_w        = 220;  // fallback
hitbox_h        = 120;  // fallback

// ── Lifetime ──────────────────────────────────────────────
lifetime = 12;
