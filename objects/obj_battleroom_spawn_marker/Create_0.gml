// ══════════════════════════════════════════════════════════
// BATTLEROOM SPAWN MARKER — Create
//
// Marker de configuración para colocar a mano en el Room Editor.
// Define DÓNDE y QUÉ debe spawnear una BattleRoom, pero no spawnea
// nada por sí solo — eso lo hace obj_battleroom_parent en
// battleroom_spawn_enemies(), buscando todos los markers que
// compartan su battleroom_id (o spawn_group_id).
//
// Este objeto es solo datos + debug visual. No busca BattleRooms,
// no cuenta enemigos, no toca cámara/paredes/música/recompensa.
// ══════════════════════════════════════════════════════════

// ── Configuración principal ───────────────────────────────
battleroom_id = "";          // conecta el marker con obj_battleroom_parent.battleroom_id
enemy_object  = noone;       // objeto enemigo genérico a spawnear (obj_enemy_swordsman, etc.)
spawn_layer   = "Instances"; // layer donde se creará el enemigo — layer real del proyecto
spawn_delay   = 0;           // frames antes de crear el enemigo (0 = inmediato). Aplicado en el paso siguiente.

face_player_on_spawn = true; // si el enemigo debe mirar al jugador al aparecer

enabled       = true;        // si es false, este marker se ignora al spawnear
debug_enabled = false;       // debug local — también responde al flag global F1 (debug_battleroom)

// ── Opcionales ─────────────────────────────────────────────
spawn_effect_enabled = false;   // si crear un efecto visual al spawnear
spawn_effect_object  = noone;   // objeto de efecto (partícula, flash, etc.)

spawn_once = true;    // si el marker solo debe usarse una vez (relevante si la sala se puede reiniciar)
used       = false;   // lo marcará el parent cuando lo consuma, en el paso siguiente

initial_facing = 0;   // 0 = auto (según face_player_on_spawn), -1 = izquierda, 1 = derecha
marker_name    = "";  // etiqueta libre para identificar el marker en debug (no es battleroom_id)


// ════════════════════════════════════════════════════════════
// FUNCIONES INTERNAS
// ════════════════════════════════════════════════════════════

/// @desc true si el debug del marker está activo (local o global, mismo flag
/// que obj_battleroom_parent/obj_battleroom_trigger — F1 en obj_input).
marker_is_debug = function() {
    return debug_enabled || (variable_global_exists("debug_battleroom") && global.debug_battleroom);
};

/// @desc Warnings de configuración común. Se corre una sola vez al crear el
/// marker (no repite en Step porque el marker no tiene Step — es solo datos).
marker_validate = function() {
    if (!marker_is_debug()) return;

    if (battleroom_id == "") {
        show_debug_message("[SPAWN MARKER] warning: battleroom_id is empty");
    }
    if (enemy_object == noone) {
        show_debug_message("[SPAWN MARKER] warning: enemy_object is noone");
    }
    if (spawn_layer == "") {
        show_debug_message("[SPAWN MARKER] warning: spawn_layer is empty");
    }
};

/// @desc Dibuja el marker (cruz + texto de config) solo si el debug está activo.
/// Llamar desde Draw (world space) — ver Draw_0.gml.
marker_debug_draw = function() {
    if (!marker_is_debug()) return;

    var _col = enabled ? c_aqua : c_gray;

    draw_set_alpha(0.85);
    draw_set_color(_col);
    draw_line(x - 12, y, x + 12, y);
    draw_line(x, y - 12, x, y + 12);
    draw_circle(x, y, 10, true);
    draw_set_alpha(1);

    var _enemy_name = (enemy_object == noone) ? "none" : object_get_name(enemy_object);

    draw_set_color(c_white);
    draw_text(x + 16, y - 34, "[Spawn Marker]");
    draw_text(x + 16, y - 20, "ID: " + battleroom_id);
    draw_text(x + 16, y - 6,  "Enemy: " + _enemy_name);
    draw_text(x + 16, y + 8,  "Delay: " + string(spawn_delay));
};

marker_validate();
