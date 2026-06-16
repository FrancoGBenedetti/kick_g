// ══════════════════════════════════════════════════════════
// obj_dash_afterimage — Create
//
// Captura los parámetros visuales del player en el frame de spawn.
// Spawneado por obj_player mientras player_state == PSTATE.DASH.
//
// NO modificar manualmente — se inicializa vía afterimage_spawn()
// en obj_player/Create_0.gml (función closure que lee el estado actual).
// ══════════════════════════════════════════════════════════

// ── Datos visuales capturados del player en el momento del spawn ──
ghost_sprite  = -1;    // sprite_index del player al spawnear
ghost_frame   = 0;     // image_index exacto (puede ser decimal — draw redondea)
ghost_xscale  = 1;     // image_xscale (facing + flip)
ghost_yscale  = 1;     // image_yscale
ghost_angle   = 0;     // image_angle
ghost_alpha   = 0.6;   // alpha inicial — sobreescrito por afterimage_spawn()
ghost_color   = c_white; // tinte — sobreescrito por afterimage_spawn()
ghost_fade    = 0.07;  // velocidad de fade — sobreescrito por afterimage_spawn()

// ── Profundidad: siempre detrás del player ────────────────
// depth mayor = dibujado antes = aparece detrás en pantalla.
// Se sobreescribe en afterimage_spawn() con owner.depth + 1.
depth = 1;

// ── Sin sprite propio — el Draw usa ghost_sprite directamente ──
// visible = false en el .yy → no usa draw_self(); solo Draw_0 custom.
