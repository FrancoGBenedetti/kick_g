// ── KEY BINDINGS ──────────────────────────────────────────
// Punto único de remapeo. Para cambiar una tecla: modificar aquí.
// Para cargar bindings de un archivo de config: sobrescribir este struct al cargar.
global.keybinds = {

    // Teclado
    kb_move_left:  vk_left,
    kb_move_right: vk_right,
    kb_jump:       vk_space,
    kb_dash:       vk_shift,
    kb_attack:     ord("Z"),     // espada — ataque cuerpo a cuerpo
    kb_ranged:     ord("X"),     // arco   — ataque a distancia
    kb_aim_up:     vk_up,        // arco — ángulo arriba (mientras se carga)
    kb_aim_down:   vk_down,      // arco — ángulo abajo  (mientras se carga)
    kb_block:      ord("C"),        // defensa / parry
    kb_pause:      vk_escape,

    // Gamepad (slot 0 — primer control conectado)
    gp_slot:       0,
    gp_move_axis:  gp_axislh,   // stick izquierdo horizontal
    gp_move_left:  gp_padl,     // D-pad izquierda
    gp_move_right: gp_padr,     // D-pad derecha
    gp_aim_axis:   gp_axisrv,   // stick derecho vertical
    gp_aim_up:     gp_padu,     // D-pad arriba
    gp_aim_down:   gp_padd,     // D-pad abajo
    gp_jump:       gp_face1,    // A / Cruz
    gp_dash:       gp_face3,    // X / Cuadrado
    gp_attack:     gp_face2,    // B / Círculo  — espada
    gp_ranged:     gp_shoulderr, // RB / R1 — arco
    gp_block:      gp_shoulderl, // LB / L1 — defensa / parry
    gp_pause:      gp_start,

    // Deadzone para ejes analógicos
    gp_deadzone:   0.25,
};

// ── ESTADO DE INPUT (frame actual) ────────────────────────
// Consumido por obj_player y cualquier sistema de gameplay.
// Poblado cada Begin Step por este mismo objeto.
global.inp = {

    move_axis:      0,      // -1 izq | 0 neutro | +1 der

    jump_pressed:   false,  // true solo en el frame que se presiona
    jump_held:      false,  // true mientras esté sostenido

    dash_pressed:     false,

    // ── Espada (Z / gp_attack) ────────────────────────────
    attack_pressed:   false,  // one-shot: primer frame que se presiona
    attack_held:      false,  // held:     true mientras el botón esté sostenido

    // ── Arco / distancia (X / gp_ranged) ──────────────────
    ranged_pressed:   false,  // one-shot: inicio de carga
    ranged_held:      false,  // held:     acumulación de carga
    ranged_released:  false,  // one-shot: disparo al soltar

    // ── Apuntado vertical del arco ────────────────────────
    // Activo solo mientras se mantiene cargado el arco.
    // Mapeado a ↑/↓ (teclado), D-pad o stick derecho vertical.
    aim_up_held:      false,
    aim_down_held:    false,

    // ── Inputs direccionales one-shot ─────────────────────
    // Usados por el buffer de combos (scr_combo_buffer).
    // Solo true en el PRIMER frame que se presiona la tecla.
    // No equivalen a move_axis (que es held continuo).
    left_pressed:     false,
    right_pressed:    false,
    up_pressed:       false,   // misma tecla que aim_up pero one-shot
    down_pressed:     false,   // misma tecla que aim_down pero one-shot

    // ── Defensa (C) ───────────────────────────────────────
    block_pressed:    false,  // one-shot: primer frame de block/parry
    block_held:       false,  // held:     manteniendo el botón de block

    pause_pressed:    false,
};

// Estado previo de ejes digitales/analógicos para detectar presses one-shot.
gp_prev_move_axis = 0;
gp_prev_aim_axis  = 0;
