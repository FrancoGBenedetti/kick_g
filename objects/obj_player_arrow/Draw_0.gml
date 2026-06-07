// ── PLACEHOLDER VISUAL DE FLECHA ─────────────────────────
// Dibuja la flecha como una línea + punta orientada según
// vel_x / vel_y, mostrando correctamente cualquier ángulo.
//
// Cuando spr_player_arrow esté creado y asignado:
//   1. Eliminar este evento Draw.
//   2. Usar draw_sprite_ext(sprite_index, 0, x, y, 1, 1,
//          -point_direction(0,0,vel_x,vel_y), c_white, 1)
//      para orientar el sprite según la trayectoria.

// ── Ángulo visual a partir del vector de velocidad ────────
// point_direction: 0° = derecha | 90° = arriba | 270° = abajo
// (GML usa conv. matemática, Y negativa = arriba en pantalla)
var _vis_angle = point_direction(0, 0, vel_x, vel_y);

// ── Geometría de la flecha ────────────────────────────────
var _shaft = 10;   // semi-longitud del eje

// Extremos del eje
var _x1 = x - lengthdir_x(_shaft, _vis_angle);
var _y1 = y - lengthdir_y(_shaft, _vis_angle);
var _x2 = x + lengthdir_x(_shaft, _vis_angle);
var _y2 = y + lengthdir_y(_shaft, _vis_angle);

// Punta: dos líneas diagonales desde el extremo delantero
var _tip = 5;
var _lx = _x2 - lengthdir_x(_tip, _vis_angle - 35);
var _ly = _y2 - lengthdir_y(_tip, _vis_angle - 35);
var _rx = _x2 - lengthdir_x(_tip, _vis_angle + 35);
var _ry = _y2 - lengthdir_y(_tip, _vis_angle + 35);

// ── Dibujo ────────────────────────────────────────────────
var _prev_color = draw_get_color();

draw_set_color(c_yellow);
draw_line(_x1, _y1, _x2, _y2);   // eje
draw_line(_x2, _y2, _lx, _ly);   // punta izquierda
draw_line(_x2, _y2, _rx, _ry);   // punta derecha

draw_set_color(_prev_color);

// ── Debug overlay del parent ──────────────────────────────
// Activa el debug de obj_projectile_parent cuando:
//   F8 → global.debug_hitboxes   (vector, bbox, flags)
//   global.debug_projectiles     (toggle específico de proyectiles)
event_inherited();
