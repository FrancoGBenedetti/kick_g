// Draw — visual de debug del gate. El sprite guía (spr_battleroom_gate_debug)
// solo sirve para posicionar/escalar en el Room Editor (visible=false en
// Create), así que acá se dibuja el rectángulo de colisión REAL
// (dynamic_solid_xoff/yoff/w/h) — coincide exactamente con lo que bloquea.
// Si el debug está apagado no dibuja nada, ni siquiera si el gate está
// activo (misma convención que obj_battleroom_wall).
if (!gate_is_debug()) exit;

var _x1 = x + dynamic_solid_xoff;
var _y1 = y + dynamic_solid_yoff;
var _x2 = _x1 + dynamic_solid_w;
var _y2 = _y1 + dynamic_solid_h;

draw_set_color(gate_enabled ? c_red : c_aqua);
draw_set_alpha(gate_enabled ? 0.35 : 0.15);
draw_rectangle(_x1, _y1, _x2, _y2, false);

draw_set_alpha(0.9);
draw_rectangle(_x1, _y1, _x2, _y2, true);

draw_set_alpha(1);
draw_set_color(c_white);
draw_set_halign(fa_center);
draw_text(x + dynamic_solid_w * 0.5, _y1 - 28, gate_id);
draw_text(x + dynamic_solid_w * 0.5, _y1 - 14, "encounter: " + encounter_id);
draw_text(x + dynamic_solid_w * 0.5, _y2 + 4, "enabled=" + string(gate_enabled) + "  solid=" + string(dynamic_solid_enabled));
draw_set_halign(fa_left);
draw_set_color(c_white);
