/// @func   scr_draw_healthbar(_x, _y, _w, _h, _hp, _max_hp, _col_bg, _col_fill)
/// @desc   Dibuja una barra de vida horizontal genérica.
///         Restaura color y alpha al terminar — seguro para llamar
///         desde cualquier evento Draw sin afectar el render posterior.
///
/// @param {real}           _x        Esquina superior izquierda X
/// @param {real}           _y        Esquina superior izquierda Y
/// @param {real}           _w        Ancho total en px
/// @param {real}           _h        Alto total en px
/// @param {real}           _hp       HP actual
/// @param {real}           _max_hp   HP máximo
/// @param {constant.Color} _col_bg   Color del fondo (zona vacía)
/// @param {constant.Color} _col_fill Color del relleno (zona de vida restante)
///
/// Uso típico — barra de enemigo flotante (Draw event, world-space):
///   scr_draw_healthbar(x - 20, y - 38, 40, 5,
///                      hp, max_hp,
///                      make_color_rgb(30, 10, 10),
///                      make_color_rgb(40, 200, 80));
///
/// Uso típico — barra del jugador (Draw GUI event, screen-space):
///   scr_draw_healthbar(32, 32, 200, 20,
///                      hp, max_hp,
///                      make_color_rgb(30, 10, 10),
///                      make_color_rgb(220, 40, 40));

function scr_draw_healthbar(_x, _y, _w, _h, _hp, _max_hp, _col_bg, _col_fill) {
    if (_max_hp <= 0) exit;

    var _ratio  = clamp(_hp / _max_hp, 0, 1);
    var _fill_w = floor(_w * _ratio);

    // ── Guardar estado de render ──────────────────────────
    var _prev_color = draw_get_color();
    var _prev_alpha = draw_get_alpha();

    draw_set_alpha(1);

    // ── Fondo (zona vacía) ────────────────────────────────
    draw_set_color(_col_bg);
    draw_rectangle(_x, _y, _x + _w, _y + _h, false);

    // ── Relleno (zona proporcional al HP) ─────────────────
    if (_fill_w > 0) {
        draw_set_color(_col_fill);
        draw_rectangle(_x, _y, _x + _fill_w, _y + _h, false);
    }

    // ── Borde (outline de 1px) ────────────────────────────
    draw_set_color(c_black);
    draw_set_alpha(0.5);
    draw_rectangle(_x, _y, _x + _w, _y + _h, true);

    // ── Restaurar ─────────────────────────────────────────
    draw_set_color(_prev_color);
    draw_set_alpha(_prev_alpha);
}
