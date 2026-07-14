if (variable_global_exists("game_paused") && global.game_paused) exit;

// F8 → toggle debug HUD de movimiento en pantalla
if (keyboard_check_pressed(vk_f8)) {
    player_debug_visible = !player_debug_visible;
}

// ── MUERTE POR CAÍDA ──────────────────────────────────────
// Corre antes de todo — incluso antes del control de time_scale.
// is_dead evita que room_restart() se llame dos veces si el Step
// se ejecuta más de una vez antes de que el room se reinicie.
if (!is_dead && y > room_height + 200) {
    show_debug_message("[DBG] PLAYER DIED - FALL  y=" + string(y)
        + "  room_h=" + string(room_height));
    hp = 0;
    die();
    exit;
}

// ══════════════════════════════════════════════════════════
// INPUT-ONLY LOCK — neutraliza global.inp ANTES de que se lea
// ══════════════════════════════════════════════════════════
// obj_player es el único consumidor de global.inp en el proyecto, así que
// alcanza con pisar estos campos acá una vez por frame — no hace falta
// tocar cada punto de lectura suelto más abajo (block/ataque/arco/dash/
// salto/mover). NO se toca velocidad, estado, gravedad ni timers: si el
// player venía cayendo, dasheando o rolleando, sigue igual (esas ramas del
// state machine usan estado ya existente, no input fresco — ver DASH/
// roll_active más abajo). Dos lecturas de teclado crudas (roll, línea con
// keyboard_check_pressed(ord("A"))) están fuera de global.inp y se
// bloquean aparte, en su propio punto.
if (input_only_lock) {
    global.inp.move_axis      = 0;
    global.inp.jump_pressed   = false;
    global.inp.dash_pressed   = false;
    global.inp.attack_pressed = false;
    global.inp.ranged_pressed = false;
    global.inp.ranged_held    = false;
    global.inp.ranged_released = false;
    global.inp.block_pressed  = false;
    global.inp.block_held     = false;
    global.inp.aim_up_held    = false;
    global.inp.aim_down_held  = false;
}

// ══════════════════════════════════════════════════════════
// SECCIÓN ALWAYS — corre cada real-frame (60fps constantes)
// Solo eventos one-shot que no pueden perderse en frame-skips
// y control del time_scale.
// ══════════════════════════════════════════════════════════

// ── Bloqueo mutuo espada / arco / dash ────────────────────
// Declarado al inicio de la sección always para proteger TANTO el buffer
// de ataque como el inicio de carga del arco. Las vars tienen scope de
// evento completo en GML → accesibles también en la sección gated.
//
//   _sword_busy: true si cualquier ataque con espada está activo
//   _bow_busy  : true mientras bow_is_charging (cargando O release pendiente)
//
// Reglas:
//   • Z presionado durante arco → ignorado (attack_buffer no se activa)
//   • X presionado durante espada → ignorado (arco no comienza)
//   • _can_attack en gated también requiere !_bow_busy como defensa extra
//   • Dash bloqueado durante arco (_bow_busy en condición de dash)
//   • Movimiento horizontal bloqueado durante arco (rama bow_is_charging en vel_x)
var _sword_busy = (player_state == PSTATE.ATTACK_1
                || player_state == PSTATE.ATTACK_2
                || player_state == PSTATE.ATTACK_3
                || player_state == PSTATE.DOWN_SLASH
                || player_state == PSTATE.DASH_ATTACK
                || player_state == PSTATE.COUNTER_ATTACK);
var _bow_busy   = bow_is_charging;   // cubre carga + pending-release
var _block_busy = (player_state == PSTATE.BLOCK);

var _dir       = global.inp.move_axis;
// Bloquear input horizontal durante Roll
if (roll_active) {
    _dir = 0;
}
var _want_jump = global.inp.jump_pressed;
var _want_dash = global.inp.dash_pressed;

// ── BLOCK: inicio ─────────────────────────────────────────
// Bloqueado durante ataque activo, arco, dash y cooldown post-parry.
// Solo desde estados de movimiento neutros (IDLE, RUN, JUMP, FALL).
// ability_parry = false → bloquea completamente el parry/block.
if (global.inp.block_pressed
    && ability_parry
    && !_sword_busy && !_bow_busy && !_block_busy
    && player_state != PSTATE.DASH
    && parry_cooldown_timer <= 0) {
    player_set_state(PSTATE.BLOCK);
    _block_busy = true;   // actualizar para que las secciones siguientes lo vean
}

// ── BLOCK: parry window + cooldown + exit ─────────────────
// Toda la lógica de temporización del block corre en ALWAYS (tiempo real).
//
// parry_window_timer:  8 frames de ventana perfecta; starts en enter hook.
// is_parrying:         true mientras parry_window_timer > 0.
// parry_active:        alias legible de is_parrying para sistemas externos.
// Salida: soltar C → exit hook de player_set_state limpia is_blocking/is_parrying.
// parry_cooldown_timer: cooldown real-time para evitar spam de parry.
if (_block_busy) {
    // Ventana de parry: set is_parrying según timer (check ANTES de decrementar)
    if (parry_window_timer > 0) {
        is_parrying  = true;
        parry_active = true;   // alias
        parry_window_timer--;
    } else {
        is_parrying  = false;
        parry_active = false;
    }

    // Salida: botón soltado → exit block state
    if (!global.inp.block_held) {
        parry_cooldown_timer = PARRY_COOLDOWN_MAX;
        player_set_state(isGrounded ? PSTATE.IDLE : PSTATE.FALL);
        _block_busy = false;
    }
}

// ── Sincronizar parry_active fuera de _block_busy ─────────
// Garantiza que parry_active sea false cuando no está bloqueando.
if (!_block_busy) {
    parry_active = false;
}

// ── parry_success: countdown (frames reales) ──────────────
// Set en take_damage cuando parry perfecto ocurre.
// Visible durante ~3 frames reales para efectos/sonido/debug.
if (parry_success_timer > 0) {
    parry_success = true;
    parry_success_timer--;
} else {
    parry_success = false;
}

// ── parry popup timer (frames reales) ─────────────────────
if (parry_popup_timer > 0) parry_popup_timer--;

// ── Air sword bounce flash timer (frames reales) ──────────
if (air_sword_bounce_flash_timer > 0) air_sword_bounce_flash_timer--;

// Decrementar cooldown del parry (tiempo real)
if (parry_cooldown_timer > 0) parry_cooldown_timer--;

// ── ESPADA: buffer de ataque ──────────────────────────────
// attack_pressed es one-shot → capturarlo aquí (always) como flag sticky.
// Se consume en la sección gated al entrar al combo o avanzarlo.
// BLOQUEADO si: ability_sword = false | arco activo | block activo | wallslide activo.
// Wallslide bloquea también el BUFFER (no solo el disparo) para evitar
// que un press durante la pared se ejecute al salir del wallslide.
if (global.inp.attack_pressed && ability_sword && !_bow_busy && !_block_busy
    && player_state != PSTATE.WALL) {
    attack_buffer = true;
} else if (global.inp.attack_pressed) {
    if (_bow_busy
    && variable_global_exists("debug_collision") && global.debug_collision) {
        show_debug_message("[DBG-ACTION] Sword blocked: bow active");
    }
    if (player_state == PSTATE.WALL
    && variable_global_exists("debug_collision") && global.debug_collision) {
        show_debug_message("[DBG-ACTION] Sword blocked: wallslide active");
    }
}

// ── ARCO (X): inicio de carga ─────────────────────────────
// Condiciones de bloqueo:
//   bow_cooldown_timer > 0  → cooldown post-disparo
//   _bow_busy               → arco ya activo (no re-entrar)
//   action_lock_timer > 0   → espada en ventana de compromiso (reemplaza !_sword_busy)
//                             El arco vuelve a estar disponible cuando el timer expira,
//                             incluso si el ataque de espada todavía está activo.
//   _block_busy             → bloqueando — bloqueo mutuo arco/block
//
// Dash cancel → arco:
//   Si el jugador está en PSTATE.DASH al presionar arco, el dash se cancela
//   inmediatamente y el arco comienza. Funciona en suelo y en aire.
if (global.inp.ranged_pressed && ability_bow && !_bow_busy && bow_cooldown_timer <= 0
    && action_lock_timer <= 0 && !_block_busy && !beat_em_up_active
    && player_state != PSTATE.WALL && player_can_bow()) {

    // ── Dash cancel → arco ────────────────────────────────
    if (player_state == PSTATE.DASH) {
        dashTimer       = 0;
        dash_jump_grace = 0;
        // El exit hook de DASH clampea vel_x a max_walk_speed.
        // isGrounded aquí refleja el frame anterior — fiable para la transición.
        var _bow_dest = isGrounded
                        ? ((abs(vel_x) > 0) ? PSTATE.RUN : PSTATE.IDLE)
                        : PSTATE.FALL;
        player_set_state(_bow_dest);
        if (variable_global_exists("debug_collision") && global.debug_collision) {
            show_debug_message("[DBG-ACTION] Dash cancelled into bow");
        }
    }

    bow_is_charging  = true;
    _bow_busy        = true;   // actualizar copia local — protege checks del resto del frame
    bow_charge_timer = 0;
    // Si se inicia en el aire, activar modo apuntado aéreo.
    // En suelo: el jugador apunta en su facing normal (sin aim mode).
    if (!isGrounded) {
        is_aiming    = true;
        saved_facing = facing;
        aim_facing   = facing;
    }
} else if (global.inp.ranged_pressed && !_bow_busy) {
    if (action_lock_timer > 0
    && variable_global_exists("debug_collision") && global.debug_collision) {
        show_debug_message("[DBG-ACTION] Bow blocked: sword action lock active  timer="
                           + string(action_lock_timer));
    }
    if (player_state == PSTATE.WALL
    && variable_global_exists("debug_collision") && global.debug_collision) {
        show_debug_message("[DBG-ACTION] Bow blocked: wallslide active");
    }
}

// ── ARCO: sticky release ──────────────────────────────────
if (bow_is_charging && global.inp.ranged_released) {
    bow_release_pending = true;
}

// ── BEAT 'EM UP MODE: activación ──────────────────────────
// Activar con tecla B: dura 5 segundos, reemplaza espada/arco.
if (keyboard_check_pressed(ord("B")) && !beat_em_up_active && ability_sword) {
    start_beat_em_up_mode();
}

// ARCO: acumulación de carga (always — tiempo real) ─────
// IMPORTANTE: esta acumulación corre en la sección always, NO en gated.
// Motivo: durante cámara lenta (time_scale=0.2) la sección gated ocurre
// solo 1 de cada 5 frames reales. Si la acumulación estuviera en gated,
// la carga mínima tardaría 5× más en tiempo real → el jugador suelta el
// botón creyendo haber cargado suficiente, pero bow_charge_timer < 12.
// Al correr aquí, bow_min_charge_frames = 12 siempre equivale a
// 12 frames reales (~0.2s) con o sin cámara lenta.
if (bow_is_charging && global.inp.ranged_held) {
    if (bow_charge_timer < bow_max_charge_frames) {
        bow_charge_timer++;
    }
}

// ── COUNTER WINDOW TIMER (tiempo real) ───────────────────
// Decrementado en always para que el jugador tenga tiempo real
// de reaccionar durante el slow-mo post-parry.
// Cuando expira: limpiar ventana de counter.
if (counterattack_timer > 0) {
    counterattack_timer--;
    if (counterattack_timer <= 0) {
        can_counterattack = false;
        counter_target    = noone;
    }
}

// ── SLOW MOTION ───────────────────────────────────────────
// Fuentes de slow-mo (tiempo real, sección always):
//   1. Arco cargado en el aire (bow_is_charging aéreo)
//   2. Parry perfecto exitoso (parry_slow_timer)
//   3. Ventana de counter activa (can_counterattack + counterattack_timer)
//      → mantiene slow-mo hasta que el jugador decida o la ventana expire.
//
// parry_slow_timer: check ANTES de decrementar para que el último frame
// de slow-mo sea efectivo (evita off-by-one).
var _parry_slow = (parry_slow_timer > 0) || (can_counterattack && counterattack_timer > 0);
if (parry_slow_timer > 0) parry_slow_timer--;

if ((bow_is_charging && !isGrounded && global.inp.ranged_held) || _parry_slow) {
    time_set_slow();
} else {
    time_set_normal();
}

// ── JUMP BUFFER ───────────────────────────────────────────
// Capturado en always para no perder taps durante slowmo.
if (_want_jump) jumpBufferTimer = jump_buffer_max;

// ── INVULNERABILITY BLINK ────────────────────────────────
// Parpadeo visual durante i-frames. Corre en always (tiempo real)
// para que el blink sea visible incluso en cámara lenta.
// blink_interval = 4 → alterna cada 4 frames ≈ 15 parpadeos/segundo.
if (is_invulnerable) {
    image_alpha = ((invuln_timer div blink_interval) mod 2 == 0) ? 0.35 : 1.0;
} else {
    image_alpha = 1.0;
}

// ── DEBUG: daño directo eliminado ────────────────────────
// Antes: H para aplicar daño de prueba.
// Ahora: usar sistema de dificultad y enemigos de prueba.

// ══════════════════════════════════════════════════════════
// GATE — física y gameplay al ritmo de time_scale
// ══════════════════════════════════════════════════════════
if (!global.do_step) exit;

// ══════════════════════════════════════════════════════════
// HITSTUN — bloquear inputs; delegar física al parent
// ══════════════════════════════════════════════════════════
// Durante hitstun el jugador no puede actuar: se limpian todos los
// flags sticky y se salta al event_inherited para que el parent aplique
// knockback (move_x = knockback_x), gravedad y colisiones de tile.
//
// ¿Por qué no en la sección always?
//   hitstun_timer es un timer gated (respeta time_scale). En slow motion
//   el timer avanza solo 1/5 de frames reales → verificar en la sección
//   gated garantiza que la duración del hitstun coincide con el ritmo
//   de gameplay, no con el ritmo real del reloj.
if (hitstun_timer > 0) {
    // Limpiar entradas buffereadas — ninguna acción durante hitstun.
    attack_buffer       = false;
    bow_release_pending = false;
    bow_is_charging     = false;
    bow_charge_timer    = 0;
    aim_angle           = 0;
    jumpBufferTimer     = 0;

    // Física: el parent aplica knockback_x a move_x, decae knockback,
    // aplica gravedad, resuelve colisiones de tile y decrementa hitstun_timer.
    event_inherited();
    exit;
}

// ══════════════════════════════════════════════════════════
// SECCIÓN GATED — se ejecuta a ritmo de global.time_scale
// ══════════════════════════════════════════════════════════

// ── BEAT 'EM UP MODE: timer y cooldowns ───────────────────
// Decrement beat_em_up_timer para llevar cuenta de duración.
// Cuando llega a 0: end_beat_em_up_mode().
if (beat_em_up_active) {
    beat_em_up_timer--;
    if (beat_em_up_timer <= 0) {
        end_beat_em_up_mode();
    }

    // ── DASH cancels Beat 'em Up Mode ─────────────────────
    // Si el jugador presiona dash mientras está en Beat 'em Up,
    // salir inmediatamente del modo y permitir dash normal.
    if (_want_dash) {
        end_beat_em_up_mode();
        show_debug_message("[BEAT-EM-UP] CANCELLED BY DASH");
    }
}

// Decrement attack cooldown (impide spam rápido)
if (beat_em_up_cooldown_timer > 0) {
    beat_em_up_cooldown_timer--;
}

// Decrement active attack timer (cuánto tiempo sigue activa la hitbox)
if (beat_em_up_attack_active) {
    beat_em_up_attack_timer--;
    if (beat_em_up_attack_timer <= 0) {
        beat_em_up_attack_active = false;
        beat_em_up_hitbox_visible = false;  // apagar debug visual
    }
}

// Decrement combo window (si pasa el tiempo sin siguiente punch, reset combo)
if (beat_em_up_active && beat_combo_index > 0) {
    beat_combo_timer++;
    if (beat_combo_timer >= beat_combo_window) {
        beat_combo_index = 0;   // reset combo al siguiente punch
        beat_combo_timer = 0;
    }
}

// ── Helper: ¿está el jugador en un estado de ataque? ──────
var _in_attack = (player_state == PSTATE.ATTACK_1
               || player_state == PSTATE.ATTACK_2
               || player_state == PSTATE.ATTACK_3
               || player_state == PSTATE.DOWN_SLASH
               || player_state == PSTATE.DASH_ATTACK
               || player_state == PSTATE.COUNTER_ATTACK);

// ── ARCO: ajuste de ángulo de apuntado ───────────────────
// Corre en gated: el ajuste respeta time_scale.
// Durante slow motion aéreo el ángulo cambia más despacio en
// tiempo real → apuntado más preciso cuando más importa.
// Solo activo mientras el arco está cargado y no soltado todavía.
if (bow_is_charging && !bow_release_pending) {
    if (global.inp.aim_up_held) {
        aim_angle = max(aim_angle - aim_angle_speed, aim_angle_min);
    }
    if (global.inp.aim_down_held) {
        aim_angle = min(aim_angle + aim_angle_speed, aim_angle_max);
    }
}

// ── ARCO: disparo o cancelación al soltar ─────────────────
// Consume el flag sticky. No dispara si está atacando con espada.
if (bow_release_pending && !_in_attack) {

    // DEBUG — muestra el estado exacto al soltar el botón
    show_debug_message("[DBG-BOW] release: charge=" + string(bow_charge_timer)
        + "  min=" + string(bow_min_charge_frames)
        + "  cooldown=" + string(bow_cooldown_timer)
        + "  is_aiming=" + string(is_aiming)
        + "  isGrounded=" + string(isGrounded));

    if (bow_charge_timer >= bow_min_charge_frames) {
        // ── DISPARO ───────────────────────────────────────
        // Carga mínima alcanzada → crear flecha.
        var _charge_level;
        if      (bow_charge_timer >= bow_charge_lvl2) { _charge_level = 2; }
        else if (bow_charge_timer >= bow_charge_lvl1) { _charge_level = 1; }
        else                                           { _charge_level = 0; }

        // Dirección: aim_facing en modo aéreo, facing normal en suelo.
        var _fire_facing = facing;
        if (is_aiming) _fire_facing = aim_facing;

        // Spawn en el borde lateral del collider + margen, a altura de pecho.
        // PLAYER_CHEST_Y viene de scr_config: ajustar allí si el sprite cambia.
        // col_right/col_left son offsets del bbox real → la flecha sale
        // exactamente al borde del cuerpo, sin solapar el collider propio.
        var _spawn_x = x + (_fire_facing > 0 ? col_right + 8 : col_left - 8);
        var _spawn_y = y + PLAYER_CHEST_Y;   // altura de pecho (scr_config)
        var _arrow   = instance_create_layer(_spawn_x, _spawn_y, "Instances_1", obj_player_arrow);

        // ── Velocidad con ángulo ──────────────────────────
        // Descomponer arrow_speed en componentes X e Y usando aim_angle.
        // Convención: aim_angle < 0 = arriba, > 0 = abajo (coord. pantalla).
        //   vel_x = facing * speed * cos(angle)  →  componente horizontal
        //   vel_y = speed * sin(angle)            →  componente vertical
        // facing solo afecta vel_x, por lo que aim_angle sube/baja igual
        // en ambas direcciones (↑ siempre es arriba sin importar facing).
        var _rad = degtorad(aim_angle);
        _arrow.vel_x = _fire_facing * _arrow.arrow_speed * cos(_rad);
        _arrow.vel_y = _arrow.arrow_speed * sin(_rad);

        _arrow.charge_level = _charge_level;
        _arrow.is_aerial    = !isGrounded;
        _arrow.owner        = id;
        if      (_charge_level == 2) { _arrow.damage = 3; }
        else if (_charge_level == 1) { _arrow.damage = 2; }
        else                         { _arrow.damage = 1; }

        // DEBUG — confirma spawn, ángulo y velocidades
        show_debug_message("[DBG-BOW] FIRED: charge=" + string(_charge_level)
            + "  aim_angle=" + string(aim_angle)
            + "  vel_x=" + string(_arrow.vel_x)
            + "  vel_y=" + string(_arrow.vel_y)
            + "  facing=" + string(_fire_facing));

        // Iniciar cooldown — impide empezar otra carga inmediatamente.
        bow_cooldown_timer = bow_cooldown_frames;

    }
    // Si bow_charge_timer < bow_min_charge_frames: cancelación silenciosa,
    // sin flecha y sin cooldown. El jugador puede reintentar de inmediato.

    // ── Restaurar aim y limpiar estado de carga ───────────
    if (is_aiming) {
        facing     = saved_facing;
        aim_facing = saved_facing;
        is_aiming  = false;
    }
    bow_release_pending = false;
    bow_is_charging     = false;
    bow_charge_timer    = 0;
    aim_angle           = 0;   // siempre resetear al terminar (disparo o cancelación)
}

// ── BEAT 'EM UP MODE: INPUTS ──────────────────────────────
// Si el modo está activo, procesar inputs de punch/heavy/uppercut.
// Tiene prioridad sobre espada/arco normales.
if (beat_em_up_active) {
    update_beat_em_up_mode();
}

// ── ESPADA: entrada al combo ──────────────────────────────
// Un ataque se puede iniciar desde IDLE, RUN, JUMP o FALL.
// Bloqueado desde DASH, WALL, otro ATTACK_* (incluido DOWN_SLASH)
// y durante combo_cooldown_timer.
// BLOQUEADO si: beat_em_up_active (prioridad a beat 'em up mode)
// ── PSTATE.DASH ya no bloquea el ataque ──────────────────
// El dash puede cancelarse hacia espada o arco (ver bloques siguientes).
// Si el jugador presiona ataque durante DASH, el dash se interrumpe y
// el ataque arranca preservando facing. El exit hook de DASH clampea vel_x.
var _can_attack = !_in_attack
               && player_state != PSTATE.WALL
               && player_state != PSTATE.BLOCK  // no atacar durante block/parry
               && combo_cooldown_timer <= 0      // cooldown post-combo
               && !_bow_busy                     // bloqueo mutuo: no espada durante arco
               && !beat_em_up_active             // beat 'em up mode bloqueado espada/arco
               && player_can_attack();           // bloquea durante damage_recovery_lock

// ── COUNTER ATTACK: activar desde ventana de parry ───────
// Prioridad alta: si can_counterattack y el jugador presiona ataque,
// se lanza el counter automático independientemente del estado actual
// (siempre que no esté en dash, arco, wallslide o ya atacando).
// El counter cancela el slow-mo (en el enter hook de COUNTER_ATTACK).
// No activa durante DASH (el dash attack tiene su propio bloque).
if (can_counterattack && ability_counterattack && attack_buffer
&&  instance_exists(counter_target)
&&  !_in_attack && !_bow_busy
&&  player_state != PSTATE.WALL
&&  player_state != PSTATE.DASH
&&  player_state != PSTATE.BLOCK) {
    player_set_state(PSTATE.COUNTER_ATTACK);
    _in_attack = true;
}

// ── DASH ATTACK: entrada ──────────────────────────────────
// Si el jugador presiona ataque DURANTE un dash activo, en vez de cancelar
// el dash se mantiene la velocidad y se activa un ataque de mayor daño.
// Solo una vez por dash (dash_attack_used).
// No interfiere con down_slash: si aim_down_held + aerial, ese bloque tiene prioridad.
if (attack_buffer && player_state == PSTATE.DASH) {
    var _can_dash_attack = !dash_attack_used
                        && !_bow_busy
                        && ability_sword
                        && !(ability_downward_slash && !isGrounded && global.inp.aim_down_held);
    if (_can_dash_attack) {
        player_set_state(PSTATE.DASH_ATTACK);
        _in_attack = true;
    } else {
        // Ya usó el dash attack este dash, consumir buffer silenciosamente.
        attack_buffer = false;
    }
}

// ── DOWN_SLASH: entrada ───────────────────────────────────
// En el aire + ↓ (aim_down_held) + Z → pogo attack.
// Prioridad sobre ATTACK_1: la condición !isGrounded + aim_down_held lo distingue
// del combo normal en tierra. El enter hook consume attack_buffer, evitando
// que ATTACK_1 se active en el mismo frame.
//
// Dash cancel → DOWN_SLASH (solo en aerial dash, !isGrounded):
//   dashTimer = 0 antes de player_set_state para que el exit hook de DASH
//   limpie el estado correctamente; dash_jump_grace = 0 evita boost residual.
// ability_downward_slash gates the DOWN_SLASH specifically.
// ability_sword already gated attack_buffer, but also check here for clarity.
if (attack_buffer && _can_attack && ability_downward_slash && !isGrounded && global.inp.aim_down_held) {
    if (player_state == PSTATE.DASH) {
        dashTimer       = 0;
        dash_jump_grace = 0;
        if (variable_global_exists("debug_collision") && global.debug_collision) {
            show_debug_message("[DBG-ACTION] Dash cancelled into sword (down slash)");
        }
    }
    player_set_state(PSTATE.DOWN_SLASH);
    _in_attack = true;
}

// ── ATTACK_1: entrada ─────────────────────────────────────
// Dash cancel → ATTACK_1 (suelo o aire):
//   El exit hook de PSTATE.DASH clampea vel_x a max_walk_speed.
//   La desaceleración del ataque continúa desde ese valor.
//   dash_jump_grace = 0 cancela cualquier boost pendiente de dash-jump.
if (attack_buffer && _can_attack) {
    if (player_state == PSTATE.DASH) {
        dashTimer       = 0;
        dash_jump_grace = 0;
        if (variable_global_exists("debug_collision") && global.debug_collision) {
            show_debug_message("[DBG-ACTION] Dash cancelled into sword");
        }
    }
    player_set_state(PSTATE.ATTACK_1);
    _in_attack = true;
}

// ── WALL DASH JUMP ────────────────────────────────────────
// Prioridad sobre el dash normal: se verifica primero para consumir
// dashCooldownTimer y evitar que el dash regular se active en el mismo frame.
// Requiere: estar en WALL + dash presionado + jump en buffer + cooldown disponible.
// Usa wallSide del frame anterior (confiable cuando player_state == PSTATE.WALL).
if (player_state == PSTATE.WALL
    && ability_walljump && ability_dash
    && _want_dash && jumpBufferTimer > 0
    && dashCooldownTimer == 0
    && !_bow_busy && !_block_busy) {
    var _wdj_dir  = -wallSide;         // alejarse del muro
    move_y            = wall_dash_jump_y;
    vel_x             = _wdj_dir * wall_dash_jump_x;
    jumpBufferTimer   = 0;
    dashCooldownTimer = dash_cooldown_max;  // impide que el dash normal se active
    can_air_dash      = false;
    dash_jump_active  = true;
    dash_jump_hsp     = vel_x;
    player_set_state(PSTATE.JUMP);
}

// ── JUMP BACK: DESACTIVADO — Reemplazado por Roll Dodge ─────
// NOTA: Jump Back fue desactivado. Toda la lógica queda comentada abajo.
// Si necesitas reactivar, descomenta, pero Roll Dodge es la opción defensiva nueva.
//
/*
var _jump_back_triggered = false;

// ── Paso 1: Presionar dash abre ventana de input ─────────────
if (ability_dash && _want_dash && dashCooldownTimer == 0 && player_state != PSTATE.DASH) {
    jump_back_stored_facing = facing;
    jump_back_input_timer = jump_back_input_window;
    show_debug_message("[JUMP_BACK] Ventana abierta - facing guardado: " + string(jump_back_stored_facing));
}

// ── Paso 2: Durante ventana de input, detectar dirección contraria ──
if (jump_back_input_timer > 0 && player_can_jump_back()) {
    jump_back_input_timer--;
    var _current_input_dir = keyboard_check(vk_right) - keyboard_check(vk_left);
    if (_current_input_dir != 0 && _current_input_dir == -jump_back_stored_facing) {
        _jump_back_triggered = start_jump_back(jump_back_stored_facing);
        if (_jump_back_triggered) {
            dashCooldownTimer = dash_cooldown_max;
            if (!isGrounded && jump_back_uses_dash_charge) can_air_dash = false;
            jump_back_input_timer = 0;
        }
    }
} else {
    jump_back_input_timer = 0;
}
*/

// ── DASH: activación ──────────────────────────────────────
// Bloqueado durante ataque y durante arco activo.
// Funciona en suelo y aire según condiciones de ability_air_dash.
if (ability_dash && _want_dash && dashCooldownTimer == 0
    && player_state != PSTATE.DASH && !_in_attack && !_bow_busy && !_block_busy && player_can_dash()) {
    // Air dash requiere ability_air_dash además de ability_dash.
    var _can_dash = isGrounded || (can_air_dash && ability_air_dash);
    if (_can_dash) {
        dash_was_grounded = isGrounded;
        // ── Dash Jump: ventana de elegibilidad ────────────────
        // Cubre el dash completo + jump_buffer_max para capturar
        // cualquier press de salto hecho durante o justo después del dash.
        // Air dash → grace = 0 (sin impulso extra).
        dash_jump_grace  = isGrounded ? dash_jump_grace_max : 0;
        dash_jump_active = false;  // cancela boost residual de un dash anterior
        dash_jump_timer  = 0;      // (legacy)
        vel_x             = facing * dash_speed;
        dashTimer         = dash_frames;
        dashCooldownTimer = dash_cooldown_max;
        jumpBufferTimer   = 0;
        dash_attack_used  = false;
        if (!isGrounded) can_air_dash = false;
        player_set_state(PSTATE.DASH);
        _in_attack = false;
    }
}

// ── ROLL DODGE: activación con tecla A ─────────────────────
// Acción completamente separada del Dash.
// Se activa presionando tecla A en suelo, mientras puede_rodar.
if (!input_only_lock && keyboard_check_pressed(ord("A")) && player_can_roll()) {
    start_roll();
}

// ── ROLL DODGE: actualización (cada frame gated) ──────────
update_roll();

// ── Roll cooldown decrement (gated) ───────────────────────
if (roll_cooldown_timer > 0) {
    roll_cooldown_timer--;
}

// ── JUMP BACK: DESACTIVADO (comentado arriba)
/*
if (jump_back_active) {
    if (jump_back_timer > 0) {
        jump_back_timer--;
    } else {
        jump_back_active = false;
    }
    if (jump_back_control_lock_timer > 0) {
        jump_back_control_lock_timer--;
    }
}
*/

// ── PRE-FÍSICA: comportamiento especial por estado ────────
switch (player_state) {
    case PSTATE.IDLE: break;
    case PSTATE.RUN:  break;
    case PSTATE.JUMP: break;
    case PSTATE.FALL: break;

    case PSTATE.WALL:
        max_fall = (_dir == wallSide) ? wall_slide_max_fall : fall_max_default;
    break;

    case PSTATE.DASH:
        if (dashTimer > 0) {
            move_y = -grav;    // neutraliza gravedad exactamente
            dashTimer--;
        }
    break;

    case PSTATE.ATTACK_1:
    case PSTATE.ATTACK_2:
    case PSTATE.ATTACK_3:
    case PSTATE.DOWN_SLASH:
        // Sin ajuste de física especial — gravedad normal en el aire.
        // Durante DOWN_SLASH el jugador cae libremente sobre el objetivo.
        // La desaceleración horizontal se gestiona en la sección vel_x (_in_attack).
    break;

    case PSTATE.DASH_ATTACK:
        // Neutralizar gravedad igual que DASH para que el ataque sea horizontal.
        move_y = -grav;
        attack_timer--;
    break;

    case PSTATE.COUNTER_ATTACK:
        // Neutralizar gravedad: el dash de counter es siempre horizontal.
        move_y = -grav;
        attack_timer--;
    break;
}

// ── VELOCIDAD HORIZONTAL ──────────────────────────────────
if (wallJumpLockTimer > 0) {

    vel_x = wall_jump_dir * wall_jump_x;

} else if (player_state == PSTATE.DASH) {

    // ── Dash aéreo: redirección instantánea ──────────────
    // En suelo el dash siempre va en la dirección original (facing al inicio).
    // En el aire, si el jugador presiona la dirección contraria, facing se
    // actualiza y el impulso se redirige sin reiniciar el timer.
    // _dir ya tiene el input horizontal de este frame (read-only en esta sección).
    // IMPORTANTE: NO cambiar facing si jump_back está buscando dirección contraria.
    if (!isGrounded && _dir != 0 && jump_back_input_timer <= 0 && !jump_back_facing_locked) {
        facing = _dir;
    }

    vel_x = facing * dash_speed;

} else if (player_state == PSTATE.DASH_ATTACK) {

    // Mantiene la velocidad del dash durante el dash attack.
    vel_x = facing * dash_speed;

} else if (player_state == PSTATE.COUNTER_ATTACK) {

    // Dash automático hacia el target. Si el target ya no existe,
    // continuar en la dirección de facing hasta que expire el timer.
    if (instance_exists(counter_target)) {
        var _cdir = sign(counter_target.x - x);
        if (_cdir == 0) _cdir = facing;
        facing = _cdir;
        vel_x  = _cdir * counter_dash_speed;
    } else {
        vel_x = facing * counter_dash_speed;
    }

} else if (roll_active) {

    // Roll: movimiento forzado con hitbox baja e invulnerabilidad.
    // Se procesa aquí para que no lo sobrescriba la desaceleración normal.
    vel_x = roll_dir * roll_speed;

} else if (_in_attack) {

    // Durante el ataque: desaceleración rápida en suelo, mantener
    // momentum en el aire (el jugador ya está comprometido).
    if (isGrounded) {
        if (abs(vel_x) <= attack_decel) {
            vel_x = 0;
        } else {
            vel_x -= sign(vel_x) * attack_decel;
        }
    }
    // En el aire no se acepta input direccional — momentum conservado.

} else if (damage_recovery_lock) {

    // ── DAMAGE RECOVERY: bloqueo total de movimiento ────────
    // El jugador acaba de recibir daño y está en i-frames.
    // No puede moverse, pero la física (gravedad, knockback) sigue activa.
    // En suelo: desacelerar a cero.
    // En aire:  conservar velocidad pero sin aceptar input (knockback sigue).
    if (isGrounded) {
        if (abs(vel_x) <= ground_decel) {
            vel_x = 0;
        } else {
            vel_x -= sign(vel_x) * ground_decel;
        }
    }
    // Aire: vel_x se conserva (incluye knockback), sin nuevo input.
    var _dir = 0;  // bloquear input

} else if (bow_is_charging) {

    // ── ARCO: bloqueo de movimiento horizontal ─────────────
    // El jugador se queda quieto apuntando.
    // En suelo: desacelerar a 0 con ground_decel (rápido, ~2 frames).
    // En aire:  vel_x se conserva sin cambios — la inercia aérea
    //           sigue activa pero NO se acepta nuevo input direccional.
    //           La gravedad sigue aplicándose (via event_inherited).
    if (isGrounded) {
        if (abs(vel_x) <= ground_decel) {
            vel_x = 0;
        } else {
            vel_x -= sign(vel_x) * ground_decel;
        }
    }
    // Aire: no tocar vel_x → inercia conservada, sin nuevo input.

} else if (_block_busy) {

    // ── BLOCK / PARRY: inmovilizar al jugador ──────────────
    // En suelo: frenar rápidamente a cero.
    // En aire:  conservar inercia — el jugador ya está comprometido
    //           y no acepta nuevo input direccional mientras bloquea.
    if (isGrounded) {
        if (abs(vel_x) <= ground_decel) {
            vel_x = 0;
        } else {
            vel_x -= sign(vel_x) * ground_decel;
        }
    }
    // Aire: vel_x sin cambios.

} else {

    // ── Dash Jump Boost: techo de velocidad aérea elevado ─────
    // dash_jump_active es true desde el salto hasta tocar el suelo (MMX4 style).
    // El boost no expira por timer — dura todo el arco aéreo.
    // • Misma dirección → fricción reducida (dash_jump_friction): momentum se mantiene.
    // • Sin input o dirección contraria → deceleración suave (dash_jump_air_control):
    //   el jugador puede redirigir, pero no pierde velocidad bruscamente.
    var _effective_max = (dash_jump_active && !isGrounded) ? dash_jump_speed : max_walk_speed;
    var _target_x      = _dir * _effective_max;
    var _rate;
    if (isGrounded) {
        if (_dir == 0) {
            _rate = ground_decel;
        } else if (vel_x != 0 && sign(vel_x) != sign(_target_x)) {
            _rate = ground_turn_accel;
        } else {
            _rate = ground_accel;
        }
    } else {
        if (dash_jump_active) {
            if (_dir != 0) {
                // ── Redirección instantánea del dash jump ─────────
                // Presionar cualquier dirección en el aire redirige el
                // impulso a dash_jump_speed en la nueva dirección.
                // No se interpola — el cambio es inmediato para que
                // el jugador sienta control total sobre el momentum.
                //
                // Se actualiza facing para que el sprite gire al instante
                // y la animación de dash sea coherente con el movimiento.
                //
                // _target_x y _rate se ponen en modo "ya alcanzado"
                // para que el lerp final del bloque sea un no-op.
                facing    = _dir;
                vel_x     = _dir * dash_jump_speed;
                _target_x = vel_x;   // diff = 0 → lerp no hace nada
                _rate     = 0;
            } else {
                // Sin input: deceleración suave — el momentum se conserva
                // pero el arco decae naturalmente.
                _rate = dash_jump_air_control;
            }
        } else if (_dir == 0 || (vel_x != 0 && sign(vel_x) != sign(_target_x))) {
            _rate = air_decel;
        } else {
            _rate = air_accel;
        }
    }
    if (abs(_target_x - vel_x) <= _rate) {
        vel_x = _target_x;
    } else {
        vel_x += sign(_target_x - vel_x) * _rate;
    }
}

move_x = vel_x;

// ── LOW PROFILE: hitbox reducida pre-física ───────────────
// Activa durante dash slide o roll. Si termina bajo un techo,
// is_sliding queda true hasta que haya espacio para crecer.
var _dash_slide_active = (player_state == PSTATE.DASH && dash_was_grounded && isGrounded);
var _roll_slide_active = roll_active;
var _should_low_profile = _dash_slide_active || _roll_slide_active;

if (_should_low_profile && !is_sliding) {
    is_sliding = true;
}
if (is_sliding) {
    col_top = slide_col_top;
}

// ── FÍSICA (parent: gravedad + colisiones de tile) ────────
event_inherited();

// ── SLOW MOTION: actualizar image_speed con multiplicador global ─
// Permite que las animaciones del sprite respondan a parry slow-mo
image_speed = base_image_speed * get_time_scale();

// ══════════════════════════════════════════════════════════
// POST-FÍSICA — combate, saltos, timers, transiciones
// ══════════════════════════════════════════════════════════

// ── DEBUG TEMPORAL: colisión en tiempo real ───────────────
// Activar con F4 en runtime, o dejar siempre activo hasta confirmar.
// Quitar este bloque cuando todo funcione.
if (keyboard_check_pressed(vk_f4)) {
    global.debug_collision_live = !variable_global_exists("debug_collision_live")
                                   || !global.debug_collision_live;
    show_debug_message("[DBG-COL] live debug: " + string(global.debug_collision_live));
}
if (variable_global_exists("debug_collision_live") && global.debug_collision_live) {
    var _tile_feet   = tilemap_get_at_pixel(collision_map, x, y + 2);
    var _tile_head   = tilemap_get_at_pixel(collision_map, x, y + col_top);
    var _tile_left   = tilemap_get_at_pixel(collision_map, x + col_left - 1, y - 16);
    var _tile_right  = tilemap_get_at_pixel(collision_map, x + col_right + 1, y - 16);
    show_debug_message("[DBG-COL]"
        + "  map=" + string(collision_map)
        + "  pos=(" + string(x) + "," + string(y) + ")"
        + "  feet=" + string(_tile_feet)
        + "  head=" + string(_tile_head)
        + "  isGrounded=" + string(isGrounded));
}
// ─────────────────────────────────────────────────────────

// ── LOW PROFILE: restaurar hitbox (post-física) ───────────
// Se evalúa cada frame mientras is_sliding sea true.
// Condición para continuar reducido: dash slide activo o roll activo.
// En cuanto ambas fallen, se intenta restaurar col_top a su valor normal.
//
// Seguridad de techo:
//   Antes de expandir, se verifica que no haya tile sólido en la zona
//   que quedaría descubierta. Si hay techo encima → col_top permanece
//   reducido hasta que el jugador salga del espacio estrecho.
//
// Esto implementa el comportamiento Hollow Knight / Metroid Dread:
//   "la hitbox no crece dentro de un techo, espera a tener espacio."
if (is_sliding) {
    var _dash_slide_continues = (player_state == PSTATE.DASH && dash_was_grounded && isGrounded);
    var _roll_slide_continues = roll_active;
    var _low_profile_continues = _dash_slide_continues || _roll_slide_continues;

    if (!_low_profile_continues) {
        if (can_restore_low_profile_collision()) {
            col_top    = normal_col_top;
            is_sliding = false;
        }
        // Si no hay espacio: mantener col_top reducido hasta salir del túnel.
    }
}

// ── APUNTADO AÉREO: actualizar y aplicar ──────────────────
// Corre post-física para que isGrounded esté actualizado.
// El parent ya actualizó facing según move_x → nosotros lo sobreescribimos.
if (is_aiming) {
    // Actualizar dirección de apuntado según input del frame actual.
    // El jugador puede presionar ← para apuntar atrás sin girar físicamente.
    if (_dir != 0) {
        aim_facing = _dir;
    }
    // Sobreescribir el facing que el parent puso según movimiento.
    // Esto hace que el sprite gire para mostrar la dirección de apuntado.
    // La física (vel_x) no se ve afectada — move_x ya fue enviado a event_inherited.
    facing = aim_facing;

    // Cancelar aim si el jugador aterrizó durante la carga
    // (sin disparar — el arco simplemente se cancela al tocar el suelo).
    if (isGrounded) {
        facing     = saved_facing;
        aim_facing = saved_facing;
        is_aiming  = false;
        // No cancelar bow_is_charging: el jugador puede seguir cargando en suelo
        // pero sin aim mode (disparará en su facing normal).
    }
}

// ── ESPADA: procesar estado de ataque (combo normal) ─────
// Corre DESPUÉS de event_inherited() para que isGrounded esté actualizado.
// DOWN_SLASH tiene su propio bloque de procesamiento más abajo.
if (_in_attack && player_state != PSTATE.DOWN_SLASH && player_state != PSTATE.DASH_ATTACK) {

    // ── Lookup de parámetros del golpe actual ─────────────
    // Valores por estado — sin ternarios encadenados para compatibilidad GML.
    var _max_t   = attack_3_frames;
    var _hb_life = attack_3_hitbox_frames;
    var _hb_dmg  = sword_damage_3;
    var _window  = -1;   // ATTACK_3 no habilita siguiente combo
    var _next    = PSTATE.ATTACK_3;

    if (player_state == PSTATE.ATTACK_1) {
        _max_t   = attack_1_frames;
        _hb_life = attack_1_hitbox_frames;
        _hb_dmg  = sword_damage_1;
        _window  = combo_window_1;
        _next    = PSTATE.ATTACK_2;
    } else if (player_state == PSTATE.ATTACK_2) {
        _max_t   = attack_2_frames;
        _hb_life = attack_2_hitbox_frames;
        _hb_dmg  = sword_damage_2;
        _window  = combo_window_2;
        _next    = PSTATE.ATTACK_3;
    }

    // ── Primer frame del estado: spawnar hitbox ───────────
    // attack_timer aún tiene el valor máximo porque el enter hook
    // lo asignó y todavía no se ha decrementado en este frame.
    // La hitbox es INDEPENDIENTE de la máscara de colisión del player.
    //
    // GEOMETRÍA DE ATAQUE (facing = +1):
    //   Rect X: [x + sword_hitbox_x] → [x + sword_hitbox_x + sword_hitbox_w]
    //   Rect Y: [y + sword_hitbox_y - sword_hitbox_h/2] → [y + sword_hitbox_y + sword_hitbox_h/2]
    // O usando variables nuevas:
    //   Rect X: [x + player_attack_start_offset] → [x + player_attack_start_offset + player_attack_reach]
    //   Rect Y: [y + player_attack_offset_y - player_attack_height/2] → [y + player_attack_offset_y + player_attack_height/2]
    //
    // AJUSTE VISUAL: Si el golpe es muy corto/largo o está muy arriba/abajo,
    // modificar SWORD_HITBOX_* en scr_config.gml o las nuevas variables.
    if (attack_timer == _max_t) {
        // Capturar el ID del jugador ANTES de entrar al with.
        // Dentro de un with, 'other' refiere al contexto anterior y puede ser
        // ambiguo en Step events normales. Usar 'id' (variable local capturada)
        // es el único método garantizado en GML para pasar el ID propio.
        var _player_id = id;

        sword_hitbox_id = instance_create_layer(
            x + facing * sword_hitbox_x,
            y + sword_hitbox_y,
            "Instances_1",
            obj_sword_hitbox
        );
        with (sword_hitbox_id) {
            owner           = _player_id;   // ID explícito — nunca ambiguo
            // Precargar owner en hit_list: segunda línea de defensa.
            // Si el check _inst == owner falla por algún motivo de GML,
            // el hit_list garantiza que el jugador nunca sea procesado.
            ds_list_add(hit_list, _player_id);
            damage          = _hb_dmg;
            lifetime        = _hb_life;
            hitbox_offset_x = _player_id.sword_hitbox_x;
            hitbox_offset_y = _player_id.sword_hitbox_y;
            hitbox_w        = _player_id.sword_hitbox_w;
            hitbox_h        = _player_id.sword_hitbox_h;
            // Energía: suelo vs aire
            energy_gain_amount = _player_id.isGrounded
                                 ? _player_id.sword_hit_energy_gain
                                 : _player_id.air_sword_hit_energy_gain;
        }
    }

    // ── Decrementar timer ─────────────────────────────────
    attack_timer--;

    // ── Ventana de combo ──────────────────────────────────
    // Si attack_buffer está activo Y el timer entró en la ventana → avanzar.
    if (_window > 0 && attack_timer <= _window && attack_buffer) {
        player_set_state(_next);
        _in_attack = true;
    } else if (attack_timer <= 0) {
        // ── Salida del combo ──────────────────────────────
        // HOOK FUTURO — dash-cancel: comprobar _want_dash aquí antes de salir.
        var _exit_dest = PSTATE.FALL;
        if (isGrounded) {
            _exit_dest = (_dir != 0) ? PSTATE.RUN : PSTATE.IDLE;
        }
        player_set_state(_exit_dest);
        _in_attack = false;
        combo_step = 0;

        // ── Limpiar buffer al terminar el combo ───────────
        // CAUSA RAÍZ DEL BUG: attack_buffer podía quedar true desde una
        // pulsación de Z hecha durante ATTACK_3 (para avanzar el combo).
        // Como ATTACK_3 no tiene ventana de avance, el buffer se ignoraba
        // durante el golpe, pero al salir a IDLE con _can_attack = true
        // disparaba un ATTACK_1 automático en el siguiente gated frame.
        //
        // Solución: vaciar el buffer al terminar CUALQUIER golpe por
        // expiración de timer (no por avance de combo). Esto garantiza
        // que solo un press POSTERIOR al cooldown inicie el próximo combo.
        attack_buffer = false;

        // Cooldown post-combo: bloquear nuevos ataques brevemente.
        // Solo se activa al terminar ATTACK_3 (último golpe). Para ATTACK_1
        // y ATTACK_2 que expiran sin avance no aplicamos cooldown completo,
        // solo limpiamos el buffer (ya hecho arriba).
        if (combo_step == 3) {
            combo_cooldown_timer = combo_cooldown_frames;
        }
    }
}

// ── ESPADA: dash attack ───────────────────────────────────
// Hitbox única en el primer frame; attack_timer se decrementa en el switch pre-física.
// Al expirar el timer → transición según suelo/aire.
if (player_state == PSTATE.DASH_ATTACK) {
    // Spawn hitbox en el primer frame (attack_timer == attack_1_frames al entrar)
    if (!instance_exists(sword_hitbox_id)) {
        var _hb = instance_create_layer(
            x + sword_hitbox_x * facing,
            y + sword_hitbox_y,
            (layer_get_id("Instances_2") != -1 ? "Instances_2" : layer_get_name(layer)),
            obj_sword_hitbox
        );
        _hb.owner              = id;
        _hb.damage             = sword_damage_1 * dash_attack_damage_mult;
        _hb.hitbox_offset_x    = sword_hitbox_x * facing;
        _hb.hitbox_offset_y    = sword_hitbox_y;
        _hb.hitbox_w           = sword_hitbox_w;
        _hb.hitbox_h           = sword_hitbox_h;
        _hb.lifetime           = attack_1_hitbox_frames;
        _hb.energy_gain_amount = sword_hit_energy_gain;   // dash attack = mismo que espada suelo
        sword_hitbox_id        = _hb;
    }

    // Transición al expirar el timer (decrementado en switch pre-física)
    if (attack_timer <= 0) {
        player_set_state(isGrounded ? PSTATE.IDLE : PSTATE.FALL);
    }
}

// ── COUNTER ATTACK: procesamiento ───────────────────────
// Hitbox se spawnea en el primer frame (attack_timer == counter_dash_duration al entrar).
// Sigue al jugador cada frame (el Step de sword_hitbox re-posiciona x/y cada frame).
// Cuando el timer expira o hay colisión con muro → salir al estado de movimiento.
if (player_state == PSTATE.COUNTER_ATTACK) {
    if (!instance_exists(sword_hitbox_id)) {
        var _player_id = id;
        sword_hitbox_id = instance_create_layer(
            x + facing * sword_hitbox_x,
            y + sword_hitbox_y,
            (layer_get_id("Instances_2") != -1 ? "Instances_2" : layer_get_name(layer)),
            obj_sword_hitbox
        );
        with (sword_hitbox_id) {
            owner              = _player_id;
            damage             = _player_id.sword_damage_1 * _player_id.counter_damage_multiplier;
            hitbox_offset_x    = _player_id.sword_hitbox_x;   // sigue al owner cada frame
            hitbox_offset_y    = _player_id.sword_hitbox_y;
            hitbox_w           = _player_id.counter_hitbox_w;
            hitbox_h           = _player_id.counter_hitbox_h;
            lifetime           = _player_id.counter_dash_duration + 2;  // cubre toda la duración
            counter_target_id  = _player_id.counter_target;             // filtrar target
            energy_gain_amount = _player_id.counter_energy_gain;        // 15 por counter hit
            ds_list_add(hit_list, _player_id);
        }
    }

    if (attack_timer <= 0) {
        player_set_state(isGrounded ? ((_dir != 0) ? PSTATE.RUN : PSTATE.IDLE) : PSTATE.FALL);
    }
}

// ── ESPADA: downward slash / pogo attack (persistente) ───
// La hitbox permanece activa mientras el jugador mantenga
// presionados ↓ + botón de ataque. Tras cada rebote, se destruye
// y se re-arma después de downward_slash_hit_cooldown_max frames,
// permitiendo encadenar múltiples rebotes sobre el mismo o
// diferentes enemigos.
//
// Cancelaciones (orden de prioridad):
//   1. isGrounded        → aterrizó → IDLE/RUN
//   2. !aim_down_held    → soltó ↓  → FALL
//   3. !attack_held      → soltó Z  → FALL
//
// Re-armado tras rebote:
//   4. has_pogo_bounced  → limpiar hitbox, iniciar cooldown
//   5. cooldown == 0     → spawnear nueva hitbox
//
// Timeout de seguridad:
//   attack_timer       → si expira, cancelar (evita DOWN_SLASH infinito)
if (player_state == PSTATE.DOWN_SLASH) {

    // ── Cancelación: aterrizar ────────────────────────────
    if (isGrounded) {
        player_set_state((_dir != 0) ? PSTATE.RUN : PSTATE.IDLE);
        _in_attack = false;

    // ── Cancelación: soltar ↓ o soltar botón de ataque ───
    } else if (!global.inp.aim_down_held || !global.inp.attack_held) {
        player_set_state(PSTATE.FALL);
        _in_attack = false;

    } else {

        // ── Cooldown de re-hit ────────────────────────────
        if (downward_slash_hit_cooldown > 0) {
            downward_slash_hit_cooldown--;
        }

        // ── Post-rebote: limpiar y re-armar ──────────────
        // has_pogo_bounced fue activado por on_hit() en el frame anterior.
        // Se destruye la hitbox vieja (su hit_list tenía al enemigo golpeado)
        // y se inicia el cooldown. En el frame N+cooldown se spawneará
        // una hitbox nueva con un hit_list limpio para el próximo rebote.
        if (has_pogo_bounced) {
            if (instance_exists(sword_hitbox_id)) {
                with (sword_hitbox_id) {
                    ds_list_destroy(hit_list);
                    instance_destroy();
                }
                sword_hitbox_id = noone;
            }
            has_pogo_bounced            = false;
            downward_slash_hit_cooldown = downward_slash_hit_cooldown_max;
            attack_timer                = down_slash_frames;   // resetear timeout
        }

        // ── Spawn de hitbox ───────────────────────────────
        // Condición: sin hitbox activa Y cooldown expirado.
        // La hitbox se mantiene viva por el estado (lifetime alto);
        // el exit hook de DOWN_SLASH la destruye al cancelar.
        if (!instance_exists(sword_hitbox_id) && downward_slash_hit_cooldown <= 0) {
            var _player_id = id;
            sword_hitbox_id = instance_create_layer(
                x + down_slash_hitbox_x,
                y + down_slash_hitbox_y,
                "Instances_1",
                obj_sword_hitbox
            );
            with (sword_hitbox_id) {
                owner              = _player_id;
                is_pogo            = true;
                damage             = _player_id.down_slash_damage;
                // lifetime alto: la hitbox vive mientras el estado esté activo.
                // El exit hook de DOWN_SLASH la destruye al cancelar/aterrizar.
                // 9999 ÷ 60 fps ≈ 166 s — imposible expirar en gameplay normal.
                lifetime           = 9999;
                hitbox_offset_x    = _player_id.down_slash_hitbox_x;
                hitbox_offset_y    = _player_id.down_slash_hitbox_y;
                hitbox_w           = _player_id.down_slash_hitbox_w;
                hitbox_h           = _player_id.down_slash_hitbox_h;
                energy_gain_amount = _player_id.downward_slash_energy_gain;
                // Excluir al jugador del hit_list (nunca se daña a sí mismo).
                ds_list_add(hit_list, _player_id);
                // on_hit: sobreescribe el default de sword_hitbox.
                // Aplica rebote + energía. Air bounce NO aplica (is DOWN_SLASH).
                on_hit = function(_target) {
                    if (!owner.has_pogo_bounced) {
                        owner.has_pogo_bounced = true;
                        owner.move_y           = owner.pogo_bounce_speed;
                        owner.bounce_count++;
                        // Energía del pogo solo en el primer bounce de cada hitbox.
                        owner.gain_super_energy(energy_gain_amount);
                        var _tname = instance_exists(_target)
                                     ? object_get_name(_target.object_index)
                                     : "[destroyed on impact]";
                        show_debug_message("[DBG-POGO] bounce: target=" + _tname
                            + "  speed=" + string(owner.pogo_bounce_speed)
                            + "  energy=" + string(owner.super_energy)
                            + "  cooldown_next=" + string(owner.downward_slash_hit_cooldown_max));
                    }
                };
            }
        }

        // ── Timeout de seguridad ──────────────────────────
        // Solo decrementar cuando hay hitbox activa. Evita que el timer
        // avance durante el cooldown de re-armado, dando el tiempo completo
        // en cada hit.
        if (instance_exists(sword_hitbox_id)) {
            attack_timer--;
            if (attack_timer <= 0) {
                player_set_state(PSTATE.FALL);
                _in_attack = false;
            }
        }
    }
}

// ── DASH JUMP: salto interrumpe dash desde suelo ──────────
// Si el jugador presiona salto DURANTE un dash que empezó en suelo,
// el dash se cancela inmediatamente y se ejecuta el salto conservando
// toda la velocidad horizontal del dash (MMX4 style).
//
// Condiciones:
//   • player_state == DASH (todavía en el dash)
//   • dash_was_grounded == true (el dash empezó en suelo)
//   • jumpBufferTimer > 0 (hubo un press de salto reciente)
//
// Nota: el exit hook de PSTATE.DASH clampea vel_x a max_walk_speed.
// Se captura la velocidad del dash ANTES del cambio de estado y se
// restaura inmediatamente después para preservar el momentum.
if (ability_dash_jump && player_state == PSTATE.DASH && dash_was_grounded && jumpBufferTimer > 0) {
    var _dash_vx     = facing * dash_speed;   // vel horizontal del dash en este frame
    move_y           = jump_speed;
    jumpBufferTimer  = 0;
    coyoteTimer      = 0;
    dashTimer        = 0;           // terminar el dash
    dash_jump_grace  = 0;           // ya no necesaria
    player_set_state(PSTATE.JUMP);  // DASH exit hook clampea vel_x — se restaura abajo
    vel_x            = _dash_vx;    // restaurar velocidad completa del dash
    dash_jump_active = true;        // mantener momentum hasta aterrizar
    dash_jump_hsp    = vel_x;       // captura para debug/referencia
}

// ── WALL JUMP ─────────────────────────────────────────────
if (ability_walljump && jumpBufferTimer > 0 && player_state == PSTATE.WALL) {
    wall_jump_dir     = -wallSide;
    vel_x             = wall_jump_dir * wall_jump_x;
    move_y            = wall_jump_y;
    wallJumpLockTimer = wall_jump_lock_frames;
    jumpBufferTimer   = 0;
    player_set_state(PSTATE.JUMP);
}

// ── SALTO NORMAL ──────────────────────────────────────────
// Bloqueado durante DASH y estados de ataque.
// (El dash-jump ya fue manejado arriba y cambió el estado a JUMP,
//  así que este bloque no se re-ejecuta para ese caso.)
if (player_state != PSTATE.DASH && !_in_attack) {
    var _can_jump = isGrounded || (coyoteTimer > 0);
    if (jumpBufferTimer > 0 && _can_jump) {
        move_y          = jump_speed;
        jumpBufferTimer = 0;
        coyoteTimer     = 0;
        // ── Dash Jump Boost (MMX4 style) ──────────────────────
        // Si el salto se ejecutó dentro de la ventana de un dash grounded,
        // activar el boost de momentum. Dura hasta aterrizar (flag-based).
        // (dash_jump_grace solo es >0 si el dash fue desde el suelo.)
        if (dash_jump_grace > 0) {
            dash_jump_active = true;
            dash_jump_hsp    = vel_x;   // captura vel en el momento del salto
        }
    }
    if (jumpBufferTimer > 0) jumpBufferTimer--;
}

// ── SAFETY EXITS por desactivación de habilidad en runtime ──
// Si una habilidad se desactiva mientras el estado correspondiente está activo,
// salir limpiamente sin dejar al jugador atrapado.
// NOTA: Solo cubre estados que no tienen salida natural si la habilidad falla.
if (!ability_wallslide && player_state == PSTATE.WALL) {
    player_set_state(PSTATE.FALL);
}
if (!ability_parry && player_state == PSTATE.BLOCK) {
    parry_cooldown_timer = PARRY_COOLDOWN_MAX;
    player_set_state(isGrounded ? PSTATE.IDLE : PSTATE.FALL);
}

// ── TIMERS ────────────────────────────────────────────────
if (wallJumpLockTimer         > 0) wallJumpLockTimer--;
if (dashCooldownTimer         > 0) dashCooldownTimer--;
if (bow_cooldown_timer        > 0) bow_cooldown_timer--;
if (combo_cooldown_timer      > 0) combo_cooldown_timer--;
if (dash_jump_timer           > 0) dash_jump_timer--;
if (dash_jump_grace           > 0) dash_jump_grace--;
if (action_lock_timer         > 0) action_lock_timer--;   // compromiso espada → libera arco al expirar
if (air_sword_bounce_cooldown > 0) air_sword_bounce_cooldown--;
if (damage_recovery_lock_timer > 0) damage_recovery_lock_timer--;
// Cuando damage_recovery_lock_timer llega a 0, limpiar lock
if (damage_recovery_lock && damage_recovery_lock_timer <= 0) {
    damage_recovery_lock = false;
}
// input_only_lock_timer es solo el techo de seguridad — quien activa el
// lock (hoy, obj_battleroom_parent) debería limpiar input_only_lock a
// mano apenas termine su motivo. Esto es el fallback si no lo hace.
if (input_only_lock_timer > 0) input_only_lock_timer--;
if (input_only_lock && input_only_lock_timer <= 0) {
    input_only_lock = false;
}
// Contraataque: ventana gated (respeta time_scale → más tiempo durante slow-mo)
// counterattack_timer se decrementa en ALWAYS (sección real-time) para que el
// jugador tenga tiempo de reaccionar durante el slow-mo del parry.

// ── BUFFER DE COMBOS ──────────────────────────────────────
// Registra inputs recientes para detección futura de combos.
// Corre en sección gated: los timers respetan time_scale.
// No activa ningún combo todavía — solo actualiza los timers.
// Helpers: was_recent_sword(), was_recent_dash(), etc. — scr_combo_buffer.gml
update_combo_input_buffer();

// ── TRANSICIÓN DE ESTADOS DE MOVIMIENTO ───────────────────
// Los estados ATTACK_* gestionan sus propias transiciones arriba.
// Esta sección solo actúa sobre estados de movimiento.
var _ground_dest = (_dir != 0) ? PSTATE.RUN : PSTATE.IDLE;

switch (player_state) {

    case PSTATE.IDLE:
        if      (isJumping)  player_set_state(PSTATE.JUMP);
        else if (isFalling)  player_set_state(PSTATE.FALL);
        else if (_dir != 0)  player_set_state(PSTATE.RUN);
    break;

    case PSTATE.RUN:
        if      (isJumping)               player_set_state(PSTATE.JUMP);
        else if (isFalling)               player_set_state(PSTATE.FALL);
        else if (_dir == 0 && vel_x == 0) player_set_state(PSTATE.IDLE);
    break;

    case PSTATE.JUMP:
        if      (isGrounded)                                                                                          player_set_state(_ground_dest);
        else if (!isJumping && ability_wallslide && wallContact && _dir == wallSide && wallJumpLockTimer == 0)        player_set_state(PSTATE.WALL);
        else if (!isJumping && wallJumpLockTimer == 0)                                                                player_set_state(PSTATE.FALL);
    break;

    case PSTATE.FALL:
        if      (isGrounded)                                                                                    player_set_state(_ground_dest);
        else if (isJumping)                                                                                      player_set_state(PSTATE.JUMP);
        else if (ability_wallslide && wallContact && _dir == wallSide && wallJumpLockTimer == 0)  player_set_state(PSTATE.WALL);
    break;

    case PSTATE.WALL:
        if      (isGrounded)                        player_set_state(_ground_dest);
        else if (isJumping)                         player_set_state(PSTATE.JUMP);
        else if (!wallContact || _dir != wallSide)  player_set_state(PSTATE.FALL);
    break;

    case PSTATE.DASH:
        var _hit_wall = (move_x == 0 && dashTimer > 0);
        if (dashTimer <= 0 || _hit_wall) {
            if (_hit_wall) {
                player_set_state(dash_was_grounded ? _ground_dest : PSTATE.FALL);
            } else {
                if      (isGrounded) player_set_state(_ground_dest);
                else if (isJumping)  player_set_state(PSTATE.JUMP);
                else                 player_set_state(PSTATE.FALL);
            }
        }
    break;

    case PSTATE.ATTACK_1:
    case PSTATE.ATTACK_2:
    case PSTATE.ATTACK_3:
        // Gestionado en la sección "ESPADA: procesar estado de ataque" de arriba.
        // HOOK FUTURO — interrupción externa:
        //   Si wallContact fuerte mientras ataca en suelo → cancelar ataque.
        //   Si recibe daño durante parry_window → player_set_state(PSTATE.PARRY).
    break;

    case PSTATE.DOWN_SLASH:
        // Gestionado en la sección "ESPADA: downward slash / pogo attack" de arriba.
        // Cancelación por ↓ liberado, aterrizaje, rebote y timer se procesan allí.
        // No hace falta manejo adicional aquí.
    break;

    case PSTATE.BLOCK:
        // La salida responde a soltar C (sección always, tiempo real).
        // La física de movimiento se maneja en la rama _block_busy de vel_x.
        // Transiciones a IDLE/FALL se disparan en la sección always al soltar el botón.
        // Aquí solo aseguramos que las transiciones de movimiento no sobreescriban BLOCK.
    break;

    case PSTATE.DASH_ATTACK:
        // Transiciones gestionadas en el bloque "ESPADA: dash attack" de arriba.
        // (timer expiry → IDLE/FALL; wall hit también la maneja el exit hook)
        var _da_hit_wall = (move_x == 0 && attack_timer > 0);
        if (_da_hit_wall) {
            player_set_state(isGrounded ? _ground_dest : PSTATE.FALL);
        }
    break;

    case PSTATE.COUNTER_ATTACK:
        // Timer y wall hit — cancelar early si el player choca con muro.
        // El timer expiry se maneja en el bloque de procesamiento de arriba.
        var _ca_hit_wall = (move_x == 0 && attack_timer > 0);
        if (_ca_hit_wall) {
            player_set_state(isGrounded ? _ground_dest : PSTATE.FALL);
        }
    break;
}

// ══════════════════════════════════════════════════════════
// ANIMACIÓN VISUAL
// ══════════════════════════════════════════════════════════
// Puramente visual: solo modifica sprite_index / image_index / image_speed.
// El Draw del parent (draw_sprite_ext) los lee directamente.
// image_xscale = facing lo aplica obj_actor_parent/Step. ✓
// spr_set(_spr) reinicia image_index solo cuando sprite_index cambia. ✓
//
// Prioridades (descendente):
//   1. Daño / knockback   → hitstun-gate hace exit antes; sin código aquí
//   2. Dash + cola visual → dash_start → dash_loop → dash_end
//   3. Espada / ataque    → placeholder  (spr_player_attack_* pendientes)
//   4. Arco / carga       → placeholder  (spr_player_bow pendiente)
//   5. Wall slide         → spr_player_wallslide
//   6. Salto   (vsp < 0)  → spr_player_jump  (congela último frame en apex)
//   7. Caída   (vsp ≥ 0)  → spr_player_fall  (loop)
//   8. Correr             → run_start → run_loop → run_end
//   9. Idle               → spr_player_idle_master
//
// player_anim_state = "air" cubre wall, jump y fall como slot compartido:
//   al aterrizar, "case air" del ground-switch transiciona a idle/run_loop.
// ══════════════════════════════════════════════════════════

// ── AFTERIMAGE SPAWN ─────────────────────────────────────
// Genera copias fantasma durante el dash.
// Corre ANTES de actualizar el sprite para capturar el frame del tick anterior
// (evita parpadeo en el primer frame del dash).
// El timer se resetea al entrar al dash y cuenta hacia 0 cada step.
if ((player_state == PSTATE.DASH || player_state == PSTATE.DASH_ATTACK || player_state == PSTATE.COUNTER_ATTACK) && afterimage_enabled) {
    afterimage_spawn_timer--;
    if (afterimage_spawn_timer <= 0) {
        afterimage_spawn();
        afterimage_spawn_timer = afterimage_spawn_rate;
    }
} else if (player_state != PSTATE.DASH && player_state != PSTATE.DASH_ATTACK && player_state != PSTATE.COUNTER_ATTACK) {
    // Resetear timer para que la primera copia aparezca inmediatamente
    // en el siguiente dash (sin esperar spawn_rate frames).
    afterimage_spawn_timer = 0;
}

// Resetear offset y tint visual cada frame; estados específicos los sobreescriben.
draw_x_offset = 0;
image_blend   = c_white;

if (player_state == PSTATE.DASH
||  player_anim_state == "dash_start"
||  player_anim_state == "dash_loop"
||  player_anim_state == "dash_end") {
    // ── Prioridad 2: dash (incluye cola visual post-física) ──
    // dash_start → once   al inicio
    // dash_loop  → loop   mientras PSTATE.DASH
    // dash_end   → once   al terminar (corre aunque player_state ya salió de DASH)
    switch (player_anim_state) {

        case "dash_start":
            if (player_state != PSTATE.DASH) {
                // Dash físico terminó antes de que dash_start acabara
                spr_set(spr_player_dash_end);
                player_anim_state = "dash_end";
            } else if (floor(image_index) >= image_number - 1) {
                spr_set(spr_player_dash_loop);
                player_anim_state = "dash_loop";
            }
        break;

        case "dash_loop":
            spr_set(spr_player_dash_loop);   // no-op si ya es este sprite
            if (player_state != PSTATE.DASH) {
                spr_set(spr_player_dash_end);
                player_anim_state = "dash_end";
            }
        break;

        case "dash_end":
            if (floor(image_index) >= image_number - 1) {
                // dash_end completado → resolver al estado visual correcto
                if (!isGrounded) {
                    // Prioridad: DOWN_SLASH activo → sprite de ataque descendente
                    if (player_state == PSTATE.DOWN_SLASH) {
                        if (move_y < 0) {
                            spr_set(spr_player_air_down_attack_2);
                        } else {
                            spr_set(spr_player_air_down_attack_1);
                        }
                        player_anim_state = "air_down_attack";
                    } else if (player_state == PSTATE.JUMP) {
                        spr_set(spr_player_jump);
                        player_anim_state = "air";
                    } else {
                        spr_set(spr_player_fall);
                        player_anim_state = "air";
                    }
                } else if (_dir != 0) {
                    spr_set(spr_player_run_loop);
                    player_anim_state = "run_loop";
                } else {
                    spr_set(spr_player_idle_master);
                    player_anim_state = "idle";
                }
            }
        break;

        default:
            // Entrada desde "idle", "run_*", "air" → arrancar secuencia
            spr_set(spr_player_dash_start);
            player_anim_state = "dash_start";
        break;
    }

} else if (_in_attack) {
    // ── Prioridad 3: espada / ataque ──────────────────────
    // spr_set() solo reinicia image_index si el sprite cambia,
    // por lo que la animación no se reinicia cada frame.
    // Al avanzar entre golpes (ATTACK_1 → ATTACK_2) el sprite
    // cambiará y se reiniciará el frame correctamente.
    switch (player_state) {

        case PSTATE.ATTACK_1:
            spr_set(spr_player_attack_1);
            player_anim_state = "attack_1";
        break;

        case PSTATE.ATTACK_2:
            // spr_set(spr_player_attack_2);   // asignar cuando exista
            // Fallback: conservar spr_player_attack_1 hasta tener el sprite
            spr_set(spr_player_attack_1);
            player_anim_state = "attack_2";
        break;

        case PSTATE.ATTACK_3:
            // spr_set(spr_player_attack_3);   // asignar cuando exista
            spr_set(spr_player_attack_1);
            player_anim_state = "attack_3";
        break;

        case PSTATE.DOWN_SLASH:
            // Sprite según velocidad vertical post-física (move_y actualizado por event_inherited):
            //   move_y >= 0  →  cayendo o en apex  → spr_player_air_down_attack_1
            //   move_y <  0  →  subiendo (rebote)  → spr_player_air_down_attack_2
            //
            // spr_set() solo cambia sprite_index cuando el sprite es distinto al actual,
            // preservando image_index y image_speed → animación continua sin glitches.
            // El cambio entre _1 y _2 reinicia la animación automáticamente porque
            // spr_set ve un sprite diferente; mientras se mantiene el mismo no se toca.
            if (move_y < 0) {
                spr_set(spr_player_air_down_attack_2);   // subiendo post-rebote
            } else {
                spr_set(spr_player_air_down_attack_1);   // cayendo o en apex
            }
            player_anim_state = "air_down_attack";
        break;

        case PSTATE.DASH_ATTACK:
            spr_set(spr_player_attack_1);   // placeholder hasta tener sprite dedicado
            player_anim_state = "dash_attack";
        break;

        case PSTATE.COUNTER_ATTACK:
            spr_set(spr_player_attack_1);   // placeholder — dedicar spr_player_counter cuando exista
            player_anim_state = "counter_attack";
            image_blend = c_orange;         // tinte naranja para distinguirlo del ataque normal
        break;
    }

} else if (bow_is_charging) {
    // ── Prioridad 4: arco cargando ────────────────────────
    // Placeholder — spr_player_bow pendiente.
    // Previene que jump/fall/wallslide sobreescriban el sprite
    // mientras el jugador apunta (relevante cuando esté en el aire).

} else if (_block_busy) {
    // ── Prioridad 4.5: block / parry ──────────────────────
    // Placeholder hasta tener spr_player_block y spr_player_parry.
    // Usa idle como base. El tint indica el estado defensivo.
    //   Amarillo (is_parrying)  → ventana perfecta activa
    //   Cian    (!is_parrying) → block normal activo
    spr_set(spr_player_idle_master);
    player_anim_state = "idle";
    image_blend = is_parrying ? c_yellow : c_aqua;

} else if (player_state == PSTATE.WALL) {
    // ── Prioridad 5: wall slide ───────────────────────────
    spr_set(spr_player_wallslide);
    player_anim_state = "air";   // slot compartido: "case air" gestiona el aterrizaje
    // Corregir flip del sprite: el parent aplica image_xscale = facing (hacia el muro).
    // Sobreescribir para que el personaje mire HACIA AFUERA del muro.
    //   wallSide =  1 (muro derecha) → image_xscale = -1 (mira izquierda, hacia afuera) ✓
    //   wallSide = -1 (muro izquierda) → image_xscale =  1 (mira derecha, hacia afuera) ✓
    // Si el sprite está diseñado para mirar hacia el muro, usar wallSide en lugar de -wallSide.
    image_xscale = -wallSide;
    // Compensar el desplazamiento lateral que produce el flip alrededor del origen del sprite.
    // image_xscale = -wallSide ya está asignado arriba.
    //   Muro derecha  (wallSide= 1): image_xscale=-1 → draw_x_offset = -offset (desplaza izq) ✓
    //   Muro izquierda(wallSide=-1): image_xscale= 1 → draw_x_offset = +offset (desplaza der) ✓
    // Un valor positivo de wallslide_sprite_offset_x aleja el sprite del muro en ambos casos.
    draw_x_offset = wallslide_sprite_offset_x * image_xscale;

} else if (!isGrounded) {
    // ── Prioridades 6 / 7: salto y caída ─────────────────
    player_anim_state = "air";

    if (player_state == PSTATE.JUMP) {
        // ── SALTO (vsp < 0) ───────────────────────────────
        // spr_set solo reinicia image_index cuando el sprite cambia
        // (p.ej. al salir de run/idle hacia JUMP).
        // Mientras PSTATE.JUMP continúe, es no-op → la animación avanza sola.
        spr_set(spr_player_jump);

        // Congelar en el último frame: pose de apex se mantiene hasta
        // que la física transita a PSTATE.FALL (que cambia el sprite a fall).
        if (floor(image_index) >= image_number - 1) {
            image_speed = 0;   // freeze — End Step respeta image_speed == 0
        } else {
            image_speed = global.time_scale;   // play a velocidad de tiempo actual
        }
    } else {
        // ── CAÍDA (vsp ≥ 0) — PSTATE.FALL, PSTATE.DOWN_SLASH cubierto por _in_attack ──
        // Loop continuo mientras cae.
        spr_set(spr_player_fall);
    }

} else {
    // ── Prioridades 8 / 9: suelo, sin ataque ni dash ─────
    switch (player_anim_state) {

        case "idle":
            spr_set(spr_player_idle_master);
            if (_dir != 0) {
                // Si ya está en PSTATE.RUN (salió de un ataque con vel activa),
                // saltar directo al loop sin repetir run_start.
                if (player_state == PSTATE.RUN) {
                    spr_set(spr_player_run_loop);
                    player_anim_state = "run_loop";
                } else {
                    spr_set(spr_player_run_start);
                    player_anim_state = "run_start";
                }
            }
        break;

        case "run_start":
            if (_dir == 0) {
                spr_set(spr_player_idle_master);
                player_anim_state = "idle";
            } else if (floor(image_index) >= image_number - 1) {
                spr_set(spr_player_run_loop);
                player_anim_state = "run_loop";
            }
        break;

        case "run_loop":
            spr_set(spr_player_run_loop);   // no-op si ya es este sprite
            if (_dir == 0) {
                spr_set(spr_player_run_end);
                player_anim_state = "run_end";
            }
        break;

        case "run_end":
            if (_dir != 0) {
                spr_set(spr_player_run_loop);
                player_anim_state = "run_loop";
            } else if (floor(image_index) >= image_number - 1) {
                spr_set(spr_player_idle_master);
                player_anim_state = "idle";
            }
        break;

        case "air":
            // Aterrizó (desde jump, fall, wall slide o dash_end) —
            // determinar estado visual correcto.
            if (_dir != 0) {
                spr_set(spr_player_run_loop);   // en movimiento → directo al loop
                player_anim_state = "run_loop";
            } else {
                spr_set(spr_player_idle_master);
                player_anim_state = "idle";
            }
        break;

        default:
            // Safety: estado visual desconocido → resetear
            spr_set(spr_player_idle_master);
            player_anim_state = "idle";
        break;
    }
}

// ── JUMP BACK: Desactivado — facing lock comentado ─────────
// if (jump_back_active && jump_back_facing_locked) {
//     facing = jump_back_stored_facing;
//     image_xscale = abs(image_xscale) * jump_back_stored_facing;
// }
// if (!jump_back_active && jump_back_facing_locked) {
//     jump_back_facing_locked = false;
// }
