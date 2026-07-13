// ══════════════════════════════════════════════════════════
// BATTLEROOM WALL — Create
//
// Pared temporal e invisible que bloquea al player durante una BattleRoom.
//
// El proyecto NO usa el `solid` nativo de GameMaker para colisión — usa un
// sistema propio: level_solid_at() (scripts/level_solid_at) consulta el
// tilemap Y recorre obj_dynamic_solid_parent buscando instancias con
// dynamic_solid_enabled == true cuyo dynamic_solid_contains_point() de
// verdadero. Por eso este objeto hereda de obj_dynamic_solid_parent —
// mismo patrón que ya usa obj_pivot_bridge para su colisión dinámica. No
// hace falta (ni corresponde) usar `solid`, place_meeting ni ninguna
// colisión paralela.
//
// battleroom_lock_player_progress() (obj_battleroom_parent) crea estas
// instancias sin pasarle nada por Creation Code, así que este objeto se
// autoconfigura con defaults razonables y expone wall_configure() para que
// el creador ajuste el alto real de la arena después de crear la instancia.
// ══════════════════════════════════════════════════════════

event_inherited();   // dynamic_solid_enabled/xoff/yoff/w/h + dynamic_solid_contains_point()

owner_battleroom = noone;   // instancia de obj_battleroom_parent dueña de esta pared
wall_id          = "";      // etiqueta libre para debug (p.ej. "battle_test_01_wall_left")

// (x, y) es la esquina superior izquierda del rectángulo sólido — misma
// convención que los spawn markers de este proyecto (no depende de sprite
// ni origin). El rectángulo va de (x,y) a (x+wall_width, y+wall_height).
wall_width  = TILE_SIZE;       // grosor horizontal — TILE_SIZE (scr_config.gml), no un número mágico suelto
wall_height = TILE_SIZE * 8;   // alto por defecto; battleroom_lock_player_progress() lo ajusta a la arena real

debug_visible      = true;   // si ESTA pared en particular puede mostrarse en debug
is_battleroom_wall = true;   // marca de identidad, útil para queries/debug futuros

dynamic_solid_enabled = true;
dynamic_solid_xoff    = 0;
dynamic_solid_yoff    = 0;
dynamic_solid_w       = wall_width;
dynamic_solid_h       = wall_height;

/// @desc Reconfigura tamaño (y por lo tanto el rectángulo sólido). Llamar
/// después de instance_create_layer(), porque battleroom_lock_player_
/// progress() no puede pasar variables en la creación misma.
wall_configure = function(_width, _height) {
    wall_width  = _width;
    wall_height = _height;

    dynamic_solid_w = wall_width;
    dynamic_solid_h = wall_height;
};
