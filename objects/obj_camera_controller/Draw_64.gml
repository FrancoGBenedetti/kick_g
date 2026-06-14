// ── CAMERA DEBUG HUD ─────────────────────────────────────
// Visible en pantalla mientras camera_debug_visible = true.
// Activar/desactivar con F7 en Step_0.
// Quitar en producción: borrar este evento o setear camera_debug_visible = false.

if (!camera_debug_visible) exit;

var _player_visual_h = 150;   // px visual del sprite 256×256
var _zoom_factor     = current_camera_height / base_camera_height;
var _player_pct      = (_player_visual_h / current_camera_height) * 100;
var _scale_x         = display_get_width()  / current_camera_width;
var _scale_y         = display_get_height() / current_camera_height;

// Determinar modo de zoom para el label
var _mode = "CUSTOM";
var _tgt_factor = target_camera_height / base_camera_height;
if (abs(_tgt_factor - gameplay_zoom_factor) < 0.01) _mode = "NORMAL";
else if (_tgt_factor < gameplay_zoom_factor)         _mode = "ZOOM IN";
else                                                 _mode = "ZOOM OUT";

var _lines = [
    "=== CAMERA DEBUG (F7 para ocultar) ===",
    "view current : " + string(round(current_camera_width)) + "x" + string(round(current_camera_height)),
    "view target  : " + string(round(target_camera_width))  + "x" + string(round(target_camera_height)),
    "zoom factor  : x" + string_format(_zoom_factor, 1, 3),
    "zoom mode    : " + _mode,
    "player ~150px: " + string_format(_player_pct, 1, 1) + "% de pantalla",
    "cam pos      : (" + string(round(cam_x)) + ", " + string(round(cam_y)) + ")",
    "room size    : " + string(room_width) + "x" + string(room_height),
    "port         : " + string(DISPLAY_W) + "x" + string(DISPLAY_H),
    "px/world px  : " + string_format(_scale_x, 1, 2) + "x",
    "",
    "J=960x540  K=1440x810  L=1920x1080(normal)  ;=2400x1350",
];

draw_set_font(-1);
draw_set_halign(fa_left);
draw_set_valign(fa_top);

var _x = 12;
var _y = 12;
var _lh = 18;

for (var _i = 0; _i < array_length(_lines); _i++) {
    // sombra
    draw_set_color(c_black);
    draw_text(_x + 1, _y + 1, _lines[_i]);
    // texto
    draw_set_color(c_yellow);
    draw_text(_x, _y, _lines[_i]);
    _y += _lh;
}

draw_set_color(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
