// ── GATE: respetar global.time_scale ─────────────────────
// Objetos que hereden obj_actor_parent y llamen event_inherited()
// desde dentro de una sección gated ya estarán protegidos.
// Este gate es para instancias standalone futuras (ej: enemigos).
if (!global.do_step) exit;

// ══════════════════════════════════════════════════════════
// HITSTUN & KNOCKBACK
// ══════════════════════════════════════════════════════════
// Durante hitstun:
//   • move_x es reemplazado por knockback_x (no hay control externo)
//   • knockback_x decae exponencialmente cada frame
//   • facing NO se actualiza (el actor queda mirando hacia donde miraba)
//   • el timer respeta time_scale (slow motion alarga el hitstun — correcto)
//
// Fuera de hitstun: facing se actualiza desde move_x normalmente.
if (hitstun_timer > 0) {
    move_x      = knockback_x;
    knockback_x *= knockback_decay;
    hitstun_timer--;
} else {
    // ── FACING ─────────────────────────────────────────────
    // Antes de la resolución: captura intención, no resultado.
    // (move_x puede quedar en 0 si colisiona con pared.)
    if (move_x != 0) facing = sign(move_x);
}

// ── FLIP DE SPRITE ────────────────────────────────────────
// Sincroniza image_xscale con facing SIEMPRE (dentro y fuera
// de hitstun). El sprite se mantiene orientado correctamente
// incluso cuando el knockback invierte move_x.
image_xscale = facing;

// ── GRAVEDAD ─────────────────────────────────────────────
move_y = min(move_y + grav, max_fall);

// ── COLISIÓN HORIZONTAL ───────────────────────────────────
if (move_x != 0) {
    var _hstep = sign(move_x);
    var _cy1 = y + col_top    + 1;
    var _cy2 = y + col_bottom - 1;

    repeat (abs(move_x)) {
        var _nx = x + _hstep;
        if (
            !tile_solid_at(collision_map, _nx + col_left,  _cy1) &&
            !tile_solid_at(collision_map, _nx + col_right, _cy1) &&
            !tile_solid_at(collision_map, _nx + col_left,  _cy2) &&
            !tile_solid_at(collision_map, _nx + col_right, _cy2)
        ) {
            x = _nx;
        } else {
            move_x = 0;
            break;
        }
    }
}

// ── COLISIÓN VERTICAL ─────────────────────────────────────
isGrounded = false;

if (move_y != 0) {
    var _vstep = sign(move_y);
    var _cx1 = x + col_left  + 1;
    var _cx2 = x + col_right - 1;

    repeat (ceil(abs(move_y))) {
        var _ny = y + _vstep;
        if (
            !tile_solid_at(collision_map, _cx1, _ny + col_top)    &&
            !tile_solid_at(collision_map, _cx2, _ny + col_top)    &&
            !tile_solid_at(collision_map, _cx1, _ny + col_bottom) &&
            !tile_solid_at(collision_map, _cx2, _ny + col_bottom)
        ) {
            y = _ny;
        } else {
            if (_vstep > 0) isGrounded = true;
            move_y = 0;
            break;
        }
    }
}

// ── DETECCIÓN DE PARED (desacoplada del movimiento) ───────
wallContact = false;
wallSide    = 0;

var _wcy1 = y + col_top    + 1;
var _wcy2 = y + col_bottom - 1;

var _wall_left  =
    tile_solid_at(collision_map, x + col_left  - 1, _wcy1) ||
    tile_solid_at(collision_map, x + col_left  - 1, _wcy2);

var _wall_right =
    tile_solid_at(collision_map, x + col_right + 1, _wcy1) ||
    tile_solid_at(collision_map, x + col_right + 1, _wcy2);

if (_wall_left || _wall_right) {
    wallContact = true;
    if (_wall_left && _wall_right) {
        wallSide = -facing;
    } else {
        wallSide = _wall_right ? 1 : -1;
    }
}

// ── ESTADOS FÍSICOS DERIVADOS ─────────────────────────────
isJumping = (move_y < 0);
isFalling = (move_y > 0 && !isGrounded);

// ── COYOTE TIME ───────────────────────────────────────────
// Transición suelo→aire sin saltar: abre la ventana coyote.
// !isJumping garantiza que el salto propio no la dispare.
if (prev_grounded && !isGrounded && !isJumping) {
    coyoteTimer = coyote_max;
}
if (coyoteTimer > 0) coyoteTimer--;

prev_grounded = isGrounded;

// ── I-FRAMES ─────────────────────────────────────────────
// Corre en la sección gated: el timer respeta global.time_scale.
// Durante slow motion los i-frames duran más en tiempo real (correcto).
if (invuln_timer > 0) {
    invuln_timer--;
    if (invuln_timer == 0) {
        is_invulnerable = false;
    }
}
