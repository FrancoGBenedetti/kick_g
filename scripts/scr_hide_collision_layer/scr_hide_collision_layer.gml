// ══════════════════════════════════════════════════════════
// scr_hide_collision_layer()
// Oculta la capa de colisión al iniciar un room para que no
// sea visible en gameplay, pero sin afectar la colisión física.
//
// Llamar desde:
//   • obj_time_manager Create   → primer room (siempre visible=false)
//   • obj_time_manager RoomStart → rooms siguientes
//   • obj_camera_controller     → al presionar tecla H (toggle)
//
// La visibilidad se controla con global.debug_collision_view:
//   false (default) → capa invisible en gameplay
//   true            → capa visible (toggle con tecla H)
//
// La colisión sigue funcionando porque layer_tilemap_get_id()
// y tilemap_get_at_pixel() NO dependen de la visibilidad del layer.
// ══════════════════════════════════════════════════════════

function scr_hide_collision_layer() {
    var _layer = layer_get_id(COLLISION_LAYER);
    if (_layer == -1) {
        show_debug_message("[LAYERS] scr_hide_collision_layer: layer '" + COLLISION_LAYER + "' no encontrada — verificar nombre en scr_config.gml (macro COLLISION_LAYER).");
        exit;
    }
    layer_set_visible(_layer, global.debug_collision_view);
    show_debug_message("[LAYERS] Collision layer '" + COLLISION_LAYER + "' visible=" + string(global.debug_collision_view));
}
