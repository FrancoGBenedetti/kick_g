// ══════════════════════════════════════════════════════════
// OBJ_DAMAGE_SOURCE_PARENT — Create
// Clase base para toda fuente de daño del juego.
//
// Hereda: nada (raíz de la jerarquía de combate).
// Hijos directos: obj_sword_hitbox, obj_player_arrow.
// Hijos futuros: proyectiles enemigos, trampas, rocas,
//                hitboxes de boss, explosiones.
//
// Esta clase NO tiene Step ni Draw — cada hijo gestiona
// su propio movimiento, geometría y lifetime.
// La única responsabilidad compartida es APLICAR DAÑO
// de forma correcta y consistente mediante try_hit().
// ══════════════════════════════════════════════════════════

// ── Identidad ─────────────────────────────────────────────
// owner: instancia que creó esta fuente de daño.
//   Usado para excluir al creador del daño (espada del jugador)
//   y para referenciar al atacante en efectos y callbacks.
//   Debe asignarse externamente justo después del spawn.
owner = noone;

// hit_source: instancia usada como origen del cálculo de knockback.
//   noone   → se usa id propio (correcto para proyectiles: el
//              knockback apunta DESDE el punto de impacto).
//   = owner → correcto para hitboxes melee: el knockback apunta
//              DESDE el atacante, no desde la hitbox desplazada
//              (una hitbox delante del jugador puede dar dirección
//              invertida si el enemigo está muy cerca del filo).
hit_source = noone;

// ── Datos de daño ─────────────────────────────────────────
damage      = 1;          // HP que quita por impacto exitoso
damage_type = "generic";  // tipo semántico — reservado para sistemas
                          // de inmunidad/debilidad futuros:
                          // "melee" | "arrow" | "fire" | "poison" | etc.

// attack_type: categoría mecánica del ataque (distinta del tipo de daño).
//   ATTACK_TYPE_MELEE      → activa parry stun en el owner al ser parriado
//   ATTACK_TYPE_PROJECTILE → solo se destruye/refleja; no noquea al owner
// Sobreescribir en subclases según el tipo de source.
attack_type = ATTACK_TYPE_MELEE;   // default conservador (cambia en proyectiles)

// ── Protección contra daño al dueño ──────────────────────
// false (default): el owner nunca puede ser dañado por su propia fuente.
//   → espada del jugador no daña al jugador.
// true: útil para mecánicas de área (bomba, splash, trampa compartida).
can_hit_owner = false;

// ── Knockback personalizado (reservado — extensión futura) ─
// Cuando != 0, permitirá sobreescribir default_knockback_x del target.
// Requiere que take_damage() lea _source.knockback_force cuando
// _source es instancia de obj_damage_source_parent.
// Por ahora los actores usan su propio default_knockback_x.
knockback_force = 0;

// ── Equipo / Facción ──────────────────────────────────────
// Identifica a quién pertenece esta fuente de daño.
//   TEAM_NEUTRAL (0) → sin facción (default conservador — no implementa friendly-fire)
//   TEAM_PLAYER  (1) → espada, flecha y cualquier arma del jugador
//   TEAM_ENEMY   (2) → hitboxes y proyectiles de enemigos
//
// Usado como metadata para: parry filtering, reflect futuro, HUD de procedencia.
// try_hit() NO filtra por team todavía — los actores no tienen team propio.
// Para friendly-fire prevention, agregar check aquí en V2.
// Sobreescribir en cada subclase.
team = TEAM_NEUTRAL;

// ── Parry / Block ─────────────────────────────────────────
// can_be_parried: el parry perfecto del jugador neutraliza este ataque.
//   true  → melee enemigo (activa parry stun en el owner al ser parriado)
//   false → armas del jugador, trampas, ataques unblockable
// can_be_blocked: el block normal (no perfecto) detiene el daño.
// Sobreescribir en subclases según diseño.
can_be_parried = false;
can_be_blocked = false;

// ── Tipo semántico ────────────────────────────────────────
// Flags de conveniencia para sistemas futuros (reflect, absorb, inmunidad).
// attack_type ya cubre MELEE vs PROJECTILE para el parry;
// is_melee/is_projectile son aliases semánticos más legibles.
is_melee      = false;   // true = golpe cuerpo a cuerpo (espada, patada, slam…)
is_projectile = false;   // true = proyectil en vuelo (flecha, magia, bala…)

// ── Anti-multi-hit ────────────────────────────────────────
// Registro de instancias ya golpeadas en este swing/vuelo.
// Evita múltiples llamadas a take_damage() sobre el mismo target
// en el mismo frame (aunque los i-frames del actor también lo
// bloquearían, evitamos el overhead de llamadas innecesarias).
// LIMPIEZA: gestionada automáticamente por el evento Destroy
// del parent — no es necesario llamar ds_list_destroy() en hijos.
hit_list = ds_list_create();

// ── Hook de impacto ───────────────────────────────────────
// Disparado desde try_hit() tras aplicar daño exitosamente.
// _target: instancia dañada, o noone si el golpe fue sobre
//          un tile (p.ej. flecha que impacta el suelo).
// Sobreescribir en subclases para efectos, sonidos, partículas,
// hit-stop, cambios de fase, etc.
on_hit = function(_target) {
    // Futuro: hit-stop → scr_time_manager.time_set_slow() por 3 frames
    // Futuro: partículas de impacto según damage_type
    // Futuro: audio_play_sound según damage_type
};

// ── try_hit(_target) — punto único de aplicación de daño ──
// Retorna true si el daño fue aplicado; false si fue rechazado.
//
// Reglas de rechazo (en orden de coste computacional):
//   1. target inválido (noone, ya destruido)
//   2. target es el owner y can_hit_owner = false
//   3. target ya procesado en este swing (hit_list)
//
// Fuente del knockback:
//   hit_source válido → usar hit_source (melee: el jugador detrás de la hitbox)
//   hit_source == noone  → usar id propio (proyectil: el punto de impacto)
//
// Uso en hijos:
//   var _found = collision_rectangle(..., obj_actor_parent, ...);
//   try_hit(_found);   // noone retorna false sin crash
try_hit = function(_target) {
    // ── Regla 1: target debe existir ─────────────────────
    if (!instance_exists(_target)) return false;

    // ── Regla 2: respetar can_hit_owner ──────────────────
    if (!can_hit_owner && _target == owner) return false;

    // ── Regla 3: anti-multi-hit ───────────────────────────
    if (ds_list_find_index(hit_list, _target) != -1) return false;
    ds_list_add(hit_list, _target);

    // ── Aplicar daño con fuente correcta ─────────────────
    var _src = (hit_source != noone && instance_exists(hit_source))
               ? hit_source
               : id;
    _target.take_damage(damage, _src);

    // ── Hook de efectos ───────────────────────────────────
    // CONTRATO: on_hit recibe _target tal como fue golpeado.
    // take_damage() puede llamar a die() → instance_destroy() DENTRO
    // de la misma llamada, por lo que _target puede estar destruido
    // cuando on_hit se ejecuta. Los callbacks deben verificar
    // instance_exists(_target) antes de leer cualquier propiedad.
    // El rebote del pogo NO necesita que _target exista — solo aplica
    // velocidad al owner, por lo que funciona correctamente en ambos casos.
    on_hit(_target);

    return true;
};
