// ══════════════════════════════════════════════════════════
// scr_combo_buffer — Buffer de inputs recientes para combos
// ══════════════════════════════════════════════════════════
// Propósito: registrar qué inputs se presionaron "hace poco".
// Cada timer funciona como un "eco" del input:
//   → Se pone en combo_buffer_window al presionar.
//   → Baja 1 por gated-frame (respeta time_scale via slowmo).
//   → En 0 = ese input fue "olvidado".
//
// Uso desde obj_player/Step_0.gml (sección gated, zona de timers):
//   update_combo_input_buffer();
//
// Uso FUTURO para detectar combos:
//   if (was_recent_sword() && was_recent_back()) {
//       player_set_state(PSTATE.DASH_SLASH);   // ejemplo
//   }
//
// IMPORTANTE: Estas funciones NO ejecutan ningún combo.
// Solo mantienen el registro para que una futura sección
// de combos pueda leer el historial de inputs.
//
// Variables de instancia necesarias en el jugador (Create_0.gml):
//   combo_buffer_window    — ventana en frames
//   recent_sword_timer, recent_bow_timer, recent_dash_timer
//   recent_jump_timer,  recent_back_timer, recent_forward_timer
//   recent_down_timer,  recent_up_timer
//
// Inputs one-shot en global.inp (obj_input/Create_0.gml):
//   left_pressed, right_pressed, up_pressed, down_pressed
// ══════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────
/// @func   update_combo_input_buffer()
/// @desc   Actualiza todos los timers del buffer de inputs.
///         Llamar UNA VEZ por gated-frame, después de que el
///         input del frame ya está disponible en global.inp.
///         Opera sobre las variables de instancia del llamador.
// ─────────────────────────────────────────────────────────
function update_combo_input_buffer() {

    // ── Decrementar timers (mínimo 0) ──────────────────────
    if (recent_sword_timer   > 0) recent_sword_timer--;
    if (recent_bow_timer     > 0) recent_bow_timer--;
    if (recent_dash_timer    > 0) recent_dash_timer--;
    if (recent_jump_timer    > 0) recent_jump_timer--;
    if (recent_back_timer    > 0) recent_back_timer--;
    if (recent_forward_timer > 0) recent_forward_timer--;
    if (recent_down_timer    > 0) recent_down_timer--;
    if (recent_up_timer      > 0) recent_up_timer--;

    // ── Registrar inputs de este frame ─────────────────────
    // Botones de acción — activados en el frame exacto del press.
    if (global.inp.attack_pressed) recent_sword_timer = combo_buffer_window;
    if (global.inp.ranged_pressed) recent_bow_timer   = combo_buffer_window;
    if (global.inp.dash_pressed)   recent_dash_timer  = combo_buffer_window;
    if (global.inp.jump_pressed)   recent_jump_timer  = combo_buffer_window;

    // Direcciones verticales (one-shot press, no held).
    if (global.inp.up_pressed)   recent_up_timer   = combo_buffer_window;
    if (global.inp.down_pressed) recent_down_timer = combo_buffer_window;

    // ── Direcciones horizontales relativas al facing ───────
    // "Adelante" = dirección hacia la que el jugador mira.
    // "Atrás"    = dirección contraria.
    //
    // Usa pressed (one-shot) para distinguir "empujé en esta dirección"
    // de "sigo sosteniendo" — relevante para inputs como ← → o → ←.
    if (global.inp.left_pressed || global.inp.right_pressed) {
        var _raw = global.inp.right_pressed ? 1 : -1;
        if (sign(_raw) == sign(facing)) {
            recent_forward_timer = combo_buffer_window;
        } else {
            recent_back_timer = combo_buffer_window;
        }
    }
}


// ─────────────────────────────────────────────────────────
// Queries — helpers para uso futuro en detección de combos
// ─────────────────────────────────────────────────────────

/// @func   was_recent_sword()
/// @returns {bool}  true si Z (ataque espada) fue presionado
///                  dentro de la ventana combo_buffer_window.
function was_recent_sword()   { return (recent_sword_timer   > 0); }

/// @func   was_recent_bow()
/// @returns {bool}  true si X (arco) fue presionado dentro de la ventana.
function was_recent_bow()     { return (recent_bow_timer     > 0); }

/// @func   was_recent_dash()
/// @returns {bool}  true si Shift (dash) fue presionado dentro de la ventana.
function was_recent_dash()    { return (recent_dash_timer    > 0); }

/// @func   was_recent_jump()
/// @returns {bool}  true si Space (salto) fue presionado dentro de la ventana.
function was_recent_jump()    { return (recent_jump_timer    > 0); }

/// @func   was_recent_forward()
/// @desc   "Adelante" es la dirección hacia la que el jugador mira (facing).
///         Si el jugador mira a la derecha y presionó ←, eso es "atrás".
/// @returns {bool}
function was_recent_forward() { return (recent_forward_timer > 0); }

/// @func   was_recent_back()
/// @desc   "Atrás" es la dirección OPUESTA al facing actual del jugador.
/// @returns {bool}
function was_recent_back()    { return (recent_back_timer    > 0); }

/// @func   was_recent_down()
/// @returns {bool}  true si ↓ fue presionado dentro de la ventana.
function was_recent_down()    { return (recent_down_timer    > 0); }

/// @func   was_recent_up()
/// @returns {bool}  true si ↑ fue presionado dentro de la ventana.
function was_recent_up()      { return (recent_up_timer      > 0); }
