function level_solid_at(_map, _x, _y) {
    if (tile_solid_at(_map, _x, _y)) return true;

    var _count = instance_number(obj_dynamic_solid_parent);
    for (var _i = 0; _i < _count; _i++) {
        var _solid = instance_find(obj_dynamic_solid_parent, _i);
        if (!instance_exists(_solid)) continue;
        if (!_solid.dynamic_solid_enabled) continue;

        if (_solid.dynamic_solid_contains_point(_x, _y)) {
            return true;
        }
    }

    return false;
}
