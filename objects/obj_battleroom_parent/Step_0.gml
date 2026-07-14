// ══════════════════════════════════════════════════════════
// BATTLEROOM PARENT — Step
//
// Máquina de estados de la BattleRoom. Cada estado delega su lógica
// a una función battleroom_state_xxx() definida en el Create Event.
// Las transiciones SIEMPRE pasan por battleroom_set_state(), nunca
// se asigna battleroom_state directamente acá.
// ══════════════════════════════════════════════════════════

if (!global.do_step) exit;   // respeta el slow motion global (igual que player/enemigos)

state_timer++;

// ── Countdown de debug del freeze de entrada ──────────────
// No controla el lock real (eso lo hace el player con su propio
// damage_recovery_lock_timer) — solo permite loguear el momento en que el
// player recupera el control, ver battleroom_freeze_player_for_start().
if (player_freeze_debug_timer > 0) {
    player_freeze_debug_timer--;
    if (player_freeze_debug_timer <= 0 && battleroom_is_debug()) {
        show_debug_message("[BATTLEROOM START] player released");

        // Diagnóstico: si acá damage_recovery_lock sigue en true, el
        // freeze de entrada NO es la causa de que el player siga sin
        // responder — algo más lo volvió a lockear (típicamente daño de
        // un enemigo ya spawneado). Esto separa "bug del freeze" de
        // "el player está en combate" sin adivinar.
        if (instance_exists(obj_player)) {
            var _p_rel = instance_find(obj_player, 0);
            var _still_locked = variable_instance_exists(_p_rel, "damage_recovery_lock") && _p_rel.damage_recovery_lock;

            show_debug_message("[BATTLEROOM ENTRY] player after release: " + string(round(_p_rel.x)) + "," + string(round(_p_rel.y))
                + "  vel=" + string(variable_instance_exists(_p_rel, "vel_x") ? round(_p_rel.vel_x) : 0) + ","
                          + string(variable_instance_exists(_p_rel, "vel_y") ? round(_p_rel.vel_y) : 0)
                + "  isGrounded=" + string(variable_instance_exists(_p_rel, "isGrounded") ? _p_rel.isGrounded : "n/a")
                + "  damage_recovery_lock=" + string(_still_locked));

            if (_still_locked) {
                show_debug_message("[BATTLEROOM WARNING] player sigue con damage_recovery_lock=true después del freeze de entrada — no es el freeze de BattleRoom, algo más lo volvió a activar (revisar daño/knockback de un enemigo).");
            }
        }
    }
}

switch (battleroom_state) {

    case BattleRoomState.WAITING:
        battleroom_state_waiting();
    break;

    case BattleRoomState.ENTERING:
        battleroom_state_entering();
    break;

    case BattleRoomState.SPAWNING:
        battleroom_state_spawning();
    break;

    case BattleRoomState.ACTIVE:
        battleroom_state_active();
    break;

    case BattleRoomState.CLEARING:
        battleroom_state_clearing();
    break;

    case BattleRoomState.REWARD:
        battleroom_state_reward();
    break;

    case BattleRoomState.FINISHED:
        battleroom_state_finished();
    break;
}
