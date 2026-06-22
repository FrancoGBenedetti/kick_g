// ══════════════════════════════════════════════════════════
// OBJ_TEST_FLY_BAT — Draw
// El parent (obj_enemy_parent) NO llama draw_self() ni
// event_inherited() hacia obj_actor_parent: cada hijo es
// responsable de dibujar su propio sprite.
// Patrón igual que obj_enemy_archer.
// ══════════════════════════════════════════════════════════

// ── Sprite del bat ────────────────────────────────────────
// draw_self() aplica image_xscale (facing flip), image_alpha
// (hit flash), image_angle y image_blend automáticamente.
draw_self();

// ── Barra de vida (equivalente a actor_parent Draw) ───────
if (show_world_healthbar && hp < max_hp && hp > 0) {
    var _bar_x = x - hpbar_width * 0.5;
    var _bar_y = y + col_top + hpbar_offset_y;
    scr_draw_healthbar(
        _bar_x, _bar_y,
        hpbar_width, hpbar_height,
        hp, max_hp,
        hpbar_col_bg,
        hpbar_col_fill
    );
}

// ── Debug: info de disparo (solo si debug_enemy_ai activo) ─
if (variable_global_exists("debug_enemy_ai") && global.debug_enemy_ai) {
    draw_set_color(c_yellow);
    draw_set_alpha(0.9);
    draw_set_halign(fa_center);
    draw_set_valign(fa_bottom);
    var _dist = instance_exists(obj_player)
                ? point_distance(x, y, obj_player.x, obj_player.y)
                : -1;
    draw_text(x, y + col_top - 4,
        "FLY_BAT  cd:" + string(shoot_cooldown)
        + "  dist:" + string(int64(_dist))
        + "  dir:" + string(fly_dir));
    draw_set_alpha(1.0);
    draw_set_color(c_white);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}

// ── Overlays de separación/colisión del enemy_parent ─────
// Solo activos cuando global.debug_enemy_collision = true (F5).
event_inherited();
