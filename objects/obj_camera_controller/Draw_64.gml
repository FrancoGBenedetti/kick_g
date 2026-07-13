// ── CAMERA DEBUG HUD ─────────────────────────────────────
// F7 → toggle. Muestra tamaño actual, modo y % del player en pantalla.

if (!camera_debug_visible) exit;

var _player_visual_h = 150;
var _player_pct      = (_player_visual_h / current_camera_height) * 100;
var _lerping         = (abs(current_camera_width - target_camera_width) > 1);
var _mode_names      = ["CLOSE", "DEFAULT", "FAR"];
var _mode_sizes      = ["1344x756", "1792x1008", "2304x1296"];
var _idx             = clamp(camera_view_index, 0, 2);
var _mode_label      = _mode_names[_idx] + " (" + _mode_sizes[_idx] + ")"
                       + (_lerping ? " lerping..." : "");

var _lines = [
    "=== CAMERA (F7 ocultar) ===",
    "mode   : " + _mode_label,
    "current: " + string(round(current_camera_width)) + "x" + string(round(current_camera_height)),
    "target : " + string(round(target_camera_width))  + "x" + string(round(target_camera_height)),
    "player%: " + string_format(_player_pct, 1, 1) + "% (150px / " + string(round(current_camera_height)) + "px)",
    "cam pos: (" + string(round(cam_x)) + ", " + string(round(cam_y)) + ")",
    "room   : " + string(room_width) + "x" + string(room_height),
    "bounds : " + string(round(bounds_left)) + "," + string(round(bounds_top)) + " - " + string(round(bounds_right)) + "," + string(round(bounds_bottom))
                + (camera_bounds_override_enabled ? " [OVERRIDE]" : ""),
    "",
    "K = zoom out  |  L = zoom in",
];

draw_set_font(-1);
draw_set_halign(fa_left);
draw_set_valign(fa_top);

var _x  = 12;
var _y  = 12;
var _lh = 18;

for (var _i = 0; _i < array_length(_lines); _i++) {
    draw_set_color(c_black);
    draw_text(_x + 1, _y + 1, _lines[_i]);
    draw_set_color(c_yellow);
    draw_text(_x, _y, _lines[_i]);
    _y += _lh;
}

draw_set_color(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
