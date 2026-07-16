dynamic_solid_enabled = false;
dynamic_solid_xoff = 0;
dynamic_solid_yoff = 0;
dynamic_solid_w = 64;
dynamic_solid_h = 16;

// Ajustable por instancia desde el Room Editor (Creation Code) en
// cualquier hijo (obj_battleroom_wall, obj_battleroom_gate, etc). Cuando
// es true, ese hijo debe dibujar su rectángulo de colisión SIEMPRE —
// incluso con el debug global apagado — solo para ajustar manualmente su
// posición/tamaño. No cambia dynamic_solid_enabled ni ninguna colisión
// real, es puramente visual. Default false: no cambia nada para nadie que
// no lo pida.
show_collision_debug = false;

dynamic_solid_contains_point = function(_px, _py) {
    var _x1 = x + dynamic_solid_xoff;
    var _y1 = y + dynamic_solid_yoff;
    var _x2 = _x1 + dynamic_solid_w;
    var _y2 = _y1 + dynamic_solid_h;

    return (_px >= min(_x1, _x2) && _px <= max(_x1, _x2)
         && _py >= min(_y1, _y2) && _py <= max(_y1, _y2));
};
