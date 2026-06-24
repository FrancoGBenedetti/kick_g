event_inherited();

// ── Offset visual del suelo ───────────────────────────────
// Dibuja el sprite ligeramente más abajo que la posición física.
// No afecta la hitbox ni la física — solo la posición del sprite.
draw_y_offset = PLAYER_DRAW_OY;   // desde scr_config

// ── Offset visual del wallslide ───────────────────────────
// Compensa el desplazamiento lateral causado por el flip de image_xscale.
// Positivo → aleja el sprite del muro (en ambos lados).
// Negativo → lo acerca al muro.
// Fórmula en Step: draw_x_offset = wallslide_sprite_offset_x * image_xscale
// Ajustar en incrementos de 5-10 hasta que el personaje no atraviese el muro.
wallslide_sprite_offset_x = 0;   // AJUSTAR visualmente en runtime

// ── DEBUG: visualización de anclas ────────────────────────
// true  → dibuja origen, spawn de flecha, hitbox espada y bbox físico.
// false → producción (sin overhead de draw).
// Alternar en runtime con: obj_player.debug_draw_anchors = !obj_player.debug_draw_anchors
debug_draw_anchors = false;

// ── Sistema de animación visual ───────────────────────────
// Sub-estado visual independiente del FSM físico (player_state).
// player_state controla gameplay/física; player_anim_state controla
// qué sprite se muestra. Ambos pueden desincronizarse brevemente
// durante transiciones (ej.: run_end mientras player_state ya es IDLE).
//
// Estados válidos:
//   "idle"      → spr_player_idle_master  (loop)
//   "run_start" → spr_player_run_start    (once → run_loop)
//   "run_loop"  → spr_player_run_loop     (loop mientras _dir != 0)
//   "run_end"   → spr_player_run_end      (once → idle)
//   "air"       → placeholder hasta tener sprites de salto/caída
player_anim_state = "idle";

// ── BASE IMAGE SPEED — para slow motion centralizado ──────
// Se multiplica por get_time_scale() cada frame para efecto de cámara lenta.
base_image_speed = 0.25;  // velocidad base de animación

// spr_set: asigna sprite sin reiniciar image_index si ya es el mismo.
// Seguro llamarlo cada frame — no provoca parpadeo ni restart de animación.
spr_set = function(_spr) {
    if (sprite_index != _spr) {
        sprite_index = _spr;
        image_index  = 0;
        // Usar base_image_speed * get_time_scale() para que respete slow motion
        image_speed  = base_image_speed * get_time_scale();
    }
};

// ── Movimiento horizontal ─────────────────────────────────
// Valores ×2 del estándar 128×128 — la vista es el doble de grande,
// el personaje también; mantener misma sensación de pantalla requiere ×2 velocidad.
max_walk_speed    = 8;    // px/frame  (era 4)
ground_accel      = 2.4;  // px/frame² (era 1.2)
ground_decel      = 3.6;  // px/frame² (era 1.8)
ground_turn_accel = 4.0;  // px/frame² (era 2.0)
air_accel         = 1.4;  // px/frame² (era 0.7)
air_decel         = 0.6;  // px/frame² (era 0.3)

vel_x = 0;

// ── Knockback y hitstun del jugador ──────────────────────
// Sobreescriben los defaults del actor_parent (5 / -3 / 12 / 0.70).
// Valores configurables por dificultad vía global.current_config.
// Si global.current_config no existe aún (durante editor), usar scr_config como fallback.
var _cfg = variable_global_exists("current_config") ? global.current_config : {
	player_knockback_x: PLAYER_KNOCKBACK_X,
	player_knockback_y: PLAYER_KNOCKBACK_Y,
	player_hitstun: PLAYER_HITSTUN,
	player_knockback_decay: PLAYER_KNOCKBACK_DECAY
};
default_knockback_x = _cfg.player_knockback_x;     // 24 px/frame (normal)
knockback_y_force   = _cfg.player_knockback_y;     // -8 px/frame (normal)
default_hitstun     = _cfg.player_hitstun;          // 20 frames (normal)
knockback_decay     = _cfg.player_knockback_decay;  // 0.80 por frame (normal)

// ── Gravedad y caída (override del parent) ────────────────
// Duplicados junto con jump_speed para mantener el arco exacto (mismos frames al apex).
// Solo afecta al jugador — enemigos conservan grav=0.5, max_fall=14 del parent.
grav             = 1.0;   // px/frame²  (parent default: 0.5)
max_fall         = 28;    // px/frame   (parent default: 14)
fall_max_default = max_fall;

// ── Movimiento vertical ───────────────────────────────────
jump_speed          = -20;   // px/frame (era -10; ×2 con grav×2 → mismos frames al apex)
wall_slide_max_fall = 4;     // px/frame (era 2)

// ── Wall jump ─────────────────────────────────────────────
wall_jump_x           = 6;    // px/frame (era 3; ×2)
wall_jump_y           = -20;  // px/frame (era -10; ×2, proporcional a jump_speed)
wall_jump_lock_frames = 6;    // frames — timing puro, sin cambio
wallJumpLockTimer     = 0;
wall_jump_dir         = 0;

// ── Wall Dash Jump ────────────────────────────────────────
// Ejecutado desde wallslide con dash + jump simultáneos.
// Impulso mayor que wall jump normal; hereda momentum del dash.
wall_dash_jump_x = 18;   // px/frame (era 9; ×2)
wall_dash_jump_y = -24;  // px/frame (era -13; ×1.85 — un poco menos de ×2 para que no se sienta excesivo)

// ── Jump buffer ───────────────────────────────────────────
jump_buffer_max = 8;
jumpBufferTimer = 0;

// ── Dash ──────────────────────────────────────────────────
dash_speed        = 20;   // px/frame (era 10; ×2 — distancia doble en mismo tiempo)
dash_frames       = 16;   // duración en frames (~0.27s a 60fps) — sin cambio
dash_cooldown_max = 20;   // frames hasta poder volver a dashear — sin cambio
dashTimer         = 0;
dashCooldownTimer = 0;
dash_was_grounded = false; // contexto del dash activo (para determinar estado post-dash)
can_air_dash      = true;  // se consume al dashear en el aire; se restaura al aterrizar

// ── Dash Attack ───────────────────────────────────────────
dash_attack_used        = false; // solo un dash attack por dash; reset al iniciar dash nuevo
dash_attack_damage_mult = 2;     // multiplicador de daño respecto a sword_damage_1

// ── Jump Back / Backstep Jump ─────────────────────────────
// Evasión hacia atrás: activada con dash PRIMERO, luego dirección contraria
// Consume el mismo dash charge que dash normal.
// Propósito: evasión táctica contra ataques enemigos.
//
// NUEVA LÓGICA: facing se GUARDA al presionar dash, no cambia durante jump back.
// DISTANCIA: ~216 píxeles (12 px/frame × 18 frames) para esquivar hitboxes enemigos
jump_back_hsp                = 12;   // velocidad horizontal (px/frame) — hacia atrás
jump_back_vsp                = -8;   // impulso vertical (px/frame) — hacia arriba
jump_back_duration           = 18;   // frames de movimiento forzado (~0.3 segundos)
jump_back_control_lock       = 12;   // frames durante los cuales se bloquea input horizontal
jump_back_cooldown_max       = 20;   // cooldown entre jump_backs
jump_back_uses_dash_charge   = true; // consume el dash charge como dash normal
jump_back_afterimage_enabled = false; // no mostrar afterimage por ahora
jump_back_iframes            = 0;    // sin invulnerabilidad por ahora
jump_back_can_air            = false; // solo desde suelo por ahora
can_jump_back_ground         = true; // permiso para jump_back en suelo
can_jump_back_air            = false; // permiso para jump_back en aire
jump_back_active             = false; // true mientras jump_back está en movimiento
jump_back_timer              = 0;    // cuenta regresiva de movimiento
jump_back_control_lock_timer = 0;    // cuenta regresiva de bloqueo de input

// ── Input window para jump back ────────────────────────────
// Ventana de tiempo después de presionar dash para detectar dirección contraria.
jump_back_input_window       = 6;    // frames para presionar dirección contraria
jump_back_input_timer        = 0;    // cuenta regresiva de ventana disponible
jump_back_stored_facing      = 1;    // facing guardado cuando se presiona dash
jump_back_facing_locked      = false; // true mientras no se puede cambiar facing

// ══════════════════════════════════════════════════════════
// BEAT 'EM UP MODE — Combate cuerpo a cuerpo temporal
// ══════════════════════════════════════════════════════════
// Prototipo de modo de boxeo: dura 5 segundos, reemplaza espada/arco por punches.
// Activación temporal: presionar B (futuro: reemplazar con otra mecánica).
combat_mode               = "normal";        // "normal" o "beat_em_up"
beat_em_up_active         = false;           // true mientras está el modo activo
beat_em_up_duration       = 300;             // 5 segundos a 60 FPS
beat_em_up_timer          = 0;               // cuenta regresiva

// ── Combo de punches normal (3 golpes rápidos) ────────────
beat_punch_damage         = 1;               // daño por punch
beat_punch_reach          = 90;              // alcance horizontal
beat_punch_height         = 75;              // altura del hitbox
beat_punch_offset_y       = -80;             // altura relativa al player
beat_punch_active_duration = 5;              // frames que la hitbox está activa
beat_punch_cooldown       = 8;               // frames de espera entre punches
beat_combo_index          = 0;               // 0-2 (3 golpes: punch 1/2/3)
beat_combo_timer          = 0;               // timer para siguiente punch
beat_combo_window         = 20;              // frames para siguiente punch en combo

// ── Golpe fuerte (Heavy) ──────────────────────────────────
beat_heavy_damage         = 3;               // daño fuerte
beat_heavy_reach          = 110;             // alcance mayor
beat_heavy_height         = 90;              // altura del hitbox
beat_heavy_offset_y       = -85;             // altura relativa
beat_heavy_active_duration = 8;              // hitbox activa más tiempo
beat_heavy_cooldown       = 25;              // espera entre heavies
beat_heavy_knockback_hsp  = 18;              // knockback horizontal
beat_heavy_knockback_vsp  = -6;              // knockback vertical

// ── Uppercut (Arriba + Heavy) ────────────────────────────
beat_uppercut_damage      = 2;               // daño de uppercut
beat_uppercut_reach       = 85;              // alcance vertical
beat_uppercut_height      = 140;             // tall hitbox
beat_uppercut_offset_y    = -130;            // muy arriba
beat_uppercut_enemy_vsp   = -18;             // lanza enemigo hacia arriba
beat_uppercut_enemy_hsp   = 4;               // knockback horizontal mínimo
beat_uppercut_hitstun     = 30;              // hitstun aéreo
beat_uppercut_cooldown    = 28;              // espera entre uppercutes

// ── State del ataque Beat 'em Up actual ───────────────────
beat_em_up_attack_type    = "";              // "punch", "heavy", "uppercut"
beat_em_up_attack_active  = false;           // true mientras hitbox está activa
beat_em_up_attack_timer   = 0;               // cuenta regresiva de hitbox
beat_em_up_cooldown_timer = 0;               // cooldown global

// ── Carga de energía para golpe fuerte ────────────────────
// Sistema de carga: 6 golpes ligeros o 1 parry desbloquea heavy punch
beat_heavy_charge         = 0;               // carga actual (0 a 6)
beat_heavy_charge_max     = 6;               // carga necesaria
beat_heavy_unlocked       = false;           // true cuando carga es máxima
beat_light_hit_charge_gain = 1;              // carga por golpe ligero exitoso
beat_parry_charge_gain     = 1;              // carga por parry exitoso
beat_uppercut_enabled     = false;           // TEMP: desactivar uppercut por ahora

// ── Debug visual: hitbox del ataque Beat 'em Up ───────────
// Almacena las coordenadas del último hitbox para debug drawing
beat_em_up_hitbox_x1      = 0;
beat_em_up_hitbox_y1      = 0;
beat_em_up_hitbox_x2      = 0;
beat_em_up_hitbox_y2      = 0;
beat_em_up_hitbox_visible = false;           // true si debe dibujarse

// ── Enemigos durante Beat 'em Up ─────────────────────────
beat_em_up_enemy_iframes  = 0;               // iframes cortos para combos rápidos
beat_em_up_enemies_hit    = ds_list_create(); // rastrear enemigos golpeados en este ataque

// ══════════════════════════════════════════════════════════
// ROLL DODGE — Evasión defensiva estilo Dark Souls
// ══════════════════════════════════════════════════════════
// Mecánica defensiva principal. Solo en suelo. Invulnerable durante roll.
// Reemplaza Jump Back (desactivado). En aire, Dash sigue sin invulnerabilidad.
roll_active           = false;             // true mientras está rodando
roll_timer            = 0;                 // cuenta regresiva del roll
roll_duration         = 18;                // frames (0.3s a 60 FPS)
roll_distance         = 400;               // píxeles que recorre
roll_speed            = roll_distance / roll_duration;  // px/frame calculado
roll_dir              = 1;                 // dirección del roll (facing al inicio)
roll_cooldown_timer   = 0;                 // espera entre rolls
roll_cooldown_max     = 20;                // frames de cooldown mínimo
roll_invulnerable     = true;              // true = invulnerable durante roll
roll_replaces_ground_dash = false;         // false = Dash y Roll son acciones separadas

// Futuras combinaciones (no implementadas todavía)
roll_can_chain_back_attack   = false;      // roll + ataque atrás
roll_can_chain_attack        = false;      // roll + ataque adelante
roll_can_change_direction    = false;      // cambiar dirección durante roll

// ══════════════════════════════════════════════════════════
// SUPER ENERGY — medidor de recurso para futuros super ataques
// ══════════════════════════════════════════════════════════
// Acumulado por golpes exitosos (espada, arco, pogo, parry, counter).
// No se gasta hasta que haya un super ataque real implementado.
// Ajustar cantidades de recarga en scr_config (SUPER_ENERGY_RECHARGE_*).
//
// Flujo de uso futuro:
//   1. Jugador acumula energía golpeando/parryeando.
//   2. Cuando super_energy >= costo del super: try_start_super_attack(type).
//   3. try_start_super_attack consume la energía via spend_super_energy.
//   4. Se activa el estado de super ataque (PSTATE futuro).
super_energy     = 0;
super_energy_max = SUPER_ENERGY_MAX;   // 100

// ── Cantidades de recarga por tipo de golpe ───────────────
// Sobreescribir en Create_0 o en runtime para ajustar ritmo.
sword_hit_energy_gain      = SUPER_ENERGY_RECHARGE_SWORD;        //  5 por golpe suelo
air_sword_hit_energy_gain  = SUPER_ENERGY_RECHARGE_AIR_SWORD;    //  6 por golpe aéreo
downward_slash_energy_gain = SUPER_ENERGY_RECHARGE_POGO;         //  8 por pogo hit
arrow_hit_energy_gain      = SUPER_ENERGY_RECHARGE_ARROW;        //  5 por flecha
parry_energy_gain          = SUPER_ENERGY_RECHARGE_PARRY;        // 10 por parry
counter_energy_gain        = SUPER_ENERGY_RECHARGE_COUNTER;      // 15 por counter hit

// ── Costos de futuros super ataques ──────────────────────
// Consultados por can_use_super_attack / spend_super_energy.
super_attack_cost_up      = SUPER_ATTACK_COST_UP;      // 25
super_attack_cost_down    = SUPER_ATTACK_COST_DOWN;    // 25
super_attack_cost_forward = SUPER_ATTACK_COST_FORWARD; // 30
super_attack_cost_back    = SUPER_ATTACK_COST_BACK;    // 30

// ── Flags de habilidad ────────────────────────────────────
// ability_super_attacks = false → todos los supers bloqueados.
// Los flags individuales se activarán al desbloquear cada super.
ability_super_attacks        = true;    // sistema general habilitado
ability_super_attack_up      = false;   // ↑ + ataque — NO implementado
ability_super_attack_down    = false;   // ↓ + ataque — NO implementado
ability_super_attack_forward = false;   // → + ataque — NO implementado
ability_super_attack_back    = false;   // ← + ataque — NO implementado

// ── gain_super_energy(_amount) ───────────────────────────
// Suma energía respetando el tope. Llamado desde on_hit de hitboxes y
// desde el parry branch de take_damage.
// Si super_energy_recharge_enabled = false, la recarga queda desactivada
// globalmente sin necesidad de cambiar ninguna otra variable.
gain_super_energy = function(_amount) {
    if (!variable_global_exists("super_energy_recharge_enabled")
    ||   global.super_energy_recharge_enabled) {
        super_energy = clamp(super_energy + _amount, 0, super_energy_max);
    }
};

// ── spend_super_energy(_amount) ──────────────────────────
// Resta energía si hay suficiente. Retorna true si se pudo gastar.
// Llamar SOLO cuando hay un super ataque real para ejecutar.
spend_super_energy = function(_amount) {
    if (super_energy >= _amount) {
        super_energy = max(0, super_energy - _amount);
        return true;
    }
    return false;
};

// ── can_use_super_attack(_type) ──────────────────────────
// Retorna true si el jugador tiene energía y la habilidad habilitada.
// _type: "up" | "down" | "forward" | "back"
can_use_super_attack = function(_type) {
    if (!ability_super_attacks) return false;
    if (is_dead)               return false;
    if (hitstun_timer > 0)     return false;

    var _cost    = 0;
    var _ability = false;
    switch (_type) {
        case "up":
            _cost    = super_attack_cost_up;
            _ability = ability_super_attack_up;
        break;
        case "down":
            _cost    = super_attack_cost_down;
            _ability = ability_super_attack_down;
        break;
        case "forward":
            _cost    = super_attack_cost_forward;
            _ability = ability_super_attack_forward;
        break;
        case "back":
            _cost    = super_attack_cost_back;
            _ability = ability_super_attack_back;
        break;
    }
    return _ability && (super_energy >= _cost);
};

// ── try_start_super_attack(_type) ────────────────────────
// Intenta activar el super ataque del tipo dado.
// Por ahora: siempre retorna false (no hay super ataques implementados).
// Futuro: si can_use_super_attack → spend_super_energy → activar PSTATE.
try_start_super_attack = function(_type) {
    if (!can_use_super_attack(_type)) return false;

    // TODO: implementar cada super ataque aquí cuando estén diseñados.
    // Ejemplo futuro:
    //   case "up":
    //     spend_super_energy(super_attack_cost_up);
    //     player_set_state(PSTATE.SUPER_UP);
    //     return true;

    show_debug_message("[SUPER] try_start_super_attack: type=" + _type
        + "  energy=" + string(super_energy)
        + "/" + string(super_energy_max)
        + "  — NO implementado todavía");
    return false;
};

// ── Air Sword Bounce ─────────────────────────────────────
// Pequeño rebote vertical al golpear un enemigo con espada normal en el aire.
// NO afecta al downward slash / pogo (que sobreescribe on_hit en la hitbox).
// NO afecta al counter attack (estado dedicado con su propia física).
// Ajustar con las macros AIR_SWORD_BOUNCE_SPEED / AIR_SWORD_BOUNCE_COOLDOWN en scr_config.
//
// apply_air_sword_bounce(): llamado desde on_hit de obj_sword_hitbox.
//   • Si el player está en suelo → no hace nada.
//   • Si el player ya sube más rápido que bounce_speed → no duplica impulso.
//   • Si cae o está en apex → aplica move_y = air_sword_bounce_speed.
//   • El cooldown impide re-bounce en el mismo hitbox (lifetime corto = 6 frames).
air_sword_bounce_speed        = AIR_SWORD_BOUNCE_SPEED;      // -5 px/frame
air_sword_bounce_cooldown     = 0;                           // frames restantes de anti-bounce
air_sword_bounce_cooldown_max = AIR_SWORD_BOUNCE_COOLDOWN;  // 8 frames
air_sword_bounce_flash_timer  = 0;   // frames del texto "AIR SWORD BOUNCE" en debug
air_sword_bounce_flash_max    = 20;  // duración del texto visual

apply_air_sword_bounce = function() {
    // ── Guards ────────────────────────────────────────────
    if (isGrounded)                              exit;  // solo en el aire
    if (player_state == PSTATE.DOWN_SLASH)       exit;  // pogo tiene su propio rebote
    if (player_state == PSTATE.COUNTER_ATTACK)   exit;  // counter tiene su propia física
    if (air_sword_bounce_cooldown > 0)           exit;  // anti-multi-bounce
    if (is_dead)                                 exit;
    if (hitstun_timer > 0)                       exit;

    // ── Aplicar impulso vertical ──────────────────────────
    // Si el player ya sube más rápido que el bounce, no sumamos impulso extra.
    // Si cae o está en apex (move_y >= 0) o sube despacio → aplicar bounce.
    // Convención: move_y negativo = hacia arriba.
    if (move_y > air_sword_bounce_speed) {
        move_y = air_sword_bounce_speed;
    }
    // Si move_y ya es < bounce_speed el player sube más fuerte → sin cambio.

    // ── Cooldown ──────────────────────────────────────────
    air_sword_bounce_cooldown = air_sword_bounce_cooldown_max;

    // ── Debug ─────────────────────────────────────────────
    air_sword_bounce_flash_timer = air_sword_bounce_flash_max;
    if (variable_global_exists("debug_air_sword_bounce") && global.debug_air_sword_bounce) {
        show_debug_message("[DBG-AIR-BOUNCE] applied: move_y=" + string(move_y)
            + "  state=" + string(player_state)
            + "  grounded=" + string(isGrounded));
    }
};

// ── Counter Attack ────────────────────────────────────────
// Activado al presionar ataque durante la ventana post-parry.
// El player se lanza hacia counter_target a counter_dash_speed.
// Ajustar los valores vía scr_config (COUNTER_*).
counter_target            = noone;   // enemigo a contraatacar; set por el parry
counter_attack_active     = false;   // true mientras COUNTER_ATTACK está activo
counter_dash_speed        = COUNTER_DASH_SPEED;         // 32 px/frame
counter_dash_duration     = COUNTER_DASH_DURATION;      // 12 frames
counter_damage_multiplier = COUNTER_DAMAGE_MULTIPLIER;  // ×3 sword_damage_1
counter_hitbox_w          = COUNTER_HITBOX_W;           // 120 px
counter_hitbox_h          = COUNTER_HITBOX_H;           //  80 px

// ── Dash Jump Momentum ────────────────────────────────────
// Salto ejecutado durante o inmediatamente después de un dash en suelo.
// El salto hereda velocidad horizontal por encima de max_walk_speed durante
// una ventana corta, dando sensación de "impulso" tipo Mega Man X / Hollow Knight.
//
// Flujo:
//   1. Dash grounded activado → dash_jump_grace = dash_jump_grace_max
//      dash_jump_grace_max cubre el dash completo (16f) + el jump buffer (8f)
//      = 22f de ventana desde el inicio del dash hasta el último momento útil.
//   2. Salto disparado mientras dash_jump_grace > 0
//      → dash_jump_timer = dash_jump_frames  (boost activo)
//   3. Sección de velocidad, rama de aire, boost activo:
//      _effective_max = dash_jump_speed   (en lugar de max_walk_speed)
//      → el jugador vuela horizontalmente más rápido mientras presione dirección.
//   4. Al expirar dash_jump_timer → vuelve a max_walk_speed (normal).
//
// Reglas:
//   • Solo dash desde suelo (dash_jump_grace = 0 si air dash).
//   • Solo afecta velocidad en el AIRE (!isGrounded) — suelo no cambia.
//   • El jugador mantiene control direccional total.
//   • No interfiere con wall jump, ataque ni dash doble.
//
// Valores sugeridos (ajustar aquí):
//   dash_jump_speed    → entre max_walk_speed(4) y dash_speed(10)
//   dash_jump_frames   → 9–21f (0.15–0.35 s a 60fps)
//   dash_jump_friction → 0.1–0.4 (menor = más momentum, mayor = decae más rápido)
//   dash_jump_grace_max debe ser siempre dash_frames + jump_buffer_max
dash_jump_timer     = 0;    // (legacy — ya no controla el boost, se mantiene para compat)
dash_jump_frames    = 18;   // (legacy — no se usa en nueva lógica)
dash_jump_speed     = 18;   // techo de vel_x durante boost (walk=8, dash_speed=20) (era 9)
dash_jump_friction  = 0.2;  // rate aéreo misma dirección — sin cambio (es rate, no velocidad)
dash_jump_grace     = 0;    // cuenta regresiva de elegibilidad; >0 = dash grounded reciente
dash_jump_grace_max = 24;   // dash_frames(16) + jump_buffer_max(8) — sin cambio (frames puro)
// ── Dash Jump (landing-based, MMX4 style) ─────────────────
// El impulso dura hasta tocar el suelo, no un timer fijo.
// Termina al aterrizar (IDLE/RUN), tocar pared (WALL) o iniciar nuevo dash.
dash_jump_active      = false; // true desde el salto hasta aterrizar
dash_jump_hsp         = 0;     // vel_x capturado al momento del salto (debug / ref)
dash_jump_air_control = 0.25;  // decel rate al soltar dirección o presionar contraria

// ── Espada / combo cuerpo a cuerpo ───────────────────────
// Combo de 3 golpes (ATTACK_1 → ATTACK_2 → ATTACK_3).
// ─ Duración total de cada estado (frames a 60fps):
attack_1_frames = 20;    // ~0.33s
attack_2_frames = 22;    // ~0.37s
attack_3_frames = 28;    // ~0.47s  (golpe final, más pesado)

// ─ Duración de la hitbox activa por golpe:
attack_1_hitbox_frames = 6;
attack_2_hitbox_frames = 7;
attack_3_hitbox_frames = 10;

// ─ Ventana de combo: cuántos frames restantes abre la ventana para buffer.
//   Si attack_timer <= combo_window_N y attack_buffer == true → avanzar combo.
combo_window_1 = 13;    // ventana para buffear ATTACK_2
combo_window_2 = 13;    // ventana para buffear ATTACK_3

// ─ Daño por golpe:
sword_damage_1 = 1;
sword_damage_2 = 1;
sword_damage_3 = 2;     // tercer golpe hace más daño

// ─ Geometría de la hitbox (offsets desde x/y del jugador):
//   hitbox_x: distancia horizontal en la dirección facing (× facing al spawnear)
//   hitbox_y: desplazamiento vertical (negativo = hacia arriba)
//
//   Calibrado para sprite 256×256, origin=(128,236), visual ~150px.
//   Leído desde scr_config — ajustar allí si el sprite cambia.
//
//   Zona de golpe resultante (con facing=1, col_right≈28):
//     X: [x+27 .. x+109]  (adelante del borde derecho del collider)
//     Y: [y-139 .. y-57]  (nivel de pecho/mano, no en el suelo)
sword_hitbox_x = SWORD_HITBOX_X;   // 60 px hacia adelante
sword_hitbox_y = SWORD_HITBOX_Y;   // -90 px (pecho/mano)
sword_hitbox_w = SWORD_HITBOX_W;   // 80 px de ancho
sword_hitbox_h = SWORD_HITBOX_H;   // 80 px de alto

// ─ Desaceleración horizontal durante el ataque (en suelo):
attack_decel = 2.0;

// ─ Estado del combo en tiempo de ejecución:
combo_step           = 0;      // golpe activo (1/2/3); 0 = no atacando
attack_timer         = 0;      // frames restantes del estado de ataque actual
attack_buffer        = false;  // sticky: attack_pressed capturado en always-section
sword_hitbox_id      = noone;  // referencia a obj_sword_hitbox activo

// ─ Cooldown post-combo:
// Bloquea el inicio de un nuevo combo inmediatamente después de ATTACK_3.
// Previene que presiones de Z durante el último golpe arranquen un 4° ataque
// automático. Durante el cooldown, attack_buffer se ignora aunque esté activo.
//
// Flujo:
//   ATTACK_3 expira → combo_cooldown_timer = combo_cooldown_frames
//   Mientras combo_cooldown_timer > 0 → _can_attack = false
//   Cuando llega a 0 → el jugador puede iniciar un nuevo combo (si presiona Z)
combo_cooldown_frames = 20;    // frames de recuperación (~0.33s a 60fps)
combo_cooldown_timer  = 0;

// ══════════════════════════════════════════════════════════
// PARÁMETROS DE ATAQUE CONFIGURABLES
// ══════════════════════════════════════════════════════════
// Las siguientes variables controlan la forma y posición del hitbox de espada
// NORMAL (no afectan al downward slash que tiene sus propios parámetros).
//
// La máscara de colisión física del player (col_left/right/top/bottom)
// permanece compacta (~56px ancho) alrededor del cuerpo.
// El hitbox de ataque es INDEPENDIENTE y se extiende hacia adelante.
//
// ── Geometría: ─────────────────────────────────────────
// Con facing=1 (mira derecha), el hitbox se construye como:
//   left   = x + player_attack_start_offset
//   right  = x + player_attack_start_offset + player_attack_reach
//   center_y = y + player_attack_offset_y
//   top    = center_y - player_attack_height / 2
//   bottom = center_y + player_attack_height / 2
//
// Visualización conceptual (facing=1):
//   [ cuerpo: col_left..col_right ]  [--- player_attack_reach ---]
//   x                                 start_offset
//
player_attack_reach       = SWORD_HITBOX_W;    // 82: longitud del golpe en eje X
player_attack_start_offset = SWORD_HITBOX_X;   // 68: distancia desde x hasta el inicio
player_attack_height      = SWORD_HITBOX_H;    // 82: altura del rectángulo
player_attack_offset_y    = SWORD_HITBOX_Y;    // -98: altura del golpe (en pixeles de sprite)

// ── Cómo ajustar el alcance del golpe: ──────────────────
// El hitbox se visualiza en AMARILLO cuando el player ataca (activa con F3/F8 o siempre para debug).
//
// Para acortar el golpe:       disminuye player_attack_reach
// Para alargarlo:              aumenta player_attack_reach
// Para moverlo más adelante:   aumenta player_attack_start_offset
// Para acercarlo al cuerpo:    disminuye player_attack_start_offset
// Para hacerlo más alto:       aumenta player_attack_height
// Para hacerlo más bajo:       disminuye player_attack_height
// Para subirlo en el sprite:   aumenta player_attack_offset_y (menos negativo)
// Para bajarlo en el sprite:   disminuye player_attack_offset_y (más negativo)
//
// Ejemplo: lanza más larga que espada:
//   player_attack_reach       = 120;  (en lugar de 82)
//   player_attack_start_offset = 80;  (en lugar de 68)
//
// DEBUG VISUAL: El hitbox aparece en AMARILLO igual que los de enemigos.
// Activar con: F3 (global.debug_enemy_attacks) o F8 (global.debug_hitboxes)
// O mantener visible siempre durante desarrollo.

// HOOK FUTURO — parry:
//   parry_window_1/2/3: frames desde el inicio del golpe en que un parry es posible.
//   Cuando on_damage se dispara durante esa ventana Y combo_step > 0:
//     → player_set_state(PSTATE.PARRY) — ver diseño en scr_player_fsm.gml.
// parry_window_1 = 6;   // (no implementado todavía)

// ── Arco / sistema de carga ───────────────────────────────
// Ahora mapeado a la tecla X (kb_ranged / ranged_*).
//
// Flujo de carga:
//   1. Presionar X → comienza la carga (si cooldown == 0).
//   2. Soltar antes de bow_min_charge_frames → cancelado, sin flecha.
//   3. Soltar después de bow_min_charge_frames → disparo.
//   4. bow_charge_timer se detiene en bow_max_charge_frames (no acumula más).
//
// Niveles de carga (charge_level — para extensiones futuras):
//   0  carga mínima–media  (bow_charge_timer < bow_charge_lvl1)
//   1  carga media         (>= bow_charge_lvl1, < bow_charge_lvl2)
//   2  carga completa      (>= bow_charge_lvl2)

bow_is_charging     = false;  // true mientras la carga está activa
bow_charge_timer    = 0;      // frames acumulados de carga
bow_release_pending = false;  // sticky: ranged_released capturado en always

// ─ Umbrales de nivel de carga (para charge_level):
bow_charge_lvl1 = 30;    // nivel 1 (~0.5 s a 60fps)
bow_charge_lvl2 = 70;    // nivel 2 (~1.17 s)

// ─ Restricciones de disparo:
bow_min_charge_frames = 12;  // mínimo de frames pulsado para que dispare (~0.2s)
bow_max_charge_frames = 90;  // techo de acumulación — más allá no cambia nada

// ─ Cooldown entre disparos:
bow_cooldown_frames = 18;    // frames de espera tras disparar (~0.3s)
bow_cooldown_timer  = 0;     // cuenta regresiva activa; 0 = listo para cargar

// ── Ángulo de apuntado vertical ──────────────────────────
// Permite inclinar el disparo hacia arriba o hacia abajo
// mientras el arco está cargado.
//
// Convención de signo (coordenadas de pantalla):
//   aim_angle < 0  → apunta hacia arriba
//   aim_angle = 0  → horizontal (default)
//   aim_angle > 0  → apunta hacia abajo
//
// Al disparar:
//   vel_x = facing * arrow_speed * cos(degtorad(aim_angle))
//   vel_y = arrow_speed * sin(degtorad(aim_angle))
//
// Ajustar aim_angle_min/max para cambiar el rango permitido.
// Ajustar aim_angle_speed para cambiar la velocidad de giro.
aim_angle       = 0;     // ángulo actual en grados
aim_angle_min   = -30;   // máximo hacia arriba (−30° = 30° upward)
aim_angle_max   = 30;    // máximo hacia abajo
aim_angle_speed = 2;     // grados por game-frame (~120°/s a 60fps)

// ── Apuntado aéreo ────────────────────────────────────────
// Cuando el jugador carga el arco en el aire, puede apuntar
// en dirección opuesta a su movimiento sin alterar su física.
//
// Flujo:
//   ranged_pressed en aire → is_aiming = true, guardar saved_facing
//   durante carga          → aim_facing sigue al input (_dir)
//   al disparar            → flecha usa aim_facing; facing restaurado
//   al aterrizar           → cancelar modo aim automáticamente
//
// HOOK FUTURO: en modo aim se puede mostrar un cursor o flecha
// de dirección sobre el personaje (Draw event de obj_player).
is_aiming    = false;  // true durante carga aérea activa
saved_facing = 1;      // facing del momento en que empezó la carga
aim_facing   = 1;      // dirección de apuntado actual (actualizada por _dir)

// ── Downward Slash / Pogo Attack ──────────────────────────
// Ataque aéreo: mantener ↓ + Z en el aire.
// Si la espada golpea un objetivo, el jugador rebota hacia arriba.
//
// Flujo:
//   1. ↓ + Z en el aire → DOWN_SLASH (enter hook: attack_timer = down_slash_frames)
//   2. Primer frame post-física: spawna hitbox centrada debajo del jugador.
//   3. Cada frame: hitbox sigue al jugador; si impacta → on_hit activa rebote.
//   4. Rebote: move_y = pogo_bounce_speed (aplicado en event_inherited del frame siguiente).
//   5. Cancelación: soltar ↓, aterrizar, o recibir daño → player_set_state(FALL/IDLE).
//   6. Encadenar: tras el rebote el jugador está en FALL; puede volver a presionar ↓+Z.
//
// Valores ajustables:
//   pogo_bounce_speed  → fuerza del rebote (más negativo = más alto)
//   down_slash_frames  → ventana de ataque antes de cancelarse solo
//   down_slash_damage  → daño aplicado al impactar
//   down_slash_hitbox_* → geometría y posición de la hitbox

has_pogo_bounced  = false;  // true en el frame en que ocurrió el rebote; se limpia para re-armar
pogo_bounce_speed = -16;    // velocidad vertical al rebotar (neg = arriba) (era -8; ×2)
bounce_count      = 0;      // cuántos rebotes encadenados en el DOWN_SLASH actual (debug + diseño futuro)

// ── Pogo persistente: cooldown entre hits ────────────────
// Después de cada rebote, se espera downward_slash_hit_cooldown_max
// frames antes de armar la hitbox de nuevo. Evita golpear múltiples
// veces en el mismo frame y da tiempo a que el jugador suba y baje.
// Rango sugerido: 4-10 frames (menor = pogo más agresivo).
downward_slash_hit_cooldown_max = 6;    // frames de espera entre rebotes
downward_slash_hit_cooldown     = 0;    // contador activo (0 = listo para armar)

down_slash_frames = 30;     // frames máx. del estado sin impacto (~0.5s a 60fps)
down_slash_damage = 2;      // daño por golpe (igual al segundo golpe del combo)

// Hitbox posicionada DEBAJO del jugador, centrada horizontalmente.
// hitbox_offset_x = 0 → no se multiplica por facing (siempre centrado).
// hitbox_offset_y > 0 → debajo del origen del jugador (nivel de pies).
//
// Calibrado para sprite HD: alcance suficiente para golpear enemigos
// directamente debajo mientras el jugador cae sobre ellos.
// Leído desde scr_config — ajustar allí si el sprite cambia.
down_slash_hitbox_x = POGO_HITBOX_X;   //  0 — centrado
down_slash_hitbox_y = POGO_HITBOX_Y;   // 40 px bajo los pies
down_slash_hitbox_w = POGO_HITBOX_W;   // 50 px de ancho
down_slash_hitbox_h = POGO_HITBOX_H;   // 80 px de alcance vertical

// ── Buffer de inputs para futuros combos ─────────────────
// Registra cuándo fue presionado cada input por última vez.
// Cada timer vale combo_buffer_window al presionar y baja 1/frame.
// En 0 = ese input fue "olvidado" (fuera de la ventana).
//
// Uso futuro (NO implementado aún):
//   if (was_recent_sword() && was_recent_back()) → dash slash
//   if (was_recent_sword() && was_recent_jump())  → uppercut
//   etc.
//
// Actualizar: llamar update_combo_input_buffer() en la sección
// de timers del Step (ya agregado abajo).
// Queries: was_recent_sword(), was_recent_back(), etc. — ver scr_combo_buffer.gml
combo_buffer_window  = 12;   // frames — ventana de detección (~0.2s a 60fps)

recent_sword_timer   = 0;    // Z presionado hace N frames
recent_bow_timer     = 0;    // X presionado hace N frames
recent_dash_timer    = 0;    // Shift presionado hace N frames
recent_jump_timer    = 0;    // Space presionado hace N frames
recent_back_timer    = 0;    // dirección "atrás" (relativa al facing) hace N frames
recent_forward_timer = 0;    // dirección "adelante" (relativa al facing) hace N frames
recent_down_timer    = 0;    // ↓ presionado hace N frames
recent_up_timer      = 0;    // ↑ presionado hace N frames

// ── Action lock ───────────────────────────────────────────
// Compromiso mínimo al iniciar un ataque de espada antes de que
// el arco pueda dispararse. NO afecta la duración del ataque ni el
// combo — solo controla cuándo vuelve a estar disponible el arco.
//
//   action_lock_timer  > 0  → espada en ventana de compromiso (arco bloqueado)
//   action_lock_timer == 0  → libre para cambiar a arco
//
// sword_lock_frames: ajustar entre 10-18 según el feel deseado.
//   Valor bajo (10) → arco disponible rápido, sensación ágil.
//   Valor alto (18) → mayor compromiso, feel más pesado.
sword_lock_frames = 14;   // frames de compromiso inicial al atacar con espada
action_lock_timer = 0;    // cuenta regresiva; set en el enter hook de cada ATTACK_*

// ── Dash Slide ────────────────────────────────────────────
// La hitbox se reduce verticalmente durante un dash iniciado en el suelo.
// Permite al jugador pasar bajo obstáculos bajos sin modificar las colisiones
// laterales, de suelo ni la lógica de salto/wallslide/airdash.
//
// Variables:
//   normal_col_top  : col_top original (referencia para restaurar)
//   slide_col_top   : col_top reducido durante el slide
//   is_sliding      : true mientras la hitbox está reducida
//
// Flujo:
//   1. PSTATE.DASH + dash_was_grounded + isGrounded  → activar (is_sliding = true)
//   2. Cada frame de slide: col_top = slide_col_top (antes de event_inherited)
//   3. Al salir del dash o elevarse: verificar espacio libre sobre la cabeza
//      → si libre → restaurar col_top, is_sliding = false
//      → si bloqueado → mantener hitbox reducida hasta que haya espacio
//
// Casos NO cubiertos (is_sliding permanece false):
//   salto normal, caída, wallslide, air dash, dash jump, hitstun
normal_col_top = col_top;              // captura el valor del sprite bbox (-72 típico)
slide_col_top  = PLAYER_SLIDE_COL_TOP; // scr_config: -36 por defecto
is_sliding     = false;

// ── Afterimage / Ghost Trail ──────────────────────────────
// Efecto visual durante el dash: deja copias del sprite que se desvanecen.
// Estilo Mega Man X4 / Dead Cells. 100% por código — sin sprites extra.
//
// Variables ajustables:
//   afterimage_enabled      : true/false — desactivar sin tocar otra lógica
//   afterimage_alpha_start  : opacidad inicial de cada copia (0.0–1.0)
//   afterimage_fade_speed   : cuánto baja el alpha por frame (mayor = desaparece más rápido)
//                             vida en frames ≈ afterimage_alpha_start / afterimage_fade_speed
//                             Ej: 0.85 / 0.045 ≈ 19 frames de vida
//   afterimage_spawn_rate   : cada cuántos frames se genera una copia (menor = más copias)
//   afterimage_back_offset  : px que se empuja la copia hacia atrás (contra facing) al nacer,
//                             para que NUNCA aparezca exactamente encima del player.
//   afterimage_color        : tinte de las copias (default: blanco azulado — estilo neon)
//   afterimage_max          : máximo de instancias simultáneas (evita spam en slowmo)
//
// FIX (no se veía nada): el .yy del objeto tenía "visible":false — en GMS2 eso
// desactiva el Draw event por completo, sin importar el código. Corregido a true.
// También se subió alpha/duración/spawn_rate para garantizar ≥4 copias visibles
// simultáneas durante cualquier dash (16 frames de duración).
//
// Conteo simultáneo aproximado = vida_en_frames / spawn_rate
//   19 / 2 ≈ 9 copias visibles en pantalla durante el dash completo ✓ (≥4 garantizado)
//
// Para desactivar rápido en debug: obj_player.afterimage_enabled = false
afterimage_enabled     = true;
afterimage_alpha_start = 0.85;    // antes 0.65 — más visible
afterimage_fade_speed  = 0.045;   // antes 0.07 — vida ≈ 19 frames (antes ~9)
afterimage_spawn_rate  = 2;       // antes 3 — copia cada 2 frames (más densidad)
afterimage_spawn_timer = 0;       // contador interno — no modificar
afterimage_back_offset = 24;      // px hacia atrás del facing al nacer (separación visual)
afterimage_color       = make_color_rgb(160, 210, 255);  // azul claro / neon
afterimage_max         = 14;      // máximo simultáneo — previene leaks en slowmo

// ── Debug temporal ─────────────────────────────────────────
// global.debug_dash_afterimage = true → cada afterimage dibuja su alpha actual
// como texto sobre sí mismo, y cada spawn deja un show_debug_message().
// Toggle: F11 (ver obj_input/Step_1.gml).
if (!variable_global_exists("debug_dash_afterimage")) {
    global.debug_dash_afterimage = false;
}

// ── Función de spawn ──────────────────────────────────────
// afterimage_spawn(): crea una copia del frame actual del player.
// Closure: captura 'id' del player para leer sus variables de manera segura.
// Devuelve el ID de la instancia creada (o noone si desactivado o max alcanzado).
afterimage_spawn = function() {
    if (!afterimage_enabled) return noone;

    // Límite de instancias simultáneas (performance)
    if (instance_number(obj_dash_afterimage) >= afterimage_max) return noone;

    // Empuje hacia atrás respecto al facing — evita que la primera copia
    // quede exactamente debajo del sprite del player (invisible por overlap).
    var _spawn_x = x - (facing * afterimage_back_offset);

    var _inst = instance_create_layer(_spawn_x, y, "Instances_1", obj_dash_afterimage);

    with (_inst) {
        ghost_sprite = other.sprite_index;
        ghost_frame  = other.image_index;
        ghost_xscale = other.image_xscale;
        ghost_yscale = other.image_yscale;
        ghost_angle  = other.image_angle;
        ghost_alpha  = other.afterimage_alpha_start;
        ghost_color  = other.afterimage_color;
        ghost_fade   = other.afterimage_fade_speed;
        depth        = other.depth + 1;   // siempre detrás del player
    }

    if (global.debug_dash_afterimage) {
        show_debug_message("[DBG-AFTERIMAGE] spawn — total activos="
            + string(instance_number(obj_dash_afterimage))
            + "  pos=(" + string(_spawn_x) + "," + string(y) + ")"
            + "  sprite=" + string(sprite_index)
            + "  frame=" + string(image_index));
    }

    return _inst;
};

// ── Debug HUD ─────────────────────────────────────────────
player_debug_visible = false;   // F8 para activar en runtime

// ── Estado de movimiento ──────────────────────────────────
player_state = PSTATE.FALL;

// ══════════════════════════════════════════════════════════
// SALUD Y DAÑO — override de los valores del parent
// ══════════════════════════════════════════════════════════
// Estas líneas corren DESPUÉS de event_inherited(), por lo que
// sobreescriben correctamente los valores base del actor.
//
// IMPORTANTES: max_hp, default_invuln y default_hitstun son configurables
// por dificultad vía global.current_config. Los valores aquí son fallback.

var _cfg_hp = variable_global_exists("current_config") ? global.current_config : {
	player_max_hp: 2,
	player_default_invuln: 90,
	player_hitstun: 20
};

max_hp = _cfg_hp.player_max_hp;        // configurables por dificultad
hp     = max_hp;

// Override de i-frames: el jugador tiene más tiempo de invulnerabilidad.
// Nota: la variable canónica es default_invuln (renombrada desde invulnerability_max).
default_invuln = _cfg_hp.player_default_invuln;   // ~1.5s en normal, menos en fácil

// ── Valores de daño del jugador (knockback y hitstun, heredados de arriba) ─
// También heredan los valores ya asignados hace poco del config de dificultad.
// No se duplican aquí para mantener coherencia.

// ── Parpadeo de invulnerabilidad ──────────────────────────
// Ajustar: menor = parpadeo más rápido; 4 es el estándar Mega Man / Hollow Knight.
blink_interval = 4;

// ── Bloqueo de input durante recuperación de daño ──────────
// Se activa cuando el player recibe daño (en take_damage → invulnerable=true).
// Bloquea movimiento, ataque, dash, etc. EXCEPTO parry.
// Un parry perfecto durante este estado lo cancela inmediatamente.
// Esto hace que ser golpeado sea más peligroso en combates multi-enemigos.
// IMPORTANTE: la duración (damage_recovery_lock_duration) es configurable por dificultad.
damage_recovery_lock = false;
damage_recovery_lock_timer = 0;
var _cfg_recovery = variable_global_exists("current_config") ? global.current_config : {
	damage_recovery_lock_duration: 90
};
damage_recovery_lock_duration = _cfg_recovery.damage_recovery_lock_duration;  // configurable por dificultad

// ── Funciones helper para verificar si el player puede actuar ──
player_can_move = function() {
    return !damage_recovery_lock && !is_dead;
};

player_can_attack = function() {
    return !damage_recovery_lock && !is_dead;
};

player_can_dash = function() {
    return !damage_recovery_lock && !is_dead;
};

player_can_parry = function() {
    // Parry está permitido INCLUSO durante damage_recovery_lock
    return ability_parry && !is_dead;
};

// ── Jump Back — Evasión hacia atrás ─────────────────────────
// Activado cuando: dash pressed + input direction == -facing
// Actúa como evasión táctica contra ataques.
player_can_jump_back = function() {
    if (is_dead) return false;
    if (damage_recovery_lock) return false;
    if (hitstun_timer > 0) return false;
    if (player_state == PSTATE.COUNTER_ATTACK) return false;
    if (player_state == PSTATE.WALL) return false;

    var _can_ground = can_jump_back_ground && isGrounded;
    var _can_air = can_jump_back_air && !isGrounded;

    return _can_ground || _can_air;
};

start_jump_back = function(_stored_facing = jump_back_stored_facing) {
    if (!player_can_jump_back()) {
        show_debug_message("[JUMP_BACK] Condición NO cumplida");
        return false;
    }

    jump_back_active = true;
    jump_back_timer = jump_back_duration;
    jump_back_control_lock_timer = jump_back_control_lock;
    jump_back_facing_locked = true;  // Bloquear cambios de facing

    // Aplicar movimiento inicial usando el FACING GUARDADO
    vel_x = -_stored_facing * jump_back_hsp;  // ← Usa facing guardado, no facing actual
    vel_y = jump_back_vsp;

    // Asegurar que facing permanece en el valor guardado
    facing = _stored_facing;
    image_xscale = abs(image_xscale) * _stored_facing;

    // Consumir dash charge si está habilitado
    if (jump_back_uses_dash_charge) {
        can_air_dash = false;  // consume el dash aéreo si estaba disponible
    }

    // Debug
    show_debug_message("[JUMP_BACK] INICIADO - FACING LOCKED: stored=" + string(_stored_facing)
        + "  vel_x=" + string(vel_x) + "  vel_y=" + string(vel_y)
        + "  movement=hacia atrás");

    return true;
};

player_can_bow = function() {
    return !damage_recovery_lock && !is_dead;
};

// on_damage: reacción específica del jugador al recibir daño.
// Sobreescribe el stub del parent. Responsabilidades:
//   1. Cancelar estados de ataque activos (interrumpir el combo)
//   2. Cancelar modo de apuntado aéreo del arco
//   3. DEBUG — confirmar daño recibido (quitar cuando el sistema esté validado)
on_damage = function(_amount, _source) {
    // ── Cancelar dash si estaba activo ────────────────────────
    // El knockback sobreescribe move_x durante hitstun, pero necesitamos
    // cancelar el estado DASH para que la física no lo mantenga activo.
    if (player_state == PSTATE.DASH) {
        dashTimer       = 0;
        dash_jump_grace = 0;
        player_set_state(isGrounded ? PSTATE.IDLE : PSTATE.FALL);
    }

    // ── Cancelar momentum de dash jump ────────────────────────
    // Si el player estaba en el aire con boost de dash_jump, interrumpirlo.
    // El knockback aplicará su propia velocidad horizontal.
    dash_jump_active = false;
    dash_jump_grace  = 0;

    // ── Resetear vel_x ─────────────────────────────────────────
    // Evita que al salir del hitstun el player reanude con la velocidad previa.
    vel_x = 0;

    // ── Cancelar block si estaba bloqueando (golpe desde atrás) ─
    // take_damage solo llama on_damage si el golpe NO fue interceptado,
    // es decir: ya pasó por las ramas de parry/block sin ser absorbido.
    // Cualquier daño que llega aquí durante BLOCK fue desde atrás.
    // Cancelar block, ya que el jugador fue golpeado.
    if (player_state == PSTATE.BLOCK) {
        is_blocking = false;
        is_parrying = false;
        parry_window_timer = 0;
        player_set_state(isGrounded ? PSTATE.IDLE : PSTATE.FALL);
    }

    // ── Cancelar combo si el jugador estaba atacando ───────
    // El hitstun gate (Step) bloqueará los inputs en los frames siguientes,
    // pero el estado de ataque debe cancelarse inmediatamente para que
    // player_set_state ejecute la limpieza de hitbox correctamente.
    if (player_state == PSTATE.ATTACK_1
    ||  player_state == PSTATE.ATTACK_2
    ||  player_state == PSTATE.ATTACK_3
    ||  player_state == PSTATE.DOWN_SLASH
    ||  player_state == PSTATE.DASH_ATTACK
    ||  player_state == PSTATE.COUNTER_ATTACK) {
        combo_step       = 0;
        attack_buffer    = false;
        has_pogo_bounced = false;
        // player_set_state destruye la hitbox activa (exit hook del estado).
        player_set_state(isGrounded ? PSTATE.IDLE : PSTATE.FALL);
    }

    // ── Cancelar carga de arco si estaba en curso ──────────
    if (bow_is_charging) {
        bow_is_charging     = false;
        bow_charge_timer    = 0;
        bow_release_pending = false;
        aim_angle           = 0;
        if (is_aiming) {
            facing     = saved_facing;
            aim_facing = saved_facing;
            is_aiming  = false;
        }
        // La slow motion se desactivará en la próxima pasada de la sección always
        // cuando bow_is_charging ya sea false.
    }

    // DEBUG — confirma quién daña al player y cuánta vida queda
    var _src_name = "unknown";
    if (instance_exists(_source)) _src_name = object_get_name(_source.object_index);
    show_debug_message("[DBG] PLAYER on_damage: amount=" + string(_amount)
        + "  source=" + _src_name
        + "  hp=" + string(hp)
        + "  hitstun=" + string(hitstun_timer)
        + "  knockback_x=" + string(knockback_x));
};

// ── Estado de muerte / respawn ────────────────────────────
is_dead = false;

// ── Punto de reaparición (futuro checkpoint) ─────────────
// Por ahora inicializan con la posición de spawn del room.
// Cuando se implemente checkpoints: spawn_x/spawn_y = checkpoint.x/y
spawn_x = x;   // ~384
spawn_y = y;   // ~416

// die: muerte específica del jugador.
die = function() {
    if (is_dead) exit;
    is_dead = true;
    show_debug_message("[DBG] PLAYER die() — hp=" + string(hp));
    show_debug_message("[DBG] ROOM RESTART");
    room_restart();
};

// ══════════════════════════════════════════════════════════
// HABILIDADES DEL JUGADOR
// ══════════════════════════════════════════════════════════
// Flags booleanos que controlan qué mecánicas están disponibles.
// Cambiar a false para deshabilitar sin tocar lógica de gameplay.
//
// Uso: sistema de progresión (desbloquear habilidades con ítems/checkpoints).
// Por ahora todas en true excepto ability_counterattack (no implementado aún).
//
// ── Cómo habilitar/deshabilitar en runtime ────────────────
//   obj_player.ability_dash = false;    // deshabilitar dash
//   obj_player.ability_dash = true;     // habilitar dash
//
// ── Dónde vive cada gate en Step_0 ───────────────────────
//   ability_sword          → attack_buffer (sección always)
//   ability_downward_slash → entrada a DOWN_SLASH (sección gated)
//   ability_bow            → ranged_pressed (sección always)
//   ability_dash           → dash activation + wall_dash_jump (sección gated)
//   ability_air_dash       → _can_dash en air (sección gated)
//   ability_dash_jump      → dash jump from ground (sección gated)
//   ability_wallslide      → WALL state transitions en JUMP/FALL
//   ability_walljump       → wall jump + wall_dash_jump (sección gated)
//   ability_parry          → block_pressed (sección always)
//   ability_counterattack  → gate en take_damage override (Create_0)
// ════════════════════════════════════════════════════════════
ability_sword          = true;
ability_bow            = true;
ability_dash           = true;
ability_dash_jump      = true;   // salto desde dash en suelo con momentum (MMX4 style)
ability_wallslide      = true;
ability_walljump       = true;
ability_air_dash       = true;   // dash aéreo (consume can_air_dash)
ability_downward_slash = true;   // ↓ + Z en el aire
ability_parry          = true;   // parry perfecto (C en ventana de 8 frames)
ability_counterattack  = true;   // contraataque post-parry — presionar ataque en ventana post-parry

// ══════════════════════════════════════════════════════════
// BLOCK / PARRY
// ══════════════════════════════════════════════════════════
// Activado con kb_block (C). Los primeros PARRY_WINDOW_FRAMES son parry perfecto.
// Después: block normal. La ventana y el estado se gestionan en Step_0 always.
//
// Jerarquía de resolución (dentro del take_damage override):
//   parry perfecto → sin daño, slow-mo, can_counterattack = true
//   block normal   → sin daño, sin knockback
//   daño normal    → base_take_damage (full hit)
//
// Dirección: solo bloquea ataques FRONTALES (sign(_source.x - x) == facing).
// Ataques desde atrás pasan siempre, incluso con block activo.
is_blocking          = false;   // espejo de (player_state == PSTATE.BLOCK); leído por take_damage
is_parrying          = false;   // true durante parry_window_timer > 0 en BLOCK
parry_window_timer   = 0;       // cuenta regresiva de la ventana perfecta (frames reales)
// Valores configurables por dificultad vía global.current_config
var _cfg_parry = variable_global_exists("current_config") ? global.current_config : {
	parry_window_frames: PARRY_WINDOW_FRAMES,
	parry_slow_duration: PARRY_SLOW_DURATION,
	parry_cooldown_max: PARRY_COOLDOWN_MAX,
	parry_counter_window: PARRY_COUNTER_WINDOW
};
parry_window_max     = _cfg_parry.parry_window_frames;   // configurables por dificultad
parry_slow_timer     = 0;       // frames restantes de slow-mo post-parry (frames reales)
parry_slow_duration_max = _cfg_parry.parry_slow_duration;  // duración del slow-mo por dificultad
parry_cooldown_timer = 0;       // cooldown tras salir de block (frames reales)
parry_cooldown_max   = _cfg_parry.parry_cooldown_max;   // cooldown por dificultad
can_counterattack    = false;   // activado tras parry perfecto — futuro contraataque
counterattack_timer  = 0;       // ventana de contraataque disponible (frames gated)
counter_window_max   = _cfg_parry.parry_counter_window;  // configurables por dificultad

// ── Variables alias / estado observable ─────────────────
// parry_active  : equivale a is_parrying; nombre más semántico para sistemas externos.
// parry_success : true durante ~3 frames tras un parry perfecto (para efectos/audio futuros).
// parry_success_timer: cuenta regresiva de parry_success (frames reales).
parry_active        = false;   // sincronizado con is_parrying en Step_0 (sección always)
parry_success       = false;   // flag de un parry exitoso — true ≈ 3 frames
parry_success_timer = 0;       // cuenta regresiva; parry_success = (timer > 0)

// ── Popup visual de parry exitoso ─────────────────────────
// Independiente de parry_success_timer (que dura solo 3 frames reales).
// Este timer dura más para que el ! sea visible sobre la cabeza del jugador.
parry_popup_timer     = 0;
parry_popup_timer_max = 28;   // frames reales — ajustar para más/menos duración

// ── take_damage override: intercepta block / parry ────────
// Guarda referencia al método base (ligado a 'id') antes de sobreescribir.
// Llamar a base_take_damage(_amount, _source) delega al parent sin super().
base_take_damage = take_damage;

take_damage = function(_amount, _source) {

    // ── Dirección del ataque ──────────────────────────────
    // Un ataque es "frontal" si la fuente está del mismo lado que facing.
    //   _source.x >  x && facing =  1 → desde la derecha, mirando derecha → frontal
    //   _source.x <  x && facing = -1 → desde la izquierda, mirando izquierda → frontal
    // Ataques sin posición (noone) no pueden ser bloqueados.
    var _from_front = false;
    if (instance_exists(_source)) {
        _from_front = (sign(_source.x - x) == facing);
    }

    // ── PARRY PERFECTO ────────────────────────────────────
    // Ventana activa + ataque frontal → parry success.
    // No aplica daño ni knockback al jugador. Activa slow-mo y
    // can_counterattack. Si el ataque era melee, aturde al atacante.
    if (is_parrying && _from_front) {
        show_debug_message("[DBG-BLOCK] PARRY PERFECTO — ataque bloqueado, can_counterattack activado");

        // ── Flags de parry ────────────────────────────────
        parry_success_timer  = 3;          // parry_success visible por ~3 frames reales
        parry_success        = true;
        parry_popup_timer    = parry_popup_timer_max;   // activa el ! visual sobre la cabeza
        trigger_parry_feedback();          // activa slow-mo centralizado + efectos
        parry_slow_timer     = PARRY_SLOW_DURATION;    // legacy: mantener para compatibilidad
        parry_window_timer   = 0;
        is_parrying          = false;
        parry_active         = false;
        parry_cooldown_timer = PARRY_COOLDOWN_MAX;

        // ── Energía por parry ─────────────────────────────
        gain_super_energy(parry_energy_gain);

        // ── Carga para golpe fuerte (Beat 'em Up) ─────────
        beat_heavy_charge += beat_parry_charge_gain;
        beat_heavy_charge = clamp(beat_heavy_charge, 0, beat_heavy_charge_max);
        if (beat_heavy_charge >= beat_heavy_charge_max) {
            beat_heavy_unlocked = true;
            show_debug_message("[BEAT-CHARGE] HEAVY READY (parry) - charge = " + string(beat_heavy_charge));
        } else {
            show_debug_message("[BEAT-CHARGE] +1 parry - charge = " + string(beat_heavy_charge) + "/" + string(beat_heavy_charge_max));
        }

        // ── Ventana de contraataque ───────────────────────
        // Se abre internamente aunque ability_counterattack = false.
        // El gate abajo limpia can_counterattack si la habilidad no está habilitada.
        can_counterattack   = true;
        counterattack_timer = COUNTERATTACK_WINDOW;

        // ── Gate ability_counterattack ────────────────────
        // Si la habilidad no está desbloqueada: limpiar ventana inmediatamente.
        // Así el parry sigue funcionando (slow-mo, stun) pero no habilita counter.
        // Cuando ability_counterattack = true, esta rama no ejecuta y el counter queda abierto.
        if (!ability_counterattack) {
            can_counterattack   = false;
            counterattack_timer = 0;
            counter_target      = noone;
        }

        // ── Stun al atacante (solo ataques melee) ─────────
        // Identifica al enemigo dueño del ataque y le aplica
        // knockback + hitstun extendido + ventana de contraataque.
        //
        // Dos rutas para resolver el attacker:
        //   A) _source es la hitbox (attack_type + owner): normal
        //      → _source.attack_type == MELEE && _source.owner tiene parried_stun_duration
        //   B) _source es el enemigo directamente (hit_source = enemy_id):
        //      → _source tiene parried_stun_duration y no es proyectil
        //      Caso del swordsman: hit_source = _enemy_id, no la hitbox.
        var _attacker = noone;

        if (instance_exists(_source)) {
            if (variable_instance_exists(_source, "attack_type")
            &&  _source.attack_type == ATTACK_TYPE_MELEE
            &&  instance_exists(_source.owner)
            &&  variable_instance_exists(_source.owner, "parried_stun_duration")) {
                // Ruta A: _source es la hitbox con owner = enemigo
                _attacker = _source.owner;
                show_debug_message("[DBG-PARRY] Ruta A: hitbox→owner=" + object_get_name(_attacker.object_index));
            } else if (variable_instance_exists(_source, "parried_stun_duration")
                   &&  !variable_instance_exists(_source, "can_be_parried")) {
                // Ruta B: _source es el enemigo directamente (hit_source apunta al enemy)
                // Guard extra: no tiene can_be_parried (para no confundir con una hitbox enemiga)
                _attacker = _source;
                show_debug_message("[DBG-PARRY] Ruta B: direct enemy=" + object_get_name(_attacker.object_index));
            } else if (variable_instance_exists(_source, "parried_stun_duration")) {
                // Ruta B sin guard — cualquier instancia con parried_stun_duration
                _attacker = _source;
                show_debug_message("[DBG-PARRY] Ruta B2: enemy (fallback)=" + object_get_name(_attacker.object_index));
            }
        }

        show_debug_message("[DBG-PARRY] _source=" + string(_source)
            + "  attacker_found=" + string(instance_exists(_attacker))
            + "  parry_slow_timer=" + string(parry_slow_timer));

        if (instance_exists(_attacker)) {
            // ── Guardar target para el counter ────────────
            // Se almacena SIEMPRE que se identifica el attacker,
            // aunque ability_counterattack = false (limpiado arriba).
            counter_target = _attacker;

            // Dirección del knockback: alejarse del jugador
            var _kdir = sign(_attacker.x - x);
            if (_kdir == 0) _kdir = -facing;

            _attacker.knockback_x         = _kdir * _attacker.parry_knockback_hsp;
            _attacker.move_y              = _attacker.parry_knockback_vsp;
            _attacker.hitstun_timer       = _attacker.parried_stun_duration;
            _attacker.is_parried_stunned  = true;
            _attacker.can_be_countered    = true;
            _attacker.counter_window_timer = _attacker.counter_window_duration;

            // ── Estado visual vulnerable ──────────────────
            if (variable_instance_exists(_attacker, "parried_vulnerable")) {
                _attacker.parried_vulnerable       = true;
                _attacker.parried_vulnerable_timer = _attacker.parried_vulnerable_duration;
            }

            // ── Blink visual del atacante ─────────────────
            // Reutiliza el sistema de hit flash del enemy_parent.
            // Duración del parpadeo: parried_stun_duration (mismo timer que el stun).
            if (variable_instance_exists(_attacker, "enemy_hit_flash_timer")) {
                _attacker.enemy_hit_flash       = true;
                _attacker.enemy_hit_flash_timer = _attacker.parried_stun_duration;
            }

            // ── Cancelar hitbox activa del atacante ───────
            // Si el atacante tiene una hitbox de espada activa, destruirla
            // para que no siga dañando durante el stun del parry.
            if (variable_instance_exists(_attacker, "sword_hitbox_id")
            &&  instance_exists(_attacker.sword_hitbox_id)) {
                with (_attacker.sword_hitbox_id) instance_destroy();
                _attacker.sword_hitbox_id = noone;
            }

            show_debug_message("[DBG-PARRY] PERFECT - ENEMY STUNNED: "
                + object_get_name(_attacker.object_index)
                + "  stun=" + string(_attacker.parried_stun_duration)
                + "  counter_window=" + string(_attacker.counter_window_duration));
        }

        // ── Cancelar bloqueo de recuperación de daño ────────
        // Un parry perfecto cancela inmediatamente el estado de invulnerabilidad
        // que había de un daño anterior. El jugador recupera control total.
        damage_recovery_lock = false;
        damage_recovery_lock_timer = 0;

        return;   // sin daño, sin knockback al jugador, sin hitstun
    }

    // ── BLOCK NORMAL ─────────────────────────────────────
    // Fuera de la ventana perfecta, con block activo + ataque frontal.
    // Primera versión: niega daño y knockback completamente.
    // Futuro: reducir a 1 de daño (block imperfecto) para distinguirlo del parry.
    if (is_blocking && _from_front) {
        show_debug_message("[DBG-BLOCK] BLOCK NORMAL — daño negado, sin knockback");
        return;   // sin daño
    }

    // ── DAÑO NORMAL ──────────────────────────────────────
    // Sin block, o ataque desde atrás.
    base_take_damage(_amount, _source);

    // ── Activar bloqueo de input durante recuperación de daño ──
    // El parent activó is_invulnerable=true y timers en base_take_damage.
    // Ahora activamos el bloqueo que impide movimiento/ataque/dash
    // excepto parry, que es la única defensa activa durante i-frames.
    // IMPORTANTE: la duración del lock es configurable por dificultad,
    // pero también respeta invuln_timer del parent (usa el menor).
    if (is_invulnerable) {
        damage_recovery_lock = true;
        damage_recovery_lock_timer = min(invuln_timer, damage_recovery_lock_duration);
        show_debug_message("[PLAYER] Daño recibido: damage_recovery_lock activado por " + string(damage_recovery_lock_timer) + " frames (dificultad: " + get_difficulty_string() + ")");
    }
};

/// @function player_can_roll()
/// @description Verifica si el jugador puede ejecutar Roll
function player_can_roll() {
    if (is_dead) return false;
    if (!isGrounded) return false;  // Solo en suelo
    if (hitstun_timer > 0) return false;
    if (damage_recovery_lock) return false;
    if (player_state == PSTATE.COUNTER_ATTACK) return false;
    if (player_state == PSTATE.BLOCK) return false;
    if (beat_em_up_active) return false;  // No durante Beat 'em Up
    if (player_state == PSTATE.WALL) return false;
    if (roll_cooldown_timer > 0) return false;
    return true;
};

/// @function start_roll()
/// @description Inicia el Roll Dodge
function start_roll() {
    if (!player_can_roll()) return false;

    roll_active = true;
    roll_timer = roll_duration;
    roll_dir = facing;  // Roll hacia donde mira
    roll_cooldown_timer = roll_cooldown_max;

    // Limpiar estados incompatibles
    attack_buffer = false;
    bow_release_pending = false;
    bow_is_charging = false;

    show_debug_message("[ROLL] Iniciado - duración: " + string(roll_duration) + "f");
    return true;
};

/// @function end_roll()
/// @description Termina el Roll Dodge
function end_roll() {
    roll_active = false;
    roll_timer = 0;
    show_debug_message("[ROLL] Terminado");
};

/// @function update_roll()
/// @description Actualiza la lógica del Roll (movimiento, invulnerabilidad)
/// @details Llamar cada frame en la sección gated del Step
function update_roll() {
    if (!roll_active) return;

    // Decrementar timer
    roll_timer--;
    if (roll_timer <= 0) {
        end_roll();
        return;
    }

    // Aplicar velocidad horizontal
    vel_x = roll_dir * roll_speed;

    // Mantener invulnerabilidad durante el roll
    if (roll_invulnerable) {
        is_invulnerable = true;
        invuln_timer = 1;  // Mantener activo
    }
};

/// @function start_beat_em_up_mode()
/// @description Activa el Beat 'em Up Mode por 5 segundos (300 frames)
function start_beat_em_up_mode() {
    beat_em_up_active = true;
    beat_em_up_timer = beat_em_up_duration;
    beat_combo_index = 0;
    beat_combo_timer = 0;
    beat_em_up_cooldown_timer = 0;
    beat_em_up_attack_active = false;
    combat_mode = "beat_em_up";
    show_debug_message("[BEAT-EM-UP] Modo activado — 5 segundos");
}

/// @function end_beat_em_up_mode()
/// @description Desactiva el Beat 'em Up Mode
function end_beat_em_up_mode() {
    beat_em_up_active = false;
    beat_em_up_timer = 0;
    beat_combo_index = 0;
    beat_combo_timer = 0;
    beat_em_up_attack_active = false;
    beat_em_up_attack_type = "";
    combat_mode = "normal";
    beat_em_up_hitbox_visible = false;  // limpiar debug visual
    show_debug_message("[BEAT-EM-UP] Modo desactivado");
}

/// @function update_beat_em_up_mode()
/// @description Actualiza la lógica de inputs del Beat 'em Up Mode
/// @details Llamar una vez por frame en la sección gated del Step
/// Prioridad de input:
///   1. Dash presionado → cancela Beat 'em Up (manejado en Step_0)
///   2. Arriba + X → Uppercut
///   3. X solo → Heavy Punch
///   4. Z → Punch Combo
function update_beat_em_up_mode() {
    if (!beat_em_up_active || beat_em_up_cooldown_timer > 0) return;

    var _up = global.inp.move_axis < 0;   // arriba detectado
    var _ranged_pressed = global.inp.ranged_pressed;  // X key (normalmente arco)

    // ── Uppercut: Up + X ─────────────────────────────────────
    // TEMP: Desactivado hasta que se implemente nuevas combinaciones
    if (_up && _ranged_pressed && beat_uppercut_enabled) {
        player_start_beat_uppercut();
        show_debug_message("[BEAT-UPPERCUT INPUT] Up + X pressed");
        return;
    }

    // ── Heavy Punch: X solo ───────────────────────────────────
    if (_ranged_pressed) {
        player_start_beat_heavy();
        show_debug_message("[BEAT-HEAVY INPUT] X pressed");
        return;
    }

    // ── Punch Combo: Z ────────────────────────────────────────
    if (global.inp.attack_pressed) {
        // Incrementar combo solo si hay tiempo (dentro de combo window)
        if (beat_combo_timer < beat_combo_window) {
            beat_combo_index = (beat_combo_index + 1) mod 3;
        } else {
            beat_combo_index = 0;
        }
        beat_combo_timer = 0;
        player_start_beat_punch();
        return;
    }
}

/// @function player_start_beat_punch()
/// @description Inicia un punch (del combo de 3 golpes)
function player_start_beat_punch() {
    beat_em_up_attack_type = "punch";
    beat_em_up_attack_active = true;
    beat_em_up_attack_timer = beat_punch_active_duration;
    beat_em_up_cooldown_timer = beat_punch_cooldown;

    // Limpiar enemigos golpeados en este ataque
    ds_list_clear(beat_em_up_enemies_hit);

    // Aplicar damage a enemigos cercanos
    update_beat_em_up_hitbox(beat_punch_damage, beat_punch_reach, beat_punch_height,
                              beat_punch_offset_y, beat_punch_cooldown);
    show_debug_message("[BEAT-PUNCH] Combo #" + string(beat_combo_index + 1));
}

/// @function player_start_beat_heavy()
/// @description Inicia un Heavy Punch — solo si está desbloqueado
function player_start_beat_heavy() {
    // Verificar si está desbloqueado
    if (!beat_heavy_unlocked) {
        show_debug_message("[BEAT-HEAVY] LOCKED - charge = " + string(beat_heavy_charge) + "/" + string(beat_heavy_charge_max));
        return;
    }

    beat_em_up_attack_type = "heavy";
    beat_em_up_attack_active = true;
    beat_em_up_attack_timer = beat_heavy_active_duration;
    beat_em_up_cooldown_timer = beat_heavy_cooldown;

    // Limpiar enemigos golpeados en este ataque
    ds_list_clear(beat_em_up_enemies_hit);

    // Aplicar damage a enemigos con knockback mayor
    update_beat_em_up_hitbox(beat_heavy_damage, beat_heavy_reach, beat_heavy_height,
                              beat_heavy_offset_y, beat_heavy_cooldown,
                              beat_heavy_knockback_hsp, beat_heavy_knockback_vsp);

    // Consumir carga
    beat_heavy_charge = 0;
    beat_heavy_unlocked = false;
    show_debug_message("[BEAT-HEAVY] USED - charge reset");
}

/// @function player_start_beat_uppercut()
/// @description Inicia un Uppercut (arriba + heavy)
function player_start_beat_uppercut() {
    beat_em_up_attack_type = "uppercut";
    beat_em_up_attack_active = true;
    beat_em_up_attack_timer = beat_heavy_active_duration;
    beat_em_up_cooldown_timer = beat_uppercut_cooldown;

    // Lanzar enemigos hacia arriba
    update_beat_em_up_hitbox(beat_uppercut_damage, beat_uppercut_reach, beat_uppercut_height,
                              beat_uppercut_offset_y, beat_uppercut_cooldown,
                              beat_uppercut_enemy_hsp, beat_uppercut_enemy_vsp);
    show_debug_message("[BEAT-UPPERCUT] ¡Arriba!");
}

/// @function update_beat_em_up_hitbox(_damage, _reach, _height, _offset_y, _cooldown, [_kb_hsp], [_kb_vsp])
/// @description Detecta y daña enemigos en el área del ataque Beat 'em Up
/// @param {real} _damage Daño a aplicar
/// @param {real} _reach Alcance horizontal
/// @param {real} _height Altura del hitbox
/// @param {real} _offset_y Offset vertical relativo
/// @param {real} _cooldown Cooldown post-ataque (no usado aquí, solo info)
/// @param {real} _kb_hsp Knockback horizontal (default: 0)
/// @param {real} _kb_vsp Knockback vertical (default: 0)
function update_beat_em_up_hitbox(_damage, _reach, _height, _offset_y, _cooldown,
                                   _kb_hsp = 0, _kb_vsp = 0) {
    // Hitbox origin: adelante del player + offset
    var _hb_x = x + (facing > 0 ? _reach : -_reach);
    var _hb_y = y + _offset_y;
    var _hb_x1 = _hb_x - _reach / 2;
    var _hb_y1 = _hb_y - _height / 2;
    var _hb_x2 = _hb_x + _reach / 2;
    var _hb_y2 = _hb_y + _height / 2;
    var _player_id = id;  // guardar referencia al player para usar en with statement

    // ── DEBUG: guardar hitbox para visualización ─────────────
    beat_em_up_hitbox_x1      = _hb_x1;
    beat_em_up_hitbox_y1      = _hb_y1;
    beat_em_up_hitbox_x2      = _hb_x2;
    beat_em_up_hitbox_y2      = _hb_y2;
    beat_em_up_hitbox_visible = true;

    // ── CARGA DE ENERGÍA: solo para golpes ligeros ──────────
    // Es un golpe ligero si beat_em_up_attack_type == "punch"
    var _is_light_punch = (beat_em_up_attack_type == "punch");

    // Detectar y dañar enemigos espadachín en el área
    if (instance_exists(obj_enemy_swordsman)) {
        with (obj_enemy_swordsman) {
            if (instance_exists(id) && !is_invulnerable &&
                bbox_left < _hb_x2 && bbox_right > _hb_x1 &&
                bbox_top < _hb_y2 && bbox_bottom > _hb_y1) {
                // Verificar si ya fue golpeado en este ataque
                var _already_hit = ds_list_find_index(_player_id.beat_em_up_enemies_hit, id) != -1;

                if (!_already_hit) {
                    // Primer hit a este enemigo en este ataque
                    ds_list_add(_player_id.beat_em_up_enemies_hit, id);

                    // Cargar energía solo si es golpe ligero
                    if (_is_light_punch) {
                        _player_id.beat_heavy_charge += _player_id.beat_light_hit_charge_gain;
                        _player_id.beat_heavy_charge = clamp(_player_id.beat_heavy_charge, 0, _player_id.beat_heavy_charge_max);
                        if (_player_id.beat_heavy_charge >= _player_id.beat_heavy_charge_max) {
                            _player_id.beat_heavy_unlocked = true;
                            show_debug_message("[BEAT-CHARGE] HEAVY READY - charge = " + string(_player_id.beat_heavy_charge));
                        } else {
                            show_debug_message("[BEAT-CHARGE] +1 punch - charge = " + string(_player_id.beat_heavy_charge) + "/" + string(_player_id.beat_heavy_charge_max));
                        }
                    }
                }

                take_damage(_damage, _player_id);  // _player_id = source del daño
                if (_kb_hsp != 0 || _kb_vsp != 0) {
                    vel_x = _kb_hsp;
                    vel_y = _kb_vsp;
                }
            }
        }
    }

    // Detectar y dañar enemigos arquero en el área
    if (instance_exists(obj_enemy_archer)) {
        with (obj_enemy_archer) {
            if (instance_exists(id) && !is_invulnerable &&
                bbox_left < _hb_x2 && bbox_right > _hb_x1 &&
                bbox_top < _hb_y2 && bbox_bottom > _hb_y1) {
                // Verificar si ya fue golpeado en este ataque
                var _already_hit = ds_list_find_index(_player_id.beat_em_up_enemies_hit, id) != -1;

                if (!_already_hit) {
                    // Primer hit a este enemigo en este ataque
                    ds_list_add(_player_id.beat_em_up_enemies_hit, id);

                    // Cargar energía solo si es golpe ligero
                    if (_is_light_punch) {
                        _player_id.beat_heavy_charge += _player_id.beat_light_hit_charge_gain;
                        _player_id.beat_heavy_charge = clamp(_player_id.beat_heavy_charge, 0, _player_id.beat_heavy_charge_max);
                        if (_player_id.beat_heavy_charge >= _player_id.beat_heavy_charge_max) {
                            _player_id.beat_heavy_unlocked = true;
                            show_debug_message("[BEAT-CHARGE] HEAVY READY - charge = " + string(_player_id.beat_heavy_charge));
                        } else {
                            show_debug_message("[BEAT-CHARGE] +1 punch - charge = " + string(_player_id.beat_heavy_charge) + "/" + string(_player_id.beat_heavy_charge_max));
                        }
                    }
                }

                take_damage(_damage, _player_id);  // _player_id = source del daño
                if (_kb_hsp != 0 || _kb_vsp != 0) {
                    vel_x = _kb_hsp;
                    vel_y = _kb_vsp;
                }
            }
        }
    }
}
;

/// @function debug_draw_beat_em_up_hitbox()
/// @description Dibuja el hitbox rojo del ataque Beat 'em Up activo para debug
function debug_draw_beat_em_up_hitbox() {
    // Solo dibujar si hay hitbox activo
    if (!beat_em_up_hitbox_visible) return;

    var _x1 = beat_em_up_hitbox_x1;
    var _y1 = beat_em_up_hitbox_y1;
    var _x2 = beat_em_up_hitbox_x2;
    var _y2 = beat_em_up_hitbox_y2;

    // Guardar estado de draw anterior
    var _prev_alpha = draw_get_alpha();
    var _prev_color = draw_get_color();

    // ── Relleno rojo semitransparente ────────────────────────
    draw_set_alpha(0.35);
    draw_set_color(c_red);
    draw_rectangle(_x1, _y1, _x2, _y2, false);

    // ── Borde rojo sólido ────────────────────────────────────
    draw_set_alpha(1.0);
    draw_set_color(c_red);
    draw_rectangle(_x1, _y1, _x2, _y2, true);

    // ── Debug text ───────────────────────────────────────────
    draw_set_color(c_red);
    draw_set_alpha(1.0);
    var _cx = (_x1 + _x2) / 2;
    var _cy = (_y1 + _y2) / 2;
    draw_text(_cx, _cy, "BEAT: " + beat_em_up_attack_type);

    // Restaurar estado anterior
    draw_set_alpha(_prev_alpha);
    draw_set_color(_prev_color);
}
;
