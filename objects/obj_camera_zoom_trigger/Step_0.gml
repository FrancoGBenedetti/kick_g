// Step — detección de cruce de X (no colisión). No importa la Y del
// player. Usa last_player_x (seguido a mano, actualizado al final de este
// mismo Step) en vez de xprevious — más explícito y fácil de loguear.
if (!enabled) exit;
if (trigger_once && activated) exit;

if (cooldown_timer > 0) {
    cooldown_timer--;
    if (zoom_trigger_is_debug() && (cooldown_timer mod 5 == 0)) {
        show_debug_message("[CAMERA ZOOM TRIGGER] " + trigger_id + " cooldown = " + string(cooldown_timer));
    }
    exit;   // sigue enfriando — no chequear cruce este frame
}

if (!instance_exists(obj_player)) exit;

var _player = instance_find(obj_player, 0);
var _curr_x = _player.x;

// Primer frame que ve al player: solo inicializar, no evaluar cruce
// (todavía no hay un "prev" real con el que comparar).
if (last_player_x <= -99999) {
    last_player_x = _curr_x;
    exit;
}

var _prev_x  = last_player_x;
var _crossed = (_prev_x < x && _curr_x >= x) || (_prev_x > x && _curr_x <= x);

// Debug de proximidad: solo cuando el player está cerca (evita spamear la
// consola con los 7+ triggers de la room a la vez todo el tiempo), y
// rate-limiteado a 1 de cada 20 frames mientras está en rango.
var _near = abs(_curr_x - x) <= 400;
if (_near && zoom_trigger_is_debug() && (current_time mod 333 < 17)) {
    show_debug_message("[CAMERA ZOOM TRIGGER] id/name = " + trigger_id);
    show_debug_message("[CAMERA ZOOM TRIGGER] target zoom = " + zoom_trigger_get_target_name());
    show_debug_message("[CAMERA ZOOM TRIGGER] mode = " + trigger_mode);
    show_debug_message("[CAMERA ZOOM TRIGGER] trigger x = " + string(round(x)));
    show_debug_message("[CAMERA ZOOM TRIGGER] player prev x = " + string(round(_prev_x)));
    show_debug_message("[CAMERA ZOOM TRIGGER] player current x = " + string(round(_curr_x)));
    show_debug_message("[CAMERA ZOOM TRIGGER] crossed = " + string(_crossed));
}

if (_crossed) {
    if (zoom_trigger_is_debug()) {
        show_debug_message("[CAMERA ZOOM TRIGGER] id/name = " + trigger_id);
        show_debug_message("[CAMERA ZOOM TRIGGER] target zoom = " + zoom_trigger_get_target_name());
        show_debug_message("[CAMERA ZOOM TRIGGER] mode = " + trigger_mode);
        show_debug_message("[CAMERA ZOOM TRIGGER] trigger x = " + string(round(x)));
        show_debug_message("[CAMERA ZOOM TRIGGER] player prev x = " + string(round(_prev_x)));
        show_debug_message("[CAMERA ZOOM TRIGGER] player current x = " + string(round(_curr_x)));
        show_debug_message("[CAMERA ZOOM TRIGGER] crossed = true");
    }
    camera_zoom_trigger_activate();   // ya loguea "applying zoom" + "camera current zoom after"
}

last_player_x = _curr_x;
