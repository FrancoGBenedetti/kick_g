// ══════════════════════════════════════════════════════════
// BATTLEROOM TRIGGER — Step
//
// Detección de colisión con obj_player + activación por flanco
// (solo al entrar en contacto, no cada frame que se solapan).
// ══════════════════════════════════════════════════════════

if (!global.do_step) exit;

if (!enabled) exit;
if (used && trigger_once) exit;

var _touching = battleroom_trigger_check_player();

if (_touching && !was_touching_player) {
    battleroom_trigger_activate();
}

was_touching_player = _touching;
