// ══════════════════════════════════════════════════════════
// scr_enemy_get_attack_rect(_enemy_id)
// Calcula el rectángulo de ataque (hitbox) para un enemigo.
//
// Parámetros:
//   _enemy_id: instancia del enemigo (obj_enemy_swordsman, etc.)
//
// Retorna: struct {left, top, right, bottom}
//
// El rectángulo se centra en el origen del enemigo y se
// extiende según:
//   - enemy_attack_reach: ancho horizontal
//   - enemy_attack_height: alto vertical
//   - enemy_attack_offset_y: desplazamiento vertical
//   - facing: dirección del enemigo
//
// Ejemplo de uso:
//   var _rect = scr_enemy_get_attack_rect(id);
//   if (collision_rectangle(_rect.left, _rect.top,
//                           _rect.right, _rect.bottom,
//                           obj_player, false, true)) {
//       // player está dentro del hitbox
//   }
// ══════════════════════════════════════════════════════════

function scr_enemy_get_attack_rect(_enemy_id) {
    if (!instance_exists(_enemy_id)) {
        return {
            left: 0, top: 0, right: 0, bottom: 0
        };
    }

    var _e = _enemy_id;
    var _reach = _e.enemy_attack_reach;
    var _height = _e.enemy_attack_height;
    var _offset_y = _e.enemy_attack_offset_y;

    // ── Centro vertical del hitbox ────────────────────────
    var _center_y = _e.y + _offset_y;
    var _half_height = _height * 0.5;

    // ── Horizontal según facing ───────────────────────────
    var _left, _right;
    if (_e.facing >= 0) {
        // Mirando derecha: [x, x + reach]
        _left = _e.x;
        _right = _e.x + _reach;
    } else {
        // Mirando izquierda: [x - reach, x]
        _left = _e.x - _reach;
        _right = _e.x;
    }

    return {
        left: _left,
        top: _center_y - _half_height,
        right: _right,
        bottom: _center_y + _half_height
    };
}
