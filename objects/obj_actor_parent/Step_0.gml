// ── GATE: respetar global.time_scale ─────────────────────
if (!global.do_step) exit;

// ══════════════════════════════════════════════════════════
// HITSTUN & KNOCKBACK
// ══════════════════════════════════════════════════════════
if (hitstun_timer > 0) {
    move_x      = knockback_x;
    knockback_x *= knockback_decay;
    hitstun_timer--;
} else {
    if (move_x != 0) facing = sign(move_x);
}

image_xscale = facing;

// ── GRAVEDAD ─────────────────────────────────────────────
move_y = min(move_y + grav, max_fall);

// ══════════════════════════════════════════════════════════
// CONSTANTE DE MUESTREO
// ══════════════════════════════════════════════════════════
// Debe ser ESTRICTAMENTE MENOR que el tile de colisión (32px).
// Con 28px de paso, ningún tile de 32px puede "colarse" entre
// dos puntos de prueba consecutivos.
// Si el tile size cambia, actualizar esta constante.
var _PROBE_STEP = 28;

// ══════════════════════════════════════════════════════════
// COLISIÓN HORIZONTAL
// ══════════════════════════════════════════════════════════
// Resolución pixel a pixel con muestreo completo de la altura
// del hitbox en pasos de _PROBE_STEP.
//
// PROBLEMA ANTERIOR: solo se chequeaban 2 probes (col_top+1 y
// col_bottom-1), dejando un gap de ~138px — tiles de 32px en
// la zona media del cuerpo eran completamente ignorados.
//
// SOLUCIÓN: escanear desde col_top+1 hasta col_bottom-1 en pasos
// de 28px, garantizando cobertura total contra tiles de ≥29px.
if (move_x != 0) {
    var _hdir   = sign(move_x);
    var _py_top = y + col_top    + 1;
    var _py_bot = y + col_bottom - 1;

    repeat (abs(move_x)) {
        var _nx      = x + _hdir;
        var _blocked = false;
        var _py      = _py_top;

        // Escanear altura completa
        while (_py <= _py_bot) {
            if (tile_solid_at(collision_map, _nx + col_left,  _py) ||
                tile_solid_at(collision_map, _nx + col_right, _py)) {
                _blocked = true;
                break;
            }
            // Avanzar al siguiente probe; siempre terminar en _py_bot
            _py = (_py >= _py_bot) ? _py_bot + 1 : min(_py + _PROBE_STEP, _py_bot);
        }

        if (!_blocked) {
            x = _nx;
        } else {
            move_x = 0;
            break;
        }
    }
}

// ══════════════════════════════════════════════════════════
// COLISIÓN VERTICAL
// ══════════════════════════════════════════════════════════
// Tres probes X: izquierda, CENTRO, derecha.
//
// PROBLEMA ANTERIOR: solo izq (col_left+1) y der (col_right-1).
// Con hitbox de 56px y tiles de 32px, el gap de 54px entre probes
// podía dejar pasar un tile centrado debajo del jugador.
//
// SOLUCIÓN: agregar probe central en x+0 — gap máximo ahora ≤27px.
isGrounded = false;
var _pre_vy = move_y;   // guardar antes de resolución (para corner correction)

if (move_y != 0) {
    var _vdir = sign(move_y);
    var _cx_l = x + col_left  + 1;
    var _cx_m = x;                    // probe central — NUEVO
    var _cx_r = x + col_right - 1;

    repeat (ceil(abs(move_y))) {
        var _ny      = y + _vdir;
        var _check_y = _ny + (_vdir > 0 ? col_bottom : col_top);

        if (!tile_solid_at(collision_map, _cx_l, _check_y) &&
            !tile_solid_at(collision_map, _cx_m, _check_y) &&
            !tile_solid_at(collision_map, _cx_r, _check_y)) {
            y = _ny;
        } else {
            if (_vdir > 0) isGrounded = true;
            move_y = 0;
            break;
        }
    }
}

// ══════════════════════════════════════════════════════════
// CORNER CORRECTION (techo)
// ══════════════════════════════════════════════════════════
// Cuando el jugador salta y roza el borde de un tile con la esquina
// del hitbox, lo deslizamos lateralmente hasta despegar la esquina
// en lugar de frenar en seco.
//
// Solo aplica al ir hacia ARRIBA (_pre_vy < 0) y solo si fue frenado
// por el techo (move_y pasó a 0 desde un valor negativo).
//
// Ajustar CC_MAX:
//   4  = muy conservador (solo roce puro de 1-4px)
//   8  = estándar (estilo Hollow Knight / MMX)   ← default
//   12 = muy permisivo (puede sorprender al jugador)
var CC_MAX = 8;
corner_corrected = false;   // flag de debug: true en el frame que corrige

if (_pre_vy < 0 && move_y == 0) {
    var _ceil_check_y = y + col_top;   // línea de techo a verificar
    var _fixed        = false;

    // Intentar derecha primero, luego izquierda
    for (var _cc_dir = 0; _cc_dir < 2 && !_fixed; _cc_dir++) {
        var _cc_sign = (_cc_dir == 0) ? 1 : -1;

        for (var _cc_i = 1; _cc_i <= CC_MAX && !_fixed; _cc_i++) {
            var _tx = x + _cc_i * _cc_sign;

            // ¿Está el techo despejado en esta nueva X?
            var _ceil_ok =
                !tile_solid_at(collision_map, _tx + col_left  + 1, _ceil_check_y) &&
                !tile_solid_at(collision_map, _tx,                  _ceil_check_y) &&
                !tile_solid_at(collision_map, _tx + col_right - 1, _ceil_check_y);

            if (_ceil_ok) {
                // Verificar que moverse a _tx no meta al jugador en una pared
                var _wall_ok = true;
                var _scan_y  = y + col_top + 1;
                while (_scan_y <= y + col_bottom - 1) {
                    if (tile_solid_at(collision_map, _tx + col_left,  _scan_y) ||
                        tile_solid_at(collision_map, _tx + col_right, _scan_y)) {
                        _wall_ok = false;
                        break;
                    }
                    _scan_y = (_scan_y >= y + col_bottom - 1)
                              ? y + col_bottom
                              : min(_scan_y + _PROBE_STEP, y + col_bottom - 1);
                }

                if (_wall_ok) {
                    x             = _tx;
                    move_y        = _pre_vy;   // restaurar impulso vertical
                    corner_corrected = true;
                    _fixed        = true;
                }
            }
        }
    }
}

// ══════════════════════════════════════════════════════════
// DETECCIÓN DE PARED (desacoplada del movimiento)
// ══════════════════════════════════════════════════════════
// Mismo muestreo completo que colisión horizontal.
// PROBLEMA ANTERIOR: solo col_top+1 y col_bottom-1 → tiles en la
// zona media del cuerpo no disparaban wallContact.
// SOLUCIÓN: escanear altura completa con el mismo _PROBE_STEP.
wallContact = false;
wallSide    = 0;

var _wpy_top = y + col_top    + 1;
var _wpy_bot = y + col_bottom - 1;
var _wall_l  = false;
var _wall_r  = false;

var _wpy = _wpy_top;
while (_wpy <= _wpy_bot) {
    if (!_wall_l && tile_solid_at(collision_map, x + col_left  - 1, _wpy)) _wall_l = true;
    if (!_wall_r && tile_solid_at(collision_map, x + col_right + 1, _wpy)) _wall_r = true;
    if (_wall_l && _wall_r) break;
    _wpy = (_wpy >= _wpy_bot) ? _wpy_bot + 1 : min(_wpy + _PROBE_STEP, _wpy_bot);
}

if (_wall_l || _wall_r) {
    wallContact = true;
    if (_wall_l && _wall_r) {
        wallSide = -facing;
    } else {
        wallSide = _wall_r ? 1 : -1;
    }
}

// ── ESTADOS FÍSICOS DERIVADOS ─────────────────────────────
isJumping = (move_y < 0);
isFalling = (move_y > 0 && !isGrounded);

// ── COYOTE TIME ───────────────────────────────────────────
if (prev_grounded && !isGrounded && !isJumping) {
    coyoteTimer = coyote_max;
}
if (coyoteTimer > 0) coyoteTimer--;
prev_grounded = isGrounded;

// ── I-FRAMES ─────────────────────────────────────────────
if (invuln_timer > 0) {
    invuln_timer--;
    if (invuln_timer == 0) is_invulnerable = false;
}
