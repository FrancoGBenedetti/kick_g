// Draw — línea vertical de debug en x, visible en toda la altura del room
// (no depende de la Y del trigger — el trigger detecta cruce de X sin
// importar Y, así que el debug tampoco debería sugerir una zona limitada
// en altura). Invisible en gameplay normal si el debug está apagado.
if (!zoom_trigger_is_debug()) exit;

draw_set_alpha(0.5);
draw_set_color((trigger_once && activated) ? c_gray : c_yellow);
draw_line_width(x, 0, x, room_height, 2);

draw_set_alpha(1);
draw_set_color(c_white);
draw_set_halign(fa_center);
draw_text(x, y - 54, "CAMERA ZOOM TRIGGER" + (trigger_id != "" ? " " + trigger_id : ""));
draw_text(x, y - 40, "target: " + zoom_trigger_get_target_name() + "  mode: " + trigger_mode);
draw_text(x, y - 26, "x: " + string(round(x)));
draw_text(x, y - 12, "trigger_once=" + string(trigger_once) + "  activated=" + string(activated) + "  cooldown=" + string(cooldown_timer));
draw_text(x, y + 2,  "activated_count=" + string(activated_count) + "  last_frame=" + string(activated_frame));
draw_text(x, y + 16, "camera now: " + zoom_trigger_get_camera_current_name());
draw_set_halign(fa_left);
draw_set_color(c_white);
