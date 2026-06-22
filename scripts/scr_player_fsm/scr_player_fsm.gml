// ── ESTADOS DEL PLAYER ────────────────────────────────────
enum PSTATE {
    IDLE,     // en suelo, sin input horizontal
    RUN,      // en suelo, moviéndose
    JUMP,     // en aire, subiendo (move_y < 0)
    FALL,     // en aire, bajando o en apex
    WALL,     // en aire, contacto lateral con pared
    DASH,     // dash activo — input bloqueado, velocidad forzada

    // ── Combate cuerpo a cuerpo ──────────────────────────
    // Cada estado representa un golpe del combo de espada.
    // El timer y la ventana de combo se gestionan en Step_0.
    // Hooks futuros:
    //   • PARRY: desde ATTACK_1/2/3, si se recibe daño durante
    //     los primeros parry_window_frames → activar parry.
    //   • HIT STOP: llamar time_set(0.0) por N frames en on_hit().
    //   • CANCEL: dash puede interrumpir ATTACK_1 (añadir en _can_attack).
    ATTACK_1,   // primer golpe del combo
    ATTACK_2,   // segundo golpe del combo
    ATTACK_3,   // tercer golpe — cierra el combo

    // ── Ataque aéreo ─────────────────────────────────────
    // Activado con ↓ + Z mientras el jugador está en el aire.
    // Si impacta un objetivo, aplica un rebote hacia arriba (pogo).
    DOWN_SLASH, // ataque hacia abajo — activo hasta impacto, cancelación o aterrizaje

    // ── Defensa ───────────────────────────────────────────
    // Activado al presionar kb_block (tecla C).
    // Los primeros PARRY_WINDOW_FRAMES son ventana de parry perfecto.
    // Después de la ventana: block normal (niega daño frontal).
    // Bloqueado durante ataque, arco y dash.
    // Dejar: can_counterattack = true para contraataque futuro.
    BLOCK,      // bloqueando — parry window activa los primeros frames

    // ── Dash Attack ───────────────────────────────────────
    // Activado al presionar ataque durante un PSTATE.DASH activo
    // (una vez por dash; se resetea al iniciar un dash nuevo).
    // Mantiene la velocidad y dirección del dash.
    // Daño = sword_damage_1 × dash_attack_damage_mult (default ×2).
    DASH_ATTACK, // ataque durante dash — velocidad conservada, hitbox única

    // ── Counter Attack ────────────────────────────────────
    // Activado al presionar ataque durante la ventana post-parry.
    // El player se lanza automáticamente hacia counter_target.
    // Requiere ability_counterattack = true.
    COUNTER_ATTACK, // dash automático hacia el enemigo parryeado
}

// ─────────────────────────────────────────────────────────
// player_set_state(_new_state)
// Centraliza la lógica de entrada/salida de cada estado.
// Llamar siempre desde obj_player — nunca asignar player_state
// directamente para garantizar que los hooks se ejecuten.
// ─────────────────────────────────────────────────────────
function player_set_state(_new_state) {
    if (player_state == _new_state) exit;

    // ── EXIT ─────────────────────────────────────────────
    switch (player_state) {
        case PSTATE.IDLE: break;
        case PSTATE.RUN:  break;
        case PSTATE.JUMP: break;
        case PSTATE.FALL: break;

        case PSTATE.WALL:
            max_fall = fall_max_default;
        break;

        case PSTATE.DASH:
            // Cortar momentum: sin vel_x residual a dash_speed al volver al control normal.
            vel_x = clamp(vel_x, -max_walk_speed, max_walk_speed);
        break;

        case PSTATE.BLOCK:
            is_blocking        = false;
            is_parrying        = false;
            parry_window_timer = 0;
        break;

        case PSTATE.ATTACK_1:
        case PSTATE.ATTACK_2:
        case PSTATE.ATTACK_3:
        case PSTATE.DOWN_SLASH:
            // Destruir hitbox si todavía existe al salir del estado.
            // Ocurre al avanzar combo, recibir dash-cancel, terminar el golpe
            // o cancelar el pogo (soltar ↓, aterrizaje, daño recibido).
            if (instance_exists(sword_hitbox_id)) {
                with (sword_hitbox_id) {
                    ds_list_destroy(hit_list);
                    instance_destroy();
                }
            }
            sword_hitbox_id  = noone;
            has_pogo_bounced = false;  // estado limpio para el próximo ataque
        break;

        case PSTATE.DASH_ATTACK:
            // Destruir hitbox si todavía existe al salir del estado.
            if (instance_exists(sword_hitbox_id)) {
                with (sword_hitbox_id) {
                    ds_list_destroy(hit_list);
                    instance_destroy();
                }
            }
            sword_hitbox_id = noone;
            // Cortar momentum al volver al control normal.
            vel_x = clamp(vel_x, -max_walk_speed, max_walk_speed);
        break;

        case PSTATE.COUNTER_ATTACK:
            if (instance_exists(sword_hitbox_id)) {
                with (sword_hitbox_id) {
                    ds_list_destroy(hit_list);
                    instance_destroy();
                }
            }
            sword_hitbox_id       = noone;
            counter_attack_active = false;
            counter_target        = noone;
            vel_x = clamp(vel_x, -max_walk_speed, max_walk_speed);
        break;
    }

    player_state = _new_state;

    // ── ENTER ────────────────────────────────────────────
    switch (player_state) {
        case PSTATE.IDLE:
        case PSTATE.RUN:
            can_air_dash     = true;   // aterrizó → restaurar air dash
            dash_jump_active = false;  // aterrizó → terminar boost MMX4
        break;

        case PSTATE.JUMP: break;
        case PSTATE.FALL: break;

        case PSTATE.WALL:
            dash_jump_active = false;  // pared cancela el boost
            can_air_dash     = true;   // wallslide = contacto válido → restaurar dash aéreo
        break;
        case PSTATE.DASH:
            // Afterimage: resetear timer para que la primera copia
            // aparezca en el frame 0 del dash (spawn_timer = 0 → spawn inmediato).
            afterimage_spawn_timer = 0;
        break;

        case PSTATE.BLOCK:
            // Activado en sección always de Step (responde al press de C).
            // is_parrying e is_blocking se sincronizan en la sección always.
            is_blocking        = true;
            parry_window_timer = PARRY_WINDOW_FRAMES;
            can_counterattack  = false;
            counterattack_timer = 0;
        break;

        case PSTATE.ATTACK_1:
            // HOOK FUTURO — parry:
            //   Si en los primeros parry_window_1 frames se detecta
            //   que el jugador recibió daño (on_damage disparado),
            //   llamar player_set_state(PSTATE.PARRY).
            combo_step        = 1;
            attack_timer      = attack_1_frames;
            attack_buffer     = false;   // consumir el press que activó este golpe
            action_lock_timer = sword_lock_frames;   // ventana de compromiso — bloquea arco
        break;

        case PSTATE.DOWN_SLASH:
            // attack_timer controla la duración máx. del estado.
            // La hitbox se spawnea en el primer frame (ver Step_0 de obj_player).
            // has_pogo_bounced se resetea aquí Y en el exit hook (doble garantía).
            attack_timer      = down_slash_frames;
            attack_buffer     = false;
            has_pogo_bounced  = false;
            bounce_count      = 0;   // reiniciar contador de rebotes de esta sesión
            action_lock_timer = sword_lock_frames;
        break;

        case PSTATE.ATTACK_2:
            combo_step        = 2;
            attack_timer      = attack_2_frames;
            attack_buffer     = false;
            action_lock_timer = sword_lock_frames;   // cada golpe renueva el compromiso
        break;

        case PSTATE.ATTACK_3:
            combo_step        = 3;
            attack_timer      = attack_3_frames;
            attack_buffer     = false;
            action_lock_timer = sword_lock_frames;
        break;

        case PSTATE.DASH_ATTACK:
            attack_timer      = attack_1_frames;
            attack_buffer     = false;
            action_lock_timer = sword_lock_frames;
            dash_attack_used  = true;
            afterimage_spawn_timer = 0;
        break;

        case PSTATE.COUNTER_ATTACK:
            attack_timer          = counter_dash_duration;
            attack_buffer         = false;
            action_lock_timer     = sword_lock_frames;
            counter_attack_active = true;
            can_counterattack     = false;
            counterattack_timer   = 0;
            parry_slow_timer      = 0;   // cancelar slow-mo → tiempo real restaurado
            afterimage_spawn_timer = 0;
            // Apuntar automáticamente hacia el target
            if (instance_exists(counter_target)) {
                var _ct_dir = sign(counter_target.x - x);
                if (_ct_dir == 0) _ct_dir = facing;
                facing = _ct_dir;
            }
        break;
    }
}
