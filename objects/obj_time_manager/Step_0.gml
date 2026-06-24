// ══════════════════════════════════════════════════════════
// OBJ_TIME_MANAGER — Step
// Controles de debug visual, dificultad y tiempo global en runtime.
//
// CONTROLES — Teclas numéricas (5-9) y Numpad opcional:
//   5 / Numpad5 = Debug Visual (colisiones, hitboxes, estado)
//   6 / Numpad6 = Dificultad Easy
//   7 / Numpad7 = Dificultad Normal
//   8 / Numpad8 = Dificultad Hard
//   9 / Numpad9 = Toggle HUD de Dificultad
// ══════════════════════════════════════════════════════════

// ── Helper: detectar tecla (row + numpad) ───────────────────
function check_key_or_numpad(_key, _numpad_key) {
    return keyboard_check_pressed(_key) || keyboard_check_pressed(_numpad_key);
}

// ── 5 / Numpad5 — Debug Visual Gameplay ─────────────────────
// Muestra: colisiones, hitboxes, máscara del player, estado
if (check_key_or_numpad(ord("5"), vk_numpad5)) {
    global.debug_collision_view = !global.debug_collision_view;
    global.debug_dev = global.debug_collision_view;  // sincronizar con debug_dev
    var _layer = layer_get_id(COLLISION_LAYER);
    if (_layer != -1) {
        layer_set_visible(_layer, global.debug_collision_view);
    }
    show_debug_message("[DEBUG VISUAL] " + (global.debug_collision_view ? "ON" : "OFF"));
}

// ── 6 / Numpad6 — Easy ──────────────────────────────────────
if (check_key_or_numpad(ord("6"), vk_numpad6)) {
    set_difficulty("easy");
    apply_difficulty_to_existing_objects();
    show_debug_message("[DIFFICULTY] EASY - Enemigos lentos, parry permisivo");
}

// ── 7 / Numpad7 — Normal ────────────────────────────────────
if (check_key_or_numpad(ord("7"), vk_numpad7)) {
    set_difficulty("normal");
    apply_difficulty_to_existing_objects();
    show_debug_message("[DIFFICULTY] NORMAL - Valores base");
}

// ── 8 / Numpad8 — Hard ──────────────────────────────────────
if (check_key_or_numpad(ord("8"), vk_numpad8)) {
    set_difficulty("hard");
    apply_difficulty_to_existing_objects();
    show_debug_message("[DIFFICULTY] HARD - Player muere en 2 golpes");
}

// ── 9 / Numpad9 — Toggle HUD de Dificultad ─────────────────
if (check_key_or_numpad(ord("9"), vk_numpad9)) {
    global.debug_difficulty = !global.debug_difficulty;
    show_debug_message("[DIFFICULTY HUD] " + (global.debug_difficulty ? "VISIBLE" : "HIDDEN"));
}
