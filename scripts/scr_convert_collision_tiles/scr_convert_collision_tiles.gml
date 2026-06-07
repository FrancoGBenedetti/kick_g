// ══════════════════════════════════════════════════════════
// scr_convert_collision_tiles()
// Convierte la capa de colisión de tiles 64×64 a tiles 32×32.
//
// CÓMO USAR:
//   1. Crear la capa "tiles_collision_32" con tileset 32×32 en Room1.
//   2. Llamar esta función UNA SOLA VEZ desde Room Start del Room1:
//        scr_convert_collision_tiles();
//   3. Verificar que las colisiones funcionan.
//   4. ELIMINAR la llamada (o comentarla) — si se ejecuta dos veces
//      sobreescribe lo escrito pero no causa error.
//   5. Cuando el nivel esté listo para producción:
//      a. Exportar/guardar Room1 con ambas capas activas.
//      b. Eliminar la capa "tiles_collision" (64×64) del room.
//      c. Renombrar "tiles_collision_32" → "tiles_collision".
//      d. Actualizar layer_get_id en Create de todos los actores
//         SI el nombre cambió (si usas "tiles_collision" para ambas
//         no hace falta cambiar nada en el código).
//
// QUÉ HACE:
//   Lee cada celda de 32×32 del room.
//   Para cada celda, consulta si el tilemap 64×64 tiene tile en ese punto.
//   Si sí → coloca tile sólido (índice 1) en el nuevo tilemap 32×32.
//   Si no → deja la celda vacía.
//
// RESULTADO:
//   Un tile 64×64 en la capa vieja → 4 tiles 32×32 en la capa nueva
//   (2×2 celdas en el mismo espacio físico). Geometría idéntica.
//
// PRECONDICIONES:
//   • Layer "tiles_collision"    existe y tiene tileset 64×64
//   • Layer "tiles_collision_32" existe y tiene tileset 32×32
//   • Ambas capas cubren el mismo room
// ══════════════════════════════════════════════════════════

function scr_convert_collision_tiles() {

    // ── Obtener los dos tilemaps ───────────────────────────
    var _layer_old = layer_get_id("tiles_collision");
    var _layer_new = layer_get_id("tiles_collision_32");

    if (_layer_old == -1) {
        show_debug_message("[CONVERT] ERROR: capa 'tiles_collision' no encontrada.");
        return false;
    }
    if (_layer_new == -1) {
        show_debug_message("[CONVERT] ERROR: capa 'tiles_collision_32' no encontrada.");
        show_debug_message("          Crear la capa en Room1 antes de ejecutar este script.");
        return false;
    }

    var _map_old = layer_tilemap_get_id(_layer_old);
    var _map_new = layer_tilemap_get_id(_layer_new);

    if (_map_old == -1 || _map_new == -1) {
        show_debug_message("[CONVERT] ERROR: no se pudo obtener tilemap de las capas.");
        return false;
    }

    // ── Parámetros ────────────────────────────────────────
    var _step    = 32;           // tamaño del tile nuevo
    var _half    = _step / 2;    // offset al centro del tile (16 px)
    var _solid   = 1;            // índice del tile sólido en el nuevo tileset
    var _written = 0;
    var _read    = 0;

    // ── Escaneo y conversión ──────────────────────────────
    // Para cada celda 32×32 del room:
    //   • Consulta si el tilemap viejo (64×64) tiene tile en el CENTRO de la celda.
    //   • tilemap_get_at_pixel devuelve 0 si no hay tile, != 0 si hay tile.
    //   • El centro garantiza que no falseamos en los bordes de tile 64×64.
    //
    // Ejemplo: tile 64×64 en col=2, row=1 cubre píxeles (128,64)→(191,127).
    //   Celda 32×32 en (128,64): centro en (144,80) → dentro del tile → sólido ✓
    //   Celda 32×32 en (160,64): centro en (176,80) → dentro del tile → sólido ✓
    //   Celda 32×32 en (128,96): centro en (144,112) → dentro del tile → sólido ✓
    //   Celda 32×32 en (160,96): centro en (176,112) → dentro del tile → sólido ✓

    for (var _y = 0; _y < room_height; _y += _step) {
        for (var _x = 0; _x < room_width; _x += _step) {
            _read++;
            var _sample_x = _x + _half;
            var _sample_y = _y + _half;
            var _tile_val = tilemap_get_at_pixel(_map_old, _sample_x, _sample_y);

            if (_tile_val != 0) {
                tilemap_set_at_pixel(_map_new, _solid, _x, _y);
                _written++;
            }
        }
    }

    show_debug_message("[CONVERT] Conversión completada.");
    show_debug_message("          Celdas leídas: "   + string(_read));
    show_debug_message("          Tiles escritos: "  + string(_written));
    show_debug_message("          Cobertura 32×32: " + string(_written * 32 * 32) + " px²");
    show_debug_message("");
    show_debug_message("[CONVERT] Siguiente paso:");
    show_debug_message("          1. Verificar colisiones visualmente (activa debug_collision).");
    show_debug_message("          2. Si OK → eliminar la llamada a scr_convert_collision_tiles().");
    show_debug_message("          3. Actualizar los actores para usar 'tiles_collision_32'.");

    return true;
}
