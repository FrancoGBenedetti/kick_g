// ══════════════════════════════════════════════════════════
// OBJ_PLAYER_ARROW — Step
// Toda la física, colisión y lifetime delegada a obj_projectile_parent.
//
// obj_projectile_parent/Step_0 maneja:
//   • Gate global.do_step
//   • Gravedad (gravity = 0 → vuelo recto)
//   • image_angle según vel_x/vel_y (ignorado — Draw usa líneas propias)
//   • Pixel-stepping horizontal + colisión tile + hit a target_object
//   • Pixel-stepping vertical  + colisión tile + hit a target_object
//   • can_be_destroyed_by_sword (false por defecto — flechas del jugador no se destruyen)
//   • Lifetime countdown
//   • Out-of-bounds check
//
// Para agregar comportamiento especial de la flecha del jugador:
//   • Lógica PRE-parent  : ANTES  de event_inherited() → split, homing, etc.
//   • Lógica POST-parent : DESPUÉS de event_inherited() → trail, sonido, etc.
// ══════════════════════════════════════════════════════════
if (!global.do_step) exit;

event_inherited();   // obj_projectile_parent: movimiento, colisión, lifetime
