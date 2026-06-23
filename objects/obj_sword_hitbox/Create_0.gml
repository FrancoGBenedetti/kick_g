// ══════════════════════════════════════════════════════════
// OBJ_SWORD_HITBOX — Create
// Hitbox temporal de espada/lanza. Hereda de obj_damage_source_parent
// todo lo relativo a daño, anti-multi-hit y cleanup de memoria.
//
// ARQUITECTURA DE ATAQUE:
// • La máscara de colisión física del player (~56px ancho) en col_left/col_right
//   permanece compacta alrededor del cuerpo.
// • Esta hitbox es INDEPENDIENTE y se extiende hacia adelante.
// • No afecta a la colisión del player con paredes/plataformas.
// • Solo detecta enemigos y les aplica daño.
//
// CONFIGURACIÓN:
// Spawneado por obj_player al inicio de cada ataque.
// El player asigna parámetros inmediatamente:
//
//   with (sword_hitbox_id) {
//       owner           = _player_id;    // dueño (jugador)
//       damage          = _hb_dmg;       // daño del golpe
//       lifetime        = _hb_life;      // frames de vida
//       hitbox_offset_x = ...;           // offset horizontal (relativo a facing)
//       hitbox_offset_y = ...;           // offset vertical
//       hitbox_w        = ...;           // ancho total
//       hitbox_h        = ...;           // alto total
//       is_pogo         = ...;           // true si es downward slash
//   }
//
// POSICIONAMIENTO:
// x = owner.x + owner.facing * hitbox_offset_x
// y = owner.y + hitbox_offset_y
// El hitbox se dibuja como rectángulo centrado en (x, y).
//
// DESACTIVACIÓN:
// Durante el paso de turnos, se sincroniza hit_source = owner
// para garantizar knockback correcto incluso con movimiento rápido del player.
// ══════════════════════════════════════════════════════════
event_inherited();   // owner, damage, can_hit_owner, hit_source,
                     // hit_list, on_hit, try_hit — del parent

// ── Super Energy: cantidad ganada por este golpe ──────────
// Set externamente al spawnear la hitbox según el tipo de ataque:
//   ATTACK_1/2/3  → sword_hit_energy_gain  o  air_sword_hit_energy_gain
//   DASH_ATTACK   → sword_hit_energy_gain
//   DOWN_SLASH    → downward_slash_energy_gain
//   COUNTER_ATTACK → counter_energy_gain
// Default 0: seguro si el spawn no lo asigna (no da energía silenciosamente).
energy_gain_amount = 0;

// ── on_hit: air bounce + super energy ─────────────────────
// Llamado por try_hit() tras aplicar daño exitosamente.
// Sobreescrito por el downward slash (pogo) con su propia lógica
// — el pogo reemplaza este on_hit, por lo que air bounce y energy
// del pogo se manejan en su propia closure (Step_0 del player).
on_hit = function(_target) {
    if (!instance_exists(owner)) exit;
    owner.apply_air_sword_bounce();          // rebote aéreo si aplica (guards internos)
    owner.gain_super_energy(energy_gain_amount);  // energía si energy_gain_amount > 0
};

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

// ── Counter target filter ─────────────────────────────────
// Cuando counter_target_id != noone, esta hitbox SOLO intenta golpear
// a esa instancia específica (el enemigo parryeado).
// Esto evita que el counter accidentalmente dañe enemigos cercanos.
// Valor noone = comportamiento normal (cualquier actor en el área).
counter_target_id = noone;

// ── Lifetime ──────────────────────────────────────────────
// Frames de vida. Se decrementa en Step; al llegar a 0
// notifica al owner y se destruye.
// Para hitboxes pogo: se asigna = down_slash_frames al spawnear,
// pero el exit hook de DOWN_SLASH garantiza la limpieza antes de expirar.
lifetime = 6;
