// Puente visual que reutiliza la señal y detección del trigger genérico.
event_inherited();

bridge_intact_sprite = spr_battleroom_bridge_intact;
bridge_broken_sprite = spr_battleroom_bridge_broken;
bridge_current_sprite = bridge_intact_sprite;

bridge_visual_width = 1088;
bridge_visual_yoff = 0;
bridge_broken_alpha_bottom = 785;

bridge_broken = false;
bridge_settled = false;
bridge_fall_speed = 0;
bridge_gravity = 0.65;
bridge_max_fall_speed = 16;
bridge_drop_edge_margin = 96;
bridge_player_fall_speed = 1;
bridge_drop_ready = false;

trigger_w = bridge_visual_width;
trigger_h = 128;

bridge_collision_map = layer_tilemap_get_id(layer_get_id(COLLISION_LAYER));

// Componente sólido: existe solo para que level_solid_at() permita caminar
// sobre el puente mientras está entero.
bridge_solid = instance_create_layer(x, y, layer, obj_dynamic_solid_parent);
bridge_solid.owner_bridge = id;
bridge_solid.dynamic_solid_enabled = true;

bridge_sync_solid = function() {
    if (!instance_exists(bridge_solid)) return;

    bridge_solid.x = x;
    bridge_solid.y = y;
    bridge_solid.dynamic_solid_xoff = -bridge_visual_width * 0.5;
    bridge_solid.dynamic_solid_yoff = 0;
    bridge_solid.dynamic_solid_w = bridge_visual_width;
    bridge_solid.dynamic_solid_h = 24;
    bridge_solid.dynamic_solid_enabled = !bridge_broken;
};

/// @desc Solo permite activar la trampa cuando el player ya no quedaría
/// sostenido por el borde del escenario al desaparecer el puente.
bridge_activator_can_drop = function(_activator) {
    if (!instance_exists(_activator)) return false;
    if (!instance_exists(bridge_solid)) return false;
    if (bridge_collision_map == -1) return false;

    var _safe_left = x - bridge_visual_width * 0.5 + bridge_drop_edge_margin;
    var _safe_right = x + bridge_visual_width * 0.5 - bridge_drop_edge_margin;

    if (_activator.bbox_left < _safe_left || _activator.bbox_right > _safe_right) {
        return false;
    }

    var _col_left = variable_instance_exists(_activator, "col_left")
        ? _activator.col_left : _activator.bbox_left - _activator.x;
    var _col_right = variable_instance_exists(_activator, "col_right")
        ? _activator.col_right : _activator.bbox_right - _activator.x;
    var _col_bottom = variable_instance_exists(_activator, "col_bottom")
        ? _activator.col_bottom : _activator.bbox_bottom - _activator.y;

    var _probe_y = _activator.y + _col_bottom + 1;
    var _was_bridge_enabled = bridge_solid.dynamic_solid_enabled;

    // Consultar el nivel como quedaría exactamente después de romperse.
    bridge_solid.dynamic_solid_enabled = false;
    var _has_other_support = level_solid_at(bridge_collision_map, _activator.x + _col_left + 1, _probe_y)
        || level_solid_at(bridge_collision_map, _activator.x, _probe_y)
        || level_solid_at(bridge_collision_map, _activator.x + _col_right - 1, _probe_y);
    bridge_solid.dynamic_solid_enabled = _was_bridge_enabled;

    return !_has_other_support;
};

bridge_break = function(_activator = noone) {
    if (bridge_broken) return;

    bridge_broken = true;
    bridge_current_sprite = bridge_broken_sprite;
    bridge_fall_speed = 0;

    if (instance_exists(bridge_solid)) {
        bridge_solid.dynamic_solid_enabled = false;
    }

    if (instance_exists(_activator)) {
        if (variable_instance_exists(_activator, "move_y")) {
            _activator.move_y = max(_activator.move_y, bridge_player_fall_speed);
        }
        if (variable_instance_exists(_activator, "isGrounded")) {
            _activator.isGrounded = false;
        }
        if (variable_instance_exists(_activator, "isFalling")) {
            _activator.isFalling = true;
        }
    }
};

bridge_hits_floor = function(_candidate_y) {
    if (bridge_collision_map == -1) return false;

    var _sprite_w = max(sprite_get_width(bridge_broken_sprite), 1);
    var _scale = bridge_visual_width / _sprite_w;
    var _origin_y = sprite_get_yoffset(bridge_broken_sprite);
    var _probe_y = _candidate_y + bridge_visual_yoff
        + (bridge_broken_alpha_bottom - _origin_y) * _scale + 1;
    var _probe_xoff = bridge_visual_width * 0.26;

    return level_solid_at(bridge_collision_map, x - _probe_xoff, _probe_y)
        || level_solid_at(bridge_collision_map, x, _probe_y)
        || level_solid_at(bridge_collision_map, x + _probe_xoff, _probe_y);
};

bridge_update_trigger = function() {
    if (!enabled) return;
    if (used && trigger_once) return;

    var _activator = trigger_find_activator();
    var _drop_ready = (_activator != noone) && bridge_activator_can_drop(_activator);

    if (_drop_ready && !bridge_drop_ready) {
        trigger_emit_signal(_activator);
        bridge_break(_activator);
        if (trigger_once) used = true;
    }

    bridge_drop_ready = _drop_ready;
    was_touching_activator = (_activator != noone);
};

bridge_update_fall = function() {
    if (!bridge_broken || bridge_settled) return;

    bridge_fall_speed = min(bridge_fall_speed + bridge_gravity, bridge_max_fall_speed);

    var _remaining = bridge_fall_speed;
    while (_remaining > 0) {
        var _move = min(_remaining, 1);

        if (bridge_hits_floor(y + _move)) {
            bridge_settled = true;
            bridge_fall_speed = 0;
            return;
        }

        y += _move;
        _remaining -= _move;
    }
};

bridge_sync_solid();
