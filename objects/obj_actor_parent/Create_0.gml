move_x = 0;
move_y = 0;

grav             = 0.5;
max_fall         = 14;
fall_max_default = max_fall;  // referencia para restaurar max_fall desde estados que lo modifican

var _layer_id = layer_get_id(COLLISION_LAYER);
collision_map = layer_tilemap_get_id(_layer_id);

// ── DEBUG TEMPORAL: verificar que la capa y el tilemap se encuentran ──
// Quitar estas líneas cuando todo funcione.
show_debug_message("[COLLISION-INIT] object=" + object_get_name(object_index));
show_debug_message("  COLLISION_LAYER = '" + COLLISION_LAYER + "'");
show_debug_message("  layer_id        = " + string(_layer_id)   + (_layer_id   == -1 ? "  ← ERROR: capa no encontrada" : "  ✓"));
show_debug_message("  collision_map   = " + string(collision_map) + (collision_map == -1 ? "  ← ERROR: tilemap no encontrado" : "  ✓"));
// ─────────────────────────────────────────────────────────────────────

// Offsets relativos al origen (bbox_* son coords absolutas)
col_left   = bbox_left   - x;
col_right  = bbox_right  - x;
col_top    = bbox_top    - y;
col_bottom = bbox_bottom - y;

// ── Estados físicos ───────────────────────────────────────
isGrounded = false;
isJumping  = false;
isFalling  = false;

// ── Contacto lateral con paredes ──────────────────────────
wallContact = false;
wallSide    = 0;      // -1 izq | 0 ninguna | +1 der

// ── Dirección que mira el actor ───────────────────────────
facing = 1;           // +1 derecha | -1 izquierda

// ── Flip de sprite y escala de imagen ─────────────────────
// image_xscale = facing se aplica en Step después de actualizar facing.
// Usar draw_x_offset / draw_y_offset para separar la posición visual
// de la posición física sin afectar la hitbox ni la física.
//   Ejemplo: draw_y_offset = PLAYER_DRAW_OY → embedding visual en suelo.
image_xscale   = 1;   // sobreescrito cada frame por facing
image_yscale   = 1;   // reservado para escala vertical (animaciones futuras)
draw_x_offset  = 0;   // px — offset visual horizontal
draw_y_offset  = 0;   // px — offset visual vertical (sobreescribir en subclases)

// ── Coyote time ───────────────────────────────────────────
coyote_max  = 6;      // frames disponibles al salir del suelo sin saltar
coyoteTimer = 0;
prev_grounded = false;

// ══════════════════════════════════════════════════════════
// SISTEMA DE SALUD Y DAÑO
// ══════════════════════════════════════════════════════════

// ── Puntos de vida ────────────────────────────────────────
max_hp = 3;       // máximo de HP — sobreescribir en subclases
hp     = max_hp;  // HP actual

// ── I-frames (invulnerabilidad temporal post-daño) ────────
is_invulnerable  = false;
invuln_timer     = 0;
default_invuln   = 60;   // frames de i-frames (~1s a 60fps) — sobreescribir en subclases

// invuln_on_damage: controla si el actor gana i-frames al recibir daño.
//   true  (default) → actor queda invulnerable durante default_invuln frames
//   false           → nunca gana i-frames; puede recibir golpes repetidos
//
// Regla de diseño:
//   • Jugador:        invuln_on_damage = true  (hereda este default)
//   • Enemigos base:  invuln_on_damage = false (sobreescrito en obj_enemy_parent)
//   • Bosses:         invuln_on_damage = true  (sobreescribir y ajustar default_invuln)
invuln_on_damage = true;

// ── Hitstun ───────────────────────────────────────────────
// Durante hitstun: el actor no puede actuar, move_x es reemplazado
// por knockback_x y no se actualiza facing.
// El timer respeta time_scale (corre en gated) para que sea consistente
// con el ritmo de gameplay incluso durante slow motion.
hitstun_timer   = 0;
default_hitstun = 12;   // frames de hitstun (~0.2s a 60fps)

// ── Knockback ─────────────────────────────────────────────
// Velocidad horizontal aplicada al recibir daño. Decae exponencialmente
// cada frame hasta llegar a cero antes de que acabe el hitstun.
//
// Flujo:
//   take_damage → knockback_x = _kdir * default_knockback_x
//                 move_y      = knockback_y_force
//   Step (gated) → move_x    = knockback_x
//               knockback_x  *= knockback_decay   (cada frame de hitstun)
//
// Geometría de knockback_decay a 60fps:
//   decay=0.70, 12 frames → 5 * 0.70^12 ≈ 0.07 px  (esencialmente 0) ✓
knockback_x         = 0;     // velocidad actual (decae sola; no modificar externamente)
default_knockback_x = 5;     // magnitud inicial en px/frame al recibir daño
knockback_y_force   = -3;    // impulso vertical al recibir daño (negativo = arriba)
knockback_decay     = 0.70;  // factor multiplicativo por frame

// ── Super armor ───────────────────────────────────────────
// Cuando es true: take_damage aplica daño e i-frames pero no hitstun ni knockback.
// Útil para estados de boss, dash blindado o golpe cargado del jugador.
super_armor = false;

// ══════════════════════════════════════════════════════════
// ── Barra de vida flotante (world-space) ─────────────────
// Dibujada en el evento Draw del parent, sobre la cabeza del actor.
// Solo visible cuando hp < max_hp (barra oculta al full de vida).
// Actores que usan barra de HUD propia (jugador) deben setear
// show_world_healthbar = false en su Create para suprimirla.
//
// Todos los parámetros son sobreescribibles en subclases:
//   hpbar_width    ancho de la barra en px
//   hpbar_height   alto en px
//   hpbar_offset_y desplazamiento Y sobre col_top (negativo = más arriba)
//   hpbar_col_bg   color del fondo (zona vacía)
//   hpbar_col_fill color del relleno (vida restante)
show_world_healthbar = true;
hpbar_width          = HPBAR_WIDTH;    // 80 px — proporcional a sprites HD (desde scr_config)
hpbar_height         = HPBAR_HEIGHT;   //  8 px
hpbar_offset_y       = HPBAR_OFFSET_Y; // -20 px sobre col_top del actor
hpbar_col_bg         = make_color_rgb( 30,  10,  10); // rojo muy oscuro
hpbar_col_fill       = make_color_rgb( 40, 200,  80); // verde

// MÉTODOS DE DAÑO (virtuales — sobreescribir en subclases)
// ══════════════════════════════════════════════════════════
//
// Jerarquía recomendada:
//   take_damage → lógica base (i-frames, knockback, hitstun) — NO sobreescribir
//   on_damage   → reacción visual/sonora — sobreescribir libremente
//   die         → lógica de muerte — sobreescribir libremente

// take_damage: punto de entrada principal.
// Desde fuera:  target.take_damage(cantidad, id_fuente);
take_damage = function(_amount, _source) {
    if (is_invulnerable) exit;

    hp = max(hp - _amount, 0);

    // I-frames condicionales: solo si invuln_on_damage = true.
    // Jugador: true (default). Enemigos comunes: false (sobrescrito en obj_enemy_parent).
    // Bosses: true + default_invuln ajustado al valor deseado.
    if (invuln_on_damage) {
        is_invulnerable = true;
        invuln_timer    = default_invuln;
    }

    if (!super_armor) {
        // ── Dirección del knockback: alejarse de la fuente ──
        // Prioridad: posición relativa → facing inverso → fallback 1
        var _kdir = 0;
        if (instance_exists(_source)) {
            _kdir = sign(x - _source.x);
        }
        if (_kdir == 0) _kdir = -facing;  // fuente en la misma x → retroceder
        if (_kdir == 0) _kdir = 1;         // safety (facing puede ser 0 brevemente)

        knockback_x   = _kdir * default_knockback_x;
        move_y        = knockback_y_force;
        hitstun_timer = default_hitstun;
    }

    on_damage(_amount, _source);  // hook de reacción (sobreescribible)

    if (hp <= 0) die();           // hook de muerte (sobreescribible)
};

// on_damage: reacción al recibir daño — sobreescribir para efectos.
// _amount : cantidad de daño recibido
// _source : instancia causante (usa _source.x/y para dirección de knockback)
on_damage = function(_amount, _source) {
    // Sobreescribir en subclases:
    // → obj_player : flash de i-frames, cancelar estados de ataque, sonido de golpe
    // → enemigos   : flash de color, partículas de daño, sonido de golpe
};

// die: ejecutado cuando hp llega a 0.
die = function() {
    // Sobreescribir en subclases:
    // → obj_player : game over / respawn / animación de muerte
    // → enemigos   : drop de items, score, partículas de muerte
    // → bosses     : transición de fase
    instance_destroy();
};
