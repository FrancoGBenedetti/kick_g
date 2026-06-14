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

// spr_set: asigna sprite sin reiniciar image_index si ya es el mismo.
// Seguro llamarlo cada frame — no provoca parpadeo ni restart de animación.
spr_set = function(_spr) {
    if (sprite_index != _spr) {
        sprite_index = _spr;
        image_index  = 0;
        image_speed  = 1;
    }
};

// ── Movimiento horizontal ─────────────────────────────────
max_walk_speed    = 4;    // px/frame
ground_accel      = 1.2;  // px/frame²
ground_decel      = 1.8;  // px/frame²
ground_turn_accel = 2.0;  // px/frame²
air_accel         = 0.7;  // px/frame²
air_decel         = 0.3;  // px/frame²

vel_x = 0;

// ── Movimiento vertical ───────────────────────────────────
jump_speed          = -10;
wall_slide_max_fall = 2;

// ── Wall jump ─────────────────────────────────────────────
wall_jump_x           = 3;
wall_jump_y           = -10;
wall_jump_lock_frames = 6;
wallJumpLockTimer     = 0;
wall_jump_dir         = 0;

// ── Wall Dash Jump ────────────────────────────────────────
// Ejecutado desde wallslide con dash + jump simultáneos.
// Impulso mayor que wall jump normal; hereda momentum del dash.
wall_dash_jump_x = 9;    // velocidad horizontal alejándose del muro (vs wall_jump_x=3)
wall_dash_jump_y = -13;  // velocidad vertical hacia arriba (vs wall_jump_y=-10)

// ── Jump buffer ───────────────────────────────────────────
jump_buffer_max = 8;
jumpBufferTimer = 0;

// ── Dash ──────────────────────────────────────────────────
dash_speed        = 10;   // px/frame — velocidad de dash (MMX: rápido y corto)
dash_frames       = 16;   // duración en frames (~0.27s a 60fps)  [+14% vs original]
dash_cooldown_max = 20;   // frames hasta poder volver a dashear
dashTimer         = 0;
dashCooldownTimer = 0;
dash_was_grounded = false; // contexto del dash activo (para determinar estado post-dash)
can_air_dash      = true;  // se consume al dashear en el aire; se restaura al aterrizar

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
dash_jump_speed     = 9;    // techo de vel_x durante boost (walk=4, dash_speed=10)
dash_jump_friction  = 0.2;  // rate aéreo misma dirección — decae suave al mantener dir
dash_jump_grace     = 0;    // cuenta regresiva de elegibilidad; >0 = dash grounded reciente
dash_jump_grace_max = 24;   // dash_frames(16) + jump_buffer_max(8)
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
pogo_bounce_speed = -8;     // velocidad vertical al rebotar (neg = arriba)
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

// ── Estado de movimiento ──────────────────────────────────
player_state = PSTATE.FALL;

// ══════════════════════════════════════════════════════════
// SALUD — override de los valores del parent
// ══════════════════════════════════════════════════════════
// Estas líneas corren DESPUÉS de event_inherited(), por lo que
// sobreescriben correctamente los valores base del actor.

max_hp = 6;       // el jugador aguanta más que un actor genérico
hp     = max_hp;

// Override de i-frames: el jugador tiene más tiempo de invulnerabilidad.
// Nota: la variable canónica es default_invuln (renombrada desde invulnerability_max).
default_invuln = 90;   // ~1.5s — más i-frames que un enemigo genérico (base = 60)

// Barra de vida: el jugador usa barra de HUD (Draw GUI), no barra flotante.
// La barra flotante (Draw_0 del parent) se suprime con este flag.
show_world_healthbar = false;

// on_damage: reacción específica del jugador al recibir daño.
// Sobreescribe el stub del parent. Responsabilidades:
//   1. Cancelar estados de ataque activos (interrumpir el combo)
//   2. Cancelar modo de apuntado aéreo del arco
//   3. DEBUG — confirmar daño recibido (quitar cuando el sistema esté validado)
on_damage = function(_amount, _source) {
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
    ||  player_state == PSTATE.DOWN_SLASH) {
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
ability_counterattack  = false;  // contraataque post-parry — NO implementado todavía

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
parry_window_max     = PARRY_WINDOW_FRAMES;   // valor de configuración — leer para debug/UI
parry_slow_timer     = 0;       // frames restantes de slow-mo post-parry (frames reales)
parry_cooldown_timer = 0;       // cooldown tras salir de block (frames reales)
can_counterattack    = false;   // activado tras parry perfecto — futuro contraataque
counterattack_timer  = 0;       // ventana de contraataque disponible (frames gated)
counter_window_max   = PARRY_COUNTER_WINDOW;  // referencia de configuración

// ── Variables alias / estado observable ─────────────────
// parry_active  : equivale a is_parrying; nombre más semántico para sistemas externos.
// parry_success : true durante ~3 frames tras un parry perfecto (para efectos/audio futuros).
// parry_success_timer: cuenta regresiva de parry_success (frames reales).
parry_active        = false;   // sincronizado con is_parrying en Step_0 (sección always)
parry_success       = false;   // flag de un parry exitoso — true ≈ 3 frames
parry_success_timer = 0;       // cuenta regresiva; parry_success = (timer > 0)

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
        parry_slow_timer     = PARRY_SLOW_DURATION;
        parry_window_timer   = 0;
        is_parrying          = false;
        parry_active         = false;
        parry_cooldown_timer = PARRY_COOLDOWN_MAX;

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
        }

        // ── Stun al atacante (solo ataques melee) ─────────
        // Identifica al owner del damage source y le aplica
        // knockback + hitstun extendido + ventana de contraataque.
        //
        // Condiciones:
        //   • _source existe y tiene attack_type (es un damage source)
        //   • attack_type == ATTACK_TYPE_MELEE (no proyectiles)
        //   • _source.owner existe y tiene parried_stun_duration
        //     (es un enemigo con soporte de parry stun)
        //
        // Proyectiles (ATTACK_TYPE_PROJECTILE) se destruyen por el
        // sistema existente pero NO noquean al arquero.
        if (instance_exists(_source)
        &&  variable_instance_exists(_source, "attack_type")
        &&  _source.attack_type == ATTACK_TYPE_MELEE
        &&  instance_exists(_source.owner)
        &&  variable_instance_exists(_source.owner, "parried_stun_duration")) {

            var _attacker = _source.owner;
            // Dirección del knockback: alejarse del jugador
            var _kdir = sign(_attacker.x - x);
            if (_kdir == 0) _kdir = -facing;

            _attacker.knockback_x         = _kdir * _attacker.parry_knockback_hsp;
            _attacker.move_y              = _attacker.parry_knockback_vsp;
            _attacker.hitstun_timer       = _attacker.parried_stun_duration;
            _attacker.is_parried_stunned  = true;
            _attacker.can_be_countered    = true;
            _attacker.counter_window_timer = _attacker.counter_window_duration;

            show_debug_message("[DBG-PARRY] PERFECT - ENEMY STUNNED: "
                + object_get_name(_attacker.object_index)
                + "  stun=" + string(_attacker.parried_stun_duration)
                + "  counter_window=" + string(_attacker.counter_window_duration));
        }

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
};
