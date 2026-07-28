// Preset: tabla colgante que cae desde el techo y mata al contacto.
// La instancia se coloca en el techo; drop_floor_y define su posición final.
if (!variable_instance_exists(id, "cover_sprite")) cover_sprite = spr_trap_ceiling;
if (!variable_instance_exists(id, "broken_sprite")) broken_sprite = spr_trap_ceiling_broken;
if (!variable_instance_exists(id, "trigger_range")) trigger_range = 300;
if (!variable_instance_exists(id, "activate_delay")) activate_delay = 18;
if (!variable_instance_exists(id, "drop_speed")) drop_speed = 28;
if (!variable_instance_exists(id, "drop_floor_y")) drop_floor_y = y + 864;
if (!variable_instance_exists(id, "drop_visual_yoff")) drop_visual_yoff = 72;
if (!variable_instance_exists(id, "drop_ground_clearance")) drop_ground_clearance = 12;
if (!variable_instance_exists(id, "trap_visual_xscale")) trap_visual_xscale = 0.6;
if (!variable_instance_exists(id, "trap_visual_yscale")) trap_visual_yscale = 0.6;

event_inherited();

drop_has_killed = false;

trap_check_trigger = function() {
    if (trap_force_trigger) return true;
    if (!instance_exists(obj_player)) return false;

    // La cercanía se lee solo en X: la trampa puede estar muy arriba del jugador.
    return abs(obj_player.x - x) <= trigger_range;
};

drop_kill_player = function() {
    if (drop_has_killed || !instance_exists(obj_player)) return;

    var _scale_x = abs(image_xscale * trap_visual_xscale);
    var _scale_y = abs(image_yscale * trap_visual_yscale);
    var _half_width = 335 * _scale_x;
    var _visual_y = y + drop_visual_yoff;
    var _hit_top = _visual_y + 24 * _scale_y;
    var _hit_bottom = _visual_y + 325 * _scale_y;
    var _player = collision_rectangle(
        x - _half_width,
        _hit_top,
        x + _half_width,
        _hit_bottom,
        obj_player,
        false,
        true
    );

    if (_player != noone) {
        with (_player) {
            hp = 0;
            health = 0;
            die();
        }
        drop_has_killed = true;
    }
};
