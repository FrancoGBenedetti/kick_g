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
