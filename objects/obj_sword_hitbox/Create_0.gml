// ══════════════════════════════════════════════════════════
// OBJ_SWORD_HITBOX — Create
// Hitbox temporal de espada. Hereda de obj_damage_source_parent
// todo lo relativo a daño, anti-multi-hit y cleanup de memoria.
//
// Spawneado por obj_player al inicio de cada estado ATTACK_N.
// El player lo configura inmediatamente después del spawn:
//
//   with (sword_hitbox_id) {
//       owner      = _player_id;   // dueño (jugador)
//       damage     = _hb_dmg;      // daño del golpe
//       lifetime   = _hb_life;     // frames de vida
//       hitbox_offset_x = ...;
//       hitbox_offset_y = ...;
//       hitbox_w        = ...;
//       hitbox_h        = ...;
//   }
//
// hit_source se sincroniza con owner cada frame en Step,
// garantizando knockback correcto incluso si owner cambia.
// ══════════════════════════════════════════════════════════
event_inherited();   // owner, damage, can_hit_owner, hit_source,
                     // hit_list, on_hit, try_hit — del parent

// ── Tipo de daño ──────────────────────────────────────────
damage_type    = "melee";
team           = TEAM_PLAYER;   // arma del jugador — no daña al jugador ni aliados
can_be_parried = false;         // no tiene sentido que los enemigos parrién la espada del jugador
can_be_blocked = false;         // no tiene sentido bloquear la espada del jugador
is_melee       = true;

// ── Geometría de la hitbox ────────────────────────────────
// Configurada externamente por obj_player al spawnear.
// Valores por defecto como fallback de seguridad.
hitbox_offset_x = 20;   // px hacia adelante del owner (en dirección facing)
hitbox_offset_y = -10;  // px hacia arriba del origen del owner
hitbox_w        = 30;   // ancho total del rectángulo de colisión
hitbox_h        = 26;   // alto total del rectángulo de colisión

// ── Tipo de hitbox ────────────────────────────────────────
// is_pogo = true  → downward slash / pogo attack.
// Permite configurar on_hit externamente para aplicar el rebote
// sin modificar la lógica del Step compartido.
is_pogo = false;

// ── Lifetime ──────────────────────────────────────────────
// Frames de vida. Se decrementa en Step; al llegar a 0
// notifica al owner y se destruye.
// Para hitboxes pogo: se asigna = down_slash_frames al spawnear,
// pero el exit hook de DOWN_SLASH garantiza la limpieza antes de expirar.
lifetime = 6;
