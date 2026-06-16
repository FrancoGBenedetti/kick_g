// Begin Step — corre antes del Step de cualquier objeto del mismo frame.
// Único lugar donde se toca hardware. Todo el gameplay lee global.inp.

var _kb  = global.keybinds;
var _inp = global.inp;

// ── TECLADO ───────────────────────────────────────────────
_inp.move_axis      = keyboard_check(_kb.kb_move_right) - keyboard_check(_kb.kb_move_left);
_inp.jump_pressed   = keyboard_check_pressed(_kb.kb_jump);
_inp.jump_held      = keyboard_check(_kb.kb_jump);
_inp.dash_pressed   = keyboard_check_pressed(_kb.kb_dash);
// ── Espada ────────────────────────────────────────────────
_inp.attack_pressed  = keyboard_check_pressed(_kb.kb_attack);
_inp.attack_held     = keyboard_check(_kb.kb_attack);          // held: pogo persistente

// ── Arco ──────────────────────────────────────────────────
_inp.ranged_pressed  = keyboard_check_pressed(_kb.kb_ranged);
_inp.ranged_held     = keyboard_check(_kb.kb_ranged);
_inp.ranged_released = keyboard_check_released(_kb.kb_ranged);

// ── Apuntado vertical del arco ────────────────────────────
_inp.aim_up_held   = keyboard_check(_kb.kb_aim_up);
_inp.aim_down_held = keyboard_check(_kb.kb_aim_down);

// ── Inputs direccionales one-shot (combo buffer) ──────────
// pressed = true solo en el primer frame de la pulsación.
// Independientes de move_axis (que es held continuo).
_inp.left_pressed  = keyboard_check_pressed(_kb.kb_move_left);
_inp.right_pressed = keyboard_check_pressed(_kb.kb_move_right);
_inp.up_pressed    = keyboard_check_pressed(_kb.kb_aim_up);
_inp.down_pressed  = keyboard_check_pressed(_kb.kb_aim_down);

// ── Defensa ───────────────────────────────────────────────────
_inp.block_pressed   = keyboard_check_pressed(_kb.kb_block);
_inp.block_held      = keyboard_check(_kb.kb_block);

_inp.pause_pressed   = keyboard_check_pressed(_kb.kb_pause);

// ── DEBUG TOGGLES ─────────────────────────────────────────
// F3: hitboxes y líneas de ataque de enemigos.
if (keyboard_check_pressed(vk_f3)) {
    global.debug_enemy_attacks = !global.debug_enemy_attacks;
    show_debug_message("Enemy attack debug: " + string(global.debug_enemy_attacks));
}

// F5: separación, radio de contacto y cooldown de enemigos.
if (keyboard_check_pressed(vk_f5)) {
    global.debug_enemy_collision = !variable_global_exists("debug_enemy_collision")
                                   || !global.debug_enemy_collision;
    show_debug_message("Enemy collision debug: " + string(global.debug_enemy_collision));
}

// F6: estado de IA, flags, detección y relación con el jugador.
if (keyboard_check_pressed(vk_f6)) {
    global.debug_enemy_ai = !variable_global_exists("debug_enemy_ai")
                            || !global.debug_enemy_ai;
    show_debug_message("Enemy AI debug: " + string(global.debug_enemy_ai));
}

// F7: hitbox de espada, frame de animación y estado de ataque del jugador.
if (keyboard_check_pressed(vk_f7)) {
    global.debug_attack = !variable_global_exists("debug_attack")
                          || !global.debug_attack;
    show_debug_message("Attack debug: " + string(global.debug_attack));
}

// F9: debug extendido de parry — panel completo sobre el jugador.
// (F6 está ocupado por debug_enemy_ai; F9 es la siguiente tecla libre.)
// Muestra: estado FSM, ventana, barra, success, counter window, hitboxes cercanas.
if (keyboard_check_pressed(vk_f9)) {
    global.debug_parry = !variable_global_exists("debug_parry")
                         || !global.debug_parry;
    show_debug_message("Parry debug: " + string(global.debug_parry));
}

// F10: debug de colisión del jugador — dibuja bbox, probes, wall/ground detection,
// corner correction. Requiere que obj_player tenga Draw_0 con la sección de debug.
if (keyboard_check_pressed(vk_f10)) {
    global.debug_collision = !variable_global_exists("debug_collision")
                             || !global.debug_collision;
    show_debug_message("Collision debug: " + string(global.debug_collision));
}

// F8: debug unificado de hitboxes — activa bbox/team/parry en TODAS las hitboxes.
// Cubre: espada jugador (obj_sword_hitbox), espada enemiga (obj_enemy_sword_hitbox),
// y todos los proyectiles (obj_projectile_parent → player arrow, enemy arrow).
// Usar en lugar de F3/F7 cuando se quiere ver el sistema de combate completo.
if (keyboard_check_pressed(vk_f8)) {
    global.debug_hitboxes = !variable_global_exists("debug_hitboxes")
                            || !global.debug_hitboxes;
    show_debug_message("Hitbox debug (unified): " + string(global.debug_hitboxes));
}

// ── GAMEPAD (futuro) ──────────────────────────────────────
// Para agregar gamepad: OR cada campo con los valores del gamepad.
// Ejemplo:
//   if (gamepad_is_connected(_kb.gp_slot)) {
//       var _raw = gamepad_axis_value(_kb.gp_slot, _kb.gp_move_axis);
//       var _gp_axis = abs(_raw) > _kb.gp_deadzone ? sign(_raw) : 0;
//       _inp.move_axis    = clamp(_inp.move_axis + _gp_axis, -1, 1);
//       _inp.jump_pressed = _inp.jump_pressed || gamepad_button_check_pressed(_kb.gp_slot, _kb.gp_jump);
//       _inp.jump_held    = _inp.jump_held    || gamepad_button_check(_kb.gp_slot, _kb.gp_jump);
//       _inp.dash_pressed = _inp.dash_pressed || gamepad_button_check_pressed(_kb.gp_slot, _kb.gp_dash);
//   }
