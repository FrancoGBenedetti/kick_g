// Begin Step — corre ANTES de todos los Step events del frame.
// Actualiza global.do_step para que cualquier objeto lo lea en su Step.
//
// Acumulador fraccionario:
//   time_scale = 1.0  →  step_accum +1.0 cada frame   →  do_step true siempre
//   time_scale = 0.2  →  step_accum +0.2 cada frame   →  do_step true 1/5 frames
//   time_scale = 0.0  →  step_accum +0.0              →  do_step false siempre (congelado)

global.step_accum += global.time_scale;
global.do_step     = (global.step_accum >= 1.0);

if (global.do_step) {
    global.step_accum -= 1.0;
    // Limitar acumulación negativa por si time_scale cambia abruptamente.
    if (global.step_accum < 0) global.step_accum = 0;
}
