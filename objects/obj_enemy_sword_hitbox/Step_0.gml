// ══════════════════════════════════════════════════════════
// OBJ_ENEMY_SWORD_HITBOX — Step
// Sigue al enemy owner cada frame, comprueba colisión contra
// obj_player y aplica daño vía try_hit() (que respeta el
// take_damage override del jugador → block/parry interceptado).
// ══════════════════════════════════════════════════════════
if (!global.do_step) exit;

// ── Seguridad: destruir si el owner desapareció ───────────
if (!instance_exists(owner)) {
    instance_destroy();
    exit;
}

// ── Sincronizar posición con el owner ────────────────────
// Se reposiciona cada frame: correcto aunque el enemigo se mueva
// o sea empujado por knockback.
// hit_source ya apunta al owner (knockback desde el enemigo).
x = owner.x + owner.facing * hitbox_offset_x;
y = owner.y + hitbox_offset_y;

// ── Detección y daño al jugador ───────────────────────────
// Solo obj_player como target (enemies no se golpean entre sí).
// try_hit() → obj_player.take_damage() → bloque de block/parry del player.
var _x1 = x - hitbox_w * 0.5;
var _y1 = y - hitbox_h * 0.5;
var _x2 = x + hitbox_w * 0.5;
var _y2 = y + hitbox_h * 0.5;

var _found = collision_rectangle(_x1, _y1, _x2, _y2, obj_player, false, true);

// DEBUG: rastrear flujo de daño melee
if (instance_exists(owner) && owner.estate == owner.ESTATE_ATTACK_ACTIVE) {
    if (_found) {
        show_debug_message("[ENEMY-MELEE] PLAYER DETECTED: " + object_get_name(_found.object_index) + " — llamando try_hit()");
    }
}

try_hit(_found);   // noone retorna false sin crash

// ── Lifetime ──────────────────────────────────────────────
lifetime--;
if (lifetime <= 0) {
    // Notificar al owner para que limpie su referencia
    if (instance_exists(owner)) {
        owner.sword_hitbox_id = noone;
    }
    instance_destroy();   // Destroy_0 del parent limpia hit_list
}
