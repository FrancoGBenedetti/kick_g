// Begin Step — corre antes del Step de cualquier objeto del mismo frame.
// Único lugar donde se toca hardware. Todo el gameplay lee global.inp.

var _kb  = global.keybinds;
var _inp = global.inp;

if (!instance_exists(obj_pause_menu) && room != RoomStartMenu) {
    instance_create_depth(0, 0, -100000, obj_pause_menu);
}

var _keyboard = scr_input_read_keyboard(_kb);
var _gamepad  = scr_input_read_gamepad(_kb, gp_prev_move_axis, gp_prev_aim_axis);

scr_input_apply(_inp, _keyboard, _gamepad);

gp_prev_move_axis = _gamepad.next_move_axis;
gp_prev_aim_axis  = _gamepad.next_aim_axis;

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

// F11: debug del afterimage/ghost trail del dash — muestra alpha por copia
// sobre cada instancia de obj_dash_afterimage y loguea cada spawn en consola.
if (keyboard_check_pressed(vk_f11)) {
    global.debug_dash_afterimage = !variable_global_exists("debug_dash_afterimage")
                                   || !global.debug_dash_afterimage;
    show_debug_message("Dash afterimage debug: " + string(global.debug_dash_afterimage));
}
