// ══════════════════════════════════════════════════════════
// OBJ_PLAYER — Draw GUI
// Dibuja la interfaz fija del jugador en screen-space.
// El evento Draw GUI corre DESPUÉS del Draw normal y en un
// sistema de coordenadas propio (0,0 = esquina superior izquierda
// de la pantalla, independiente de la cámara).
//
// Contenido actual:
//   • Barra de vida con fondo, relleno y texto HP x/max
//
// Futuro:
//   • Contador de flechas / munición
//   • Icono de dash disponible
//   • Indicador de carga del arco
// ══════════════════════════════════════════════════════════

// ── Parámetros de posición y tamaño ──────────────────────
// Escalado para puerto 1920×1080. Ajustar si cambia DISPLAY_W/H.
var _bar_x = 48;
var _bar_y = 48;
var _bar_w = 300;
var _bar_h = 28;

// ── Borde exterior de la barra ────────────────────────────
var _prev_color = draw_get_color();
var _prev_alpha = draw_get_alpha();

draw_set_alpha(0.85);
draw_set_color(c_black);
draw_rectangle(_bar_x - 2, _bar_y - 2, _bar_x + _bar_w + 2, _bar_y + _bar_h + 2, true);

// ── Barra de vida ─────────────────────────────────────────
// Colores: fondo rojo oscuro | relleno rojo saturado
scr_draw_healthbar(
    _bar_x, _bar_y,
    _bar_w, _bar_h,
    hp, max_hp,
    make_color_rgb( 50,  10,  10),   // fondo — rojo muy oscuro
    make_color_rgb(220,  40,  40)    // relleno — rojo
);

// ── Texto HP ──────────────────────────────────────────────
// Dibujado encima de la barra — siempre legible en blanco.
draw_set_alpha(1);
draw_set_color(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_middle);
draw_text(_bar_x + 6, _bar_y + _bar_h * 0.5,
          "HP  " + string(hp) + " / " + string(max_hp));

// ── Restaurar estado de render ────────────────────────────
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(_prev_color);
draw_set_alpha(_prev_alpha);
