// ══════════════════════════════════════════════════════════
// OBJ_SWORD_HITBOX — Step
// Gated por do_step: respeta time_scale igual que el player
// (ventana de daño correcta durante slow motion / hit stop).
// ══════════════════════════════════════════════════════════
if (!global.do_step) exit;

// ── Seguridad: destruir si el owner desapareció ───────────
if (!instance_exists(owner)) {
    instance_destroy();   // Destroy event limpia hit_list automáticamente
    exit;
}

// ── Sincronizar hit_source ────────────────────────────────
// hit_source = owner garantiza que el knockback apunte DESDE
// el jugador y no desde la hitbox desplazada.
// Ejemplo: jugador en x=100, hitbox en x=120, enemigo en x=115.
//   Con hit_source=owner:  sign(115 - 100) = +1 (alejarse del jugador) ✓
//   Con hit_source=id:     sign(115 - 120) = -1 (hacia el jugador)     ✗
hit_source = owner;

// ── Seguir al owner ───────────────────────────────────────
// Se reposiciona cada frame — correcto incluso en movimiento
// rápido (dash durante ataque, knockback, etc.)
x = owner.x + owner.facing * hitbox_offset_x;
y = owner.y + hitbox_offset_y;

// ── Detección y aplicación de daño ────────────────────────
// collision_rectangle_list: puede golpear MÚLTIPLES enemigos
// en el mismo frame (área de efecto del swing).
// try_hit() maneja owner-exclusion y anti-multi-hit internamente.
var _x1 = x - hitbox_w * 0.5;
var _y1 = y - hitbox_h * 0.5;
var _x2 = x + hitbox_w * 0.5;
var _y2 = y + hitbox_h * 0.5;

var _temp = ds_list_create();
var _count = collision_rectangle_list(_x1, _y1, _x2, _y2,
                                      obj_actor_parent, false, true,
                                      _temp, false);
for (var _i = 0; _i < _count; _i++) {
    try_hit(_temp[| _i]);
}
ds_list_destroy(_temp);

// ── Lifetime ──────────────────────────────────────────────
lifetime--;
if (lifetime <= 0) {
    // Notificar al owner antes de destruirse para que actualice
    // su referencia. La limpieza de hit_list la hace Destroy_0.
    if (instance_exists(owner)) {
        owner.sword_hitbox_id = noone;
    }
    instance_destroy();
}
