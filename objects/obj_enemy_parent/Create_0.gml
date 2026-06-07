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

// Variable de estado: true cuando otro enemigo empuja a este.
// Puede leerse desde la IA de los hijos para cancelar avance.
is_blocked_by_enemy = false;

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

// ── Hooks virtuales ───────────────────────────────────────
// Sobreescribir en cada hijo para reacciones específicas.

on_damage = function(_amount, _source) {
    // Pausa de readquisición: evita vibración post-pogo
    reacquire_timer = reacquire_wait_max;
    show_debug_message("[DBG] ENEMY on_damage: obj=" + object_get_name(object_index)
        + "  hp=" + string(hp)
        + "  hitstun=" + string(hitstun_timer));
};

die = function() {
    show_debug_message("[DBG] ENEMY die(): " + object_get_name(object_index));
    instance_destroy();
};
