// Begin Step corre antes del Step de cualquier objeto.
// obj_player siempre lee global.inp ya actualizado.

var _kb = global.keybinds;
var _inp = global.inp;

// ── TECLADO ───────────────────────────────────────────────
var _k_axis    = keyboard_check(_kb.kb_move_right) - keyboard_check(_kb.kb_move_left);
var _k_jump_p  = keyboard_check_pressed(_kb.kb_jump);
var _k_jump_h  = keyboard_check(_kb.kb_jump);
var _k_dash_p  = keyboard_check_pressed(_kb.kb_dash);
var _k_attack  = keyboard_check_pressed(_kb.kb_attack);
var _k_pause   = keyboard_check_pressed(_kb.kb_pause);

// ── GAMEPAD ───────────────────────────────────────────────
// Si no hay gamepad conectado, todos los valores son 0/false.
// Agregar más slots o Joy-Cons: duplicar este bloque con _kb.gp_slot_2, etc.
var _gp_axis   = 0;
var _gp_jump_p = false;
var _gp_jump_h = false;
var _gp_dash_p = false;
var _gp_attack = false;
var _gp_pause  = false;

if (gamepad_is_connected(_kb.gp_slot)) {
    var _raw = gamepad_axis_value(_kb.gp_slot, _kb.gp_move_axis);
    _gp_axis   = abs(_raw) > _kb.gp_deadzone ? sign(_raw) : 0;
    _gp_jump_p = gamepad_button_check_pressed(_kb.gp_slot, _kb.gp_jump);
    _gp_jump_h = gamepad_button_check(_kb.gp_slot, _kb.gp_jump);
    _gp_dash_p = gamepad_button_check_pressed(_kb.gp_slot, _kb.gp_dash);
    _gp_attack = gamepad_button_check_pressed(_kb.gp_slot, _kb.gp_attack);
    _gp_pause  = gamepad_button_check_pressed(_kb.gp_slot, _kb.gp_pause);
}

// ── MERGE → global.inp ───────────────────────────────────
// Teclado y gamepad conviven: cualquiera de los dos activa la acción.
_inp.move_axis      = clamp(_k_axis + _gp_axis, -1, 1);
_inp.jump_pressed   = _k_jump_p  || _gp_jump_p;
_inp.jump_held      = _k_jump_h  || _gp_jump_h;
_inp.dash_pressed   = _k_dash_p  || _gp_dash_p;
_inp.attack_pressed = _k_attack  || _gp_attack;
_inp.pause_pressed  = _k_pause   || _gp_pause;
