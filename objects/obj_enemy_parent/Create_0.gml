// ══════════════════════════════════════════════════════════
// OBJ_ENEMY_PARENT — Create
// Clase base para todos los enemigos del juego.
//
// Hereda de obj_actor_parent:
//   gravedad, colisiones de tile, take_damage, hitstun,
//   knockback, i-frames, is_invulnerable, facing, barra de vida.
//
// Hijos directos:
//   obj_enemy_swordsman — enemigo melee con espada
//   obj_enemy_archer    — enemigo a distancia con arco
//
// Jerarquía intencionada:
//   obj_actor_parent
//     └─ obj_enemy_parent    (esta clase)
//          ├─ obj_enemy_swordsman
//          └─ obj_enemy_archer
//
// NOTA: obj_enemy_basic hereda directamente de obj_actor_parent
// (no migrado) — se mantiene como enemigo de prueba original.
// ══════════════════════════════════════════════════════════
event_inherited();   // obj_actor_parent: gravedad, colisiones, salud, métodos

// ── I-frames: desactivados para enemigos comunes ──────────
// Los enemigos pueden recibir golpes repetidos inmediatamente.
// Para bosses o élites que necesiten i-frames:
//   sobreescribir invuln_on_damage = true + ajustar default_invuln.
invuln_on_damage = false;

// ── Parry stun ────────────────────────────────────────────
// Estado de aturdimiento aplicado cuando el jugador ejecuta
// parry perfecto contra un ataque melee de este enemigo.
//
// Flujo:
//   1. Jugador hace parry perfecto → detecta _source.attack_type == ATTACK_TYPE_MELEE
//   2. Se aplica knockback + hitstun extendido al owner (este enemigo)
//   3. is_parried_stunned = true, can_be_countered = true
//   4. counter_window_timer cuenta hacia atrás; al expirar, can_be_countered = false
//   5. is_parried_stunned se limpia cuando hitstun_timer llega a 0
//
// NO implementa el contraataque — solo prepara las variables.
parried_stun_duration  = PARRY_STUN_DURATION;    // frames de hitstun extendido
parry_knockback_hsp    = PARRY_KNOCKBACK_HSP;    // velocidad horizontal retroceso
parry_knockback_vsp    = PARRY_KNOCKBACK_VSP;    // impulso vertical (negativo = arriba)
counter_window_duration = PARRY_COUNTER_WINDOW;  // frames de ventana de contraataque

// Estado de runtime (no modificar directamente):
is_parried_stunned  = false;   // true mientras hitstun proviene de parry
can_be_countered    = false;   // true durante la ventana de contraataque
counter_window_timer = 0;      // cuenta regresiva; > 0 = ventana activa

// ── Estado vulnerable al counter ─────────────────────────
// parried_vulnerable: flag observable por sistemas externos.
//   true  → enemigo queda expuesto para counter attack (no ataca, no persigue).
//   false → recuperó el control.
// parried_vulnerable_timer: cuenta regresiva gated (respeta time_scale).
// parried_vulnerable_duration: duración total de la ventana de vulnerabilidad.
//   Ajustar aquí para darle al jugador más/menos tiempo de contraatacar.
// counter_target_priority: este enemigo es target prioritario para el counter.
parried_vulnerable          = false;
parried_vulnerable_timer    = 0;
parried_vulnerable_duration = PARRY_STUN_DURATION;   // cubre el stun completo (60 f)
counter_target_priority     = true;

// ── Daño por contacto ─────────────────────────────────────
// Cuando el jugador toca físicamente a este enemigo.
// Usa take_damage() del jugador → respeta sus i-frames y parry.
// Deshabilitar en arqueros estáticos, trampas, NPCs o bosses:
//   contact_damage_enabled = false
//
// contact_damage_cooldown_max: frames entre intentos de contacto.
//   Bajo  (10) → daño casi constante al tocar, agresivo.
//   Alto  (60) → una vez por segundo, más permisivo.
contact_damage_enabled      = true;
contact_damage              = 1;
contact_damage_cooldown_max = 30;   // ~0.5 s a 60fps
contact_damage_cooldown     = 0;

// ── Separación entre enemigos ─────────────────────────────
// Impide que dos enemigos se sobrepongan. La fuerza de
// separación se suma a move_x antes de la física, por lo que
// respeta colisión con tiles automáticamente.
//
// enemy_separation_radius:
//   Distancia (px) desde el centro del enemigo hasta donde
//   empieza a empujar. Dos enemigos se separan cuando la suma
//   de sus radios > distancia entre sus centros.
//   Recomendado ≈ mitad del ancho visual del enemigo (16-24 px).
//
// enemy_separation_strength:
//   Velocidad máxima del empuje (px/frame).
//   Debe ser ≥ walk/chase speed para que el bloqueo sea efectivo.
//   Demasiado alto produce vibraciones; demasiado bajo, solapado.
//
// Fórmula aplicada: push = sign(dx) * (t²) * strength * 2
//   donde t = 1 − (dist / combined_radius)  → 0 en el borde, 1 en el centro.
//   La curva cuadrática es suave cerca del umbral y fuerte si se solapan.
enemy_separation_enabled  = true;
enemy_separation_radius   = 20;    // px — recomendado: mitad del ancho colisionable
enemy_separation_strength = 3.0;   // px/frame — ≥ chase_speed para crear fila

// Distancia máxima al jugador para activar bloqueo/fila entre enemigos.
// Si cualquiera de los dos enemigos está más lejos que este valor,
// se ignoran entre sí y pueden cruzarse libremente.
//
// Razonamiento: solo tiene sentido formar fila cuando ambos persiguen
// al jugador y están cerca. Si uno está lejos, no compite por posición.
// Rango sugerido: 140–240 px. Aumentar = fila más larga; reducir = solo los más cercanos.
enemy_queue_distance_to_player = 180;   // px

// Tolerancia vertical para considerar que dos enemigos están en el mismo piso.
// Si abs(y_self - y_vecino) > este valor → se ignora para separación y bloqueo.
//
// Valor sugerido: 16–32 px.
//   16 → solo separa si están casi exactamente al mismo nivel (estricto).
//   32 → tolera pequeñas diferencias de terreno irregular (permisivo).
//
// Ajustar según la altura de los tiles de colisión (actualmente 32px).
// Un valor de 24 cubre ±¾ de tile sin afectar enemigos en pisos distintos.
enemy_same_floor_tolerance = 24;   // px — diferencia máxima de Y para ser "mismo piso"

// Variable de estado: true cuando otro enemigo empuja o bloquea a este.
// Puede leerse desde la IA de los hijos para cancelar avance.
is_blocked_by_enemy = false;

// ── Hard block: detención dura por bloqueador adelante ────
//
// blocks_other_enemies     : este enemigo actúa como pared para los demás
//                            (si alguien se acerca, lo detiene)
// blocked_by_other_enemies : este enemigo se detiene si hay un bloqueador adelante
// enemy_block_distance     : px de brecha entre bordes de bbox para activar el bloqueo
//                            Valores típicos: 8-24 px. Menor = solo se frena al casi tocar.
// blocking_enemy_id        : ID de la instancia que actualmente bloquea a este (noone = libre)
//
// Configuración por tipo de enemigo (sobreescribir en Create del hijo):
//   Enemigos terrestres  → defaults (ambos true)
//   Enemigos voladores   → blocks_other_enemies = false, blocked_by_other_enemies = false
//   Bosses               → blocked_by_other_enemies = false (nunca se detienen)
//   Proyectiles          → no heredan obj_enemy_parent, no aplica
blocks_other_enemies     = true;
blocked_by_other_enemies = true;
enemy_block_distance     = 16;     // px — ajustar según el ancho visual del sprite
blocking_enemy_id        = noone;  // debug: quién bloquea ahora

// ── Salud base ────────────────────────────────────────────
// Sobreescribir en hijos para ajustar resistencia.
max_hp = 3;
hp     = max_hp;

// ── Flags de capacidad de IA ──────────────────────────────
// Controlan qué comportamientos están disponibles para cada tipo de enemigo.
// Sobreescribir en los hijos según diseño.
//
//   can_patrol   : camina de un lado al otro cuando no detecta al jugador.
//   can_chase    : persigue al jugador cuando lo detecta.
//   can_drop_down: en CHASE, puede caer por bordes de plataforma.
//                  Si false, detiene el chase al llegar al borde.
//
// Defaults seguros: patrulla, persigue, NO cae por bordes.
can_patrol    = true;
can_chase     = true;
can_drop_down = false;

// ── Patrulla base ─────────────────────────────────────────
walk_speed  = 2;     // px/frame — sobreescribir en hijos
patrol_dir  = 1;     // +1 derecha | -1 izquierda

// ── Rangos de detección / pérdida de aggro (rectangular 2D) ──
// Reemplazan la detección circular para control independiente en X e Y.
//
//   aggro_range_x/y      : distancia para ACTIVAR persecución.
//   lose_aggro_range_x/y : distancia para DESACTIVAR persecución.
//                          Siempre debe ser > aggro_range_* para evitar
//                          toggle rápido (hysteresis).
//
// El legacy detection_range permanece para compatibilidad con código
// interno del arquero y cualquier uso por point_distance.
detection_range    = 400;   // px circular — compatibilidad legada

aggro_range_x      = 320;   // px horizontal para activar chase
aggro_range_y      = 160;   // px vertical   para activar chase
lose_aggro_range_x = 480;   // px horizontal para perder aggro
lose_aggro_range_y = 240;   // px vertical   para perder aggro

// ── Alcance de ataque melee: configurable por enemigo ────────
// Define el tamaño y posición del hitbox de ataque en rango.
// Sobrescribir en cada enemigo hijo según su arma/tamaño.
// Ejemplo: enemy_attack_reach = 300 para arma larga.
enemy_attack_reach        = 220;   // px horizontal — alcance del ataque
enemy_attack_height       = 120;   // px vertical — alto del hitbox
enemy_attack_offset_y     = -40;   // px — posición vertical relativa al origen

// ── Drop-down: bajar plataformas persiguiendo al jugador ──
// Solo aplica cuando can_drop_down = true.
//
//   player_below_threshold: diferencia de Y (px) para considerar
//     que el jugador está "significativamente abajo".
//     Cuando se cumple, se deshabilita stop_distance en X
//     para que el enemigo avance hasta el borde y caiga.
//
//   drop_down_x_tolerance : distancia horizontal máxima al jugador
//     para activar el modo de bajada. Evita que el enemigo caiga
//     por un borde lejano persiguiendo a un jugador lejano.
player_below_threshold = 48;    // px — player.y - self.y > este valor → está abajo
drop_down_x_tolerance  = 128;   // px — solo cae si el jugador está a esta distancia en X

// ── Pausa de readquisición post-daño ─────────────────────
// Activo tras recibir un golpe. Evita vibración cuando el jugador
// rebota sobre el enemigo (pogo, dash). Sobreescribible en hijos.
reacquire_timer    = 0;
reacquire_wait_max = 20;   // frames
chase_min_dx       = 16;   // px — umbral de distancia mínima horizontal

// ── Timer de ataque común ────────────────────────────────
// Cooldown entre ataques. Decrementado en Step de cada hijo.
attack_cooldown_timer = 0;
attack_cooldown_max   = 90;   // sobreescribir en hijos

// ── FSM — estados base ────────────────────────────────────
// Hijos pueden agregar estados adicionales como variables de instancia.
ESTATE_PATROL = 0;    // patrulla — sin objetivo
ESTATE_CHASE  = 1;    // persecución — jugador detectado
ESTATE_ATTACK = 2;    // atacando (subestados en hijos)
ESTATE_STUN   = 3;    // aturdido — reservado para expansiones futuras
ESTATE_DEAD   = 4;    // muerto   — reservado

estate = ESTATE_PATROL;

// ══════════════════════════════════════════════════════════
// HIT FEEDBACK — override de valores del actor_parent
// ══════════════════════════════════════════════════════════
// Los enemigos usan knockback y hitstun más perceptibles que el default
// del actor (default_knockback_x=5, knockback_y_force=-3, default_hitstun=12).
// Sobreescribir en cada hijo si se necesita un valor distinto.
// Valores via scr_config — ajustar ENEMY_KNOCKBACK_X/Y, ENEMY_HITSTUN ahí.
default_knockback_x = ENEMY_KNOCKBACK_X;     // 14 px/frame (actor default: 5, antiguo: 8)
knockback_y_force   = ENEMY_KNOCKBACK_Y;     // -7 px/frame (actor default: -3, antiguo: -5)
default_hitstun     = ENEMY_HITSTUN;          // 18 frames  (actor default: 12, antiguo: 14)
knockback_decay     = ENEMY_KNOCKBACK_DECAY;  // 0.80 por frame (antiguo: 0.75)

// ── Blink visual al recibir golpe ─────────────────────────
// can_hit_flash: habilita el parpadeo de image_alpha durante el hit.
// enemy_hit_flash_duration: cuántos frames dura el parpadeo.
// enemy_hit_blink_interval: cada cuántos frames cambia alpha (menor = más rápido).
can_hit_flash            = true;
enemy_hit_flash          = false;
enemy_hit_flash_timer    = 0;
enemy_hit_flash_duration = 12;    // frames totales del efecto
enemy_hit_blink_interval = 3;     // frames entre cambios de alpha

// ── Flags de reacción al daño ─────────────────────────────
// can_take_knockback: si false, el enemigo no es empujado.
// can_enter_hitstun:  si false, la IA no se interrumpe al recibir daño.
// enemy_knockback_multiplier: escala el knockback_x resultante.
// enemy_hitstun_multiplier:   escala el hitstun_timer resultante.
// enemy_hit_iframes: 0 = sin invulnerabilidad (combos libres).
//                    >0 = frames de invulnerabilidad post-golpe (para bosses).
can_take_knockback          = true;
can_enter_hitstun           = true;
enemy_knockback_multiplier  = 1.0;
enemy_hitstun_multiplier    = 1.0;
enemy_hit_iframes           = 0;    // 0 = enemigos normales, sin i-frames

// ── Hooks virtuales ───────────────────────────────────────
// Sobreescribir en cada hijo para reacciones específicas.
// Los hijos que necesiten lógica propia DEBEN capturar este método
// antes de sobreescribir: var _p = on_damage; ... _p(_amount, _source);

on_damage = function(_amount, _source) {
    // ── Pausa de readquisición ────────────────────────────
    reacquire_timer = reacquire_wait_max;

    // ── Blink visual ──────────────────────────────────────
    if (can_hit_flash) {
        enemy_hit_flash       = true;
        enemy_hit_flash_timer = enemy_hit_flash_duration;
    }

    // ── Ajustar knockback ─────────────────────────────────
    // knockback_x ya fue calculado por base take_damage. Aplicar flags/multiplier.
    if (!can_take_knockback) {
        knockback_x = 0;
        // Cancelar impulso vertical también
        if (move_y < 0) move_y = 0;
    } else if (enemy_knockback_multiplier != 1.0) {
        knockback_x *= enemy_knockback_multiplier;
    }

    // ── Ajustar hitstun ───────────────────────────────────
    if (!can_enter_hitstun) {
        hitstun_timer = 0;
    } else if (enemy_hitstun_multiplier != 1.0) {
        hitstun_timer = round(hitstun_timer * enemy_hitstun_multiplier);
    }

    // ── I-frames opcionales (para bosses) ─────────────────
    // invuln_on_damage = false en obj_enemy_parent → take_damage no activa i-frames.
    // enemy_hit_iframes > 0 los activa manualmente para enemigos especiales.
    if (enemy_hit_iframes > 0) {
        is_invulnerable = true;
        invuln_timer    = enemy_hit_iframes;
    }

    show_debug_message("[DBG] ENEMY on_damage: obj=" + object_get_name(object_index)
        + "  hp=" + string(hp)
        + "  hitstun=" + string(hitstun_timer)
        + "  knockback=" + string_format(knockback_x, 1, 1)
        + "  flash=" + string(enemy_hit_flash));
};

die = function() {
    show_debug_message("[DBG] ENEMY die(): " + object_get_name(object_index));
    instance_destroy();
};
