function tile_solid_at(_map, _x, _y) {
    return tilemap_get_at_pixel(_map, _x, _y) != 0;
}