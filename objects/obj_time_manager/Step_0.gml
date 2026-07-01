// ══════════════════════════════════════════════════════════
// OBJ_TIME_MANAGER — Step
// Controles de debug visual, dificultad y tiempo global en runtime.
//
// CONTROLES — Teclas QWERTY:
//   Y = Debug Visual (colisiones, hitboxes, estado)
//   E = Dificultad Easy
//   R = Dificultad Normal
//   T = Dificultad Hard
// ══════════════════════════════════════════════════════════

// ── SLOW MOTION TIMER ──────────────────────────────────────
// Actualizar timer y restaurar velocidad normal cuando termina
if (global.slowmo_active) {
    global.slowmo_timer--;
    if (global.slowmo_timer <= 0) {
        global.slowmo_active = false;
        global.slowmo_scale_temporary = 1.0;
        global.time_scale = 1.0;  // Restaurar velocidad normal
    }
}

// ── Y — Debug Visual Gameplay ────────────────────────────────
// Muestra: colisiones, hitboxes, máscara del player, estado
if (keyboard_check_pressed(ord("Y"))) {
    global.debug_collision_view = !global.debug_collision_view;
    global.debug_dev = global.debug_collision_view;  // sincronizar con debug_dev
    var _layer = layer_get_id(COLLISION_LAYER);
    if (_layer != -1) {
        layer_set_visible(_layer, global.debug_collision_view);
    }
    show_debug_message("[DEBUG VISUAL] " + (global.debug_collision_view ? "ON" : "OFF"));
}

// ── I — Toggle collision tiles visible/invisible ──────────────
if (keyboard_check_pressed(ord("I"))) {
    var _layer = layer_get_id(COLLISION_LAYER);
    if (_layer != -1) {
        var _visible = !layer_get_visible(_layer);
        layer_set_visible(_layer, _visible);
        show_debug_message("[COLLISION TILES] " + (_visible ? "VISIBLE" : "INVISIBLE"));
    }
}

// ── E — Easy ─────────────────────────────────────────────────
if (keyboard_check_pressed(ord("E"))) {
    set_difficulty("easy");
    apply_difficulty_to_existing_objects();
    show_debug_message("[DIFFICULTY] EASY - Enemigos lentos, parry permisivo");
}

// ── R — Normal ───────────────────────────────────────────────
if (keyboard_check_pressed(ord("R"))) {
    set_difficulty("normal");
    apply_difficulty_to_existing_objects();
    show_debug_message("[DIFFICULTY] NORMAL - Valores base");
}

// ── T — Hard ────────────────────────────────────────────────
if (keyboard_check_pressed(ord("T"))) {
    set_difficulty("hard");
    apply_difficulty_to_existing_objects();
    show_debug_message("[DIFFICULTY] HARD - Player muere en 1-2 golpes");
}
