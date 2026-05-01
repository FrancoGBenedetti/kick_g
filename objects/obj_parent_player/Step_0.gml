// ── Gravedad ───────────────────────────────────────────────────
move_y = min(move_y + grav, max_fall);

// ── Colisión horizontal ────────────────────────────────────────
if (move_x != 0) {
    var _hstep = sign(move_x);
    repeat (abs(move_x)) {
        if (!place_meeting(x + _hstep, y, collision_map)) {
            x += _hstep;
        } else {
            move_x = 0;
            break;
        }
    }
}

// ── Colisión vertical ──────────────────────────────────────────
on_ground = false;
if (move_y != 0) {
    var _vstep = sign(move_y);
    repeat (ceil(abs(move_y))) {
        if (!place_meeting(x, y + _vstep, collision_map)) {
            y += _vstep;
        } else {
            if (_vstep > 0) on_ground = true;
            move_y = 0;
            break;
        }
    }
}