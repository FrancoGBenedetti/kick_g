// ══════════════════════════════════════════════════════════
// TRIGGER ON COLLISION — Step
//
// Detección de colisión con activator_object + emisión de señal por
// flanco (solo al entrar en contacto, no cada frame que se solapan).
// ══════════════════════════════════════════════════════════

if (!global.do_step) exit;

if (!enabled) exit;
if (used && trigger_once) exit;

var _activator = trigger_find_activator();

if (_activator != noone && !was_touching_activator) {
    trigger_emit_signal(_activator);
    if (trigger_once) used = true;
}

was_touching_activator = (_activator != noone);
