// =============================================================
//  scr_config — Fuente única de verdad para escala y geometría
//
//  REGLA: si necesitas ajustar un número que depende del tamaño
//  del personaje, del tile o de la cámara, hazlo AQUÍ.
//  Nunca hardcodees estos valores dentro de los objetos.
// =============================================================

// ── Resolución y puerto ────────────────────────────────────────
//  GAME_W × GAME_H = área del mundo visible (room-pixels).
//  DISPLAY_W × DISPLAY_H = resolución del puerto (pantalla física).
//  Relación: DISPLAY / GAME = factor de escala entero.
//    960×540 → 1920×1080 = escala ×2  (pixel-perfect; 1 px mundo = 2 px pantalla)
//
//  Proporciones del personaje a esta resolución:
//    Sprite 256×256, origin=(128,236) → altura visual ~150 px (estándar 256×256)
//    Con gameplay_zoom_factor=1.25 (vista 1200×675): 150/675 = 22.2 % de pantalla
//    — equivale al feel original del personaje de 118 px a zoom ×1.0 ✓
//    (Estándar anterior: 128×128, origin=(64,118), altura ~72 px)
//
//  Aplicar manualmente en GameMaker IDE:
//    Game Settings › Main › Game Width=1920, Game Height=1080
//    Interpolate colours between pixels = OFF
#macro GAME_W     960
#macro GAME_H     540
#macro DISPLAY_W 1920
#macro DISPLAY_H 1080

// ── Cámara — offset y look-ahead ──────────────────────────────
//  CAM_OFFSET_Y: desplaza el centro de la vista hacia arriba para
//  mostrar más espacio sobre el jugador (plataformas, picos, lectura).
//  Con GAME_H=540 y personaje de 150 px visible, vista gameplay 2560×1440:
//    sin offset → personaje a 50 % de pantalla (centrado)
//    −180 px    → personaje a 900/1440 = 62.5 % desde arriba ✓
//    Cabeza del personaje queda a ~750 px del borde superior → lectura cómoda.
//
//  CAM_LOOKAHEAD: desplazamiento horizontal máx. en la dirección de avance.
//  Proporcional: 2560 × 0.125 = 320 px.
#macro CAM_OFFSET_Y   -180    // px — jugador en tercio inferior (vista 2560×1440)
#macro CAM_LOOKAHEAD   320    // px — look-ahead horizontal máximo (proporcional a vista 2560px)

// ── Tiles ──────────────────────────────────────────────────────
#macro TILE_SIZE          64   // tamaño visual de tile — NO cambiar al migrar colisión

// Nombre de la capa de colisión de tiles. Fuente única de verdad:
// cambiar aquí afecta todos los actores, proyectiles y herramientas.
// Durante la migración 64→32: dejar "tiles_collision" hasta que la
// nueva capa 32×32 esté validada, luego renombrarla en el IDE a
// "tiles_collision" (sin tocar este macro) — cero cambios de código.
#macro COLLISION_LAYER    "tiles_collision_32"

// ── Anclas verticales del personaje (offset desde origen = pies) ─
//  Sprite estándar 256×256: origin=(128, 236), altura visual ~150 px.
//  Hitbox recomendada (Opción B — ajustada para gameplay):
//    bbox_left=100, bbox_right=156, bbox_top=96, bbox_bottom=236
//    col_left=−28, col_right=+28, col_top=−140, col_bottom=0
//    Área de colisión: 56×140 px (torso y piernas; cabeza/capa fuera)
//
//  Si el sprite cambia, actualizar SOLO estas macros.
//  Todos los sistemas (arco, espada, pogo, indicador aim) leen de aquí.
//
//  Escala ×2 desde el estándar anterior (128×128, 72 px visual).
//  Coordenadas: negativo = ARRIBA desde los pies, positivo = abajo.
#macro PLAYER_FEET_Y        0    // origen — contacto con el suelo
#macro PLAYER_KNEE_Y      -38    // rodillas  (~25 % de 150 px) — era -19 en 128×128
#macro PLAYER_HIP_Y       -76    // cadera    (~51 %)            — era -38
#macro PLAYER_CHEST_Y     -98    // pecho/mano — ancla de arma, disparo, aim (~65 %) — era -49
#macro PLAYER_SHOULDER_Y -136    // hombros   (~91 %)            — era -68
#macro PLAYER_HEAD_TOP_Y -176    // cima de cabeza (referencia visual) — era -88

// ── Tipos de ataque (damage sources) ─────────────────────────────
//  Asignado en cada damage source para permitir reacciones específicas.
//  ATTACK_TYPE_MELEE      → golpe cuerpo a cuerpo (activa parry stun en el atacante)
//  ATTACK_TYPE_PROJECTILE → bala/flecha (proyectil; destruida o desviada por parry)
#macro ATTACK_TYPE_MELEE       0
#macro ATTACK_TYPE_PROJECTILE  1

// ── Knockback del jugador al recibir daño ────────────────────────
//  Aplicado cuando un enemigo golpea al jugador.
//  PLAYER_KNOCKBACK_X  : px/frame de empuje horizontal (actor default: 5)
//  PLAYER_KNOCKBACK_Y  : impulso vertical al recibir golpe (actor default: -3)
//  PLAYER_HITSTUN      : frames de hitstun (actor default: 12)
//  PLAYER_KNOCKBACK_DECAY : factor por frame (0.80 = decae en ~20 frames)
#macro PLAYER_KNOCKBACK_X      24   // empuje fuerte — sentir el golpe
#macro PLAYER_KNOCKBACK_Y      -8   // salto hacia atrás visible
#macro PLAYER_HITSTUN          20   // suficiente para ver el knockback completo
#macro PLAYER_KNOCKBACK_DECAY  0.80 // decae gradualmente (no teletransporte)

// ── Knockback de enemigos al recibir daño ────────────────────────
//  Aplicado cuando el jugador golpea a un enemigo.
//  ENEMY_KNOCKBACK_X  : px/frame de empuje horizontal (enemy_parent actual: 8)
//  ENEMY_KNOCKBACK_Y  : impulso vertical (enemy_parent actual: -5)
//  ENEMY_HITSTUN      : frames de hitstun (enemy_parent actual: 14)
//  ENEMY_KNOCKBACK_DECAY : factor por frame
#macro ENEMY_KNOCKBACK_X      14   // empuje claro — "peso" del golpe
#macro ENEMY_KNOCKBACK_Y      -7   // saltito hacia atrás
#macro ENEMY_HITSTUN          18   // da tiempo a ver el blink y el retroceso
#macro ENEMY_KNOCKBACK_DECAY  0.80 // igual que el jugador

// ── Parry Stun del enemigo ────────────────────────────────────────
//  Aplicado al enemigo cuando el jugador ejecuta parry perfecto
//  contra un ataque melee de ese enemigo.
//  PARRY_STUN_DURATION   : frames que el enemigo queda congelado (hitstun extendido)
//  PARRY_KNOCKBACK_HSP   : velocidad horizontal inicial del retroceso
//  PARRY_KNOCKBACK_VSP   : impulso vertical inicial (negativo = arriba)
//  PARRY_COUNTER_WINDOW  : frames disponibles para ejecutar contraataque (futuro)
#macro PARRY_STUN_DURATION     60   // ~1 s a 60 fps
#macro PARRY_KNOCKBACK_HSP      3   // px/frame de retroceso horizontal
#macro PARRY_KNOCKBACK_VSP     -3   // px/frame de salto vertical
#macro PARRY_COUNTER_WINDOW    45   // frames de ventana de contraataque

// ── Equipos / Facciones ───────────────────────────────────────────
//  Usados por obj_projectile_parent para identificar origen del proyectil.
//  Extensible a sistemas de friendly-fire, inmunidad por tipo, etc.
#macro TEAM_NEUTRAL  0   // sin facción (trampas, entorno)
#macro TEAM_PLAYER   1   // disparado por el jugador
#macro TEAM_ENEMY    2   // disparado por un enemigo

// ── Dash Slide: hitbox reducida ───────────────────────────────────
//  col_top normal: -140 px (hitbox completa desde pies hasta casi hombros).
//  col_top slide : -72 px (mitad inferior del cuerpo — permite pasar por túneles bajos).
//  Proporción mantenida ×2 desde el estándar 128×128 (era -36).
//  Ajustar PLAYER_SLIDE_COL_TOP según el diseño de nivel:
//    más negativo  → hitbox más alta (menos margen para túneles)
//    menos negativo → hitbox más baja (más permisivo, solo cubre piernas)
#macro PLAYER_SLIDE_COL_TOP  -72   // px — col_top reducido durante dash slide (era -36 en 128×128)

// ── Offset visual del sprite (ground embedding) ────────────────
//  El sprite se dibuja PLAYER_DRAW_OY px MÁS ABAJO que la posición física.
//  Nota: con origin_y=236 en canvas de 256px, el sprite ya extiende
//  20px por debajo del origen → hay embedding natural (×2 del estándar anterior).
//  Este offset añade un desplazamiento extra para el efecto de pisada.
//  Ajustar junto al arte del tile. 0 = sin desplazamiento adicional.
#macro PLAYER_DRAW_OY       8    // px extra hacia abajo — era 4 en 128×128 (×2)

// ── Alcance horizontal del personaje ──────────────────────────
//  PLAYER_HAND_REACH: distancia desde el centro al extremo de la mano.
#macro PLAYER_HAND_REACH   68    // px hacia adelante — era 34 en 128×128 (×2)

// ── Sprite de ataque 1 ────────────────────────────────────────
//  spr_player_attack_1: 256×256 px (estándar nuevo), origin=(128,236), 10 frames, 30fps.
//  Canvas cuadrado con espacio para la espada a la derecha del cuerpo.
//  Al facing=-1 (izquierda), GM voltea alrededor de xorigin=128 → espada va a la izquierda.
//
//  Velocidad de imagen: playbackSpeed=30 con juego a 60fps = 0.5 frames/step.
//  10 frames / 0.5 = 20 steps totales = ataque_1_frames (20). Coinciden exactamente.
//
//  Si ajustás el sprite y el timing no coincide, modificar attack_1_frames
//  en obj_player/Create_0.gml para que = sprite_frames × (game_fps / sprite_fps).

// ── Hitbox de espada (combo normal) ───────────────────────────
//  SWORD_HITBOX_Y == PLAYER_CHEST_Y → la hitbox parte del nivel de la mano.
//  Con facing=+1: hitbox_x=x+68; el área de colisión va de x+27 a x+109.
//  col_right=+28 → el borde izquierdo de la espada roza el borde del cuerpo ✓
//  Escala ×2 desde estándar 128×128 (era X=34, Y=-49, W=41, H=41).
#macro SWORD_HITBOX_X      68    // px hacia adelante — era 34 en 128×128 (×2)
#macro SWORD_HITBOX_Y     -98    // px sobre el origen (= PLAYER_CHEST_Y) — era -49
#macro SWORD_HITBOX_W      82    // ancho total del área de golpe — era 41
#macro SWORD_HITBOX_H      82    // alto total del área de golpe  — era 41

// ── Hitbox de pogo / downward slash ───────────────────────────
//  Centrada debajo de los pies; NO se multiplica por facing.
//  Escala ×2 desde estándar 128×128 (era Y=22, W=30, H=45).
#macro POGO_HITBOX_X        0    // centrado horizontalmente (sin cambio)
#macro POGO_HITBOX_Y       44    // px BAJO el origen — era 22 en 128×128 (×2)
#macro POGO_HITBOX_W       60    // ancho del área de golpe pogo — era 30
#macro POGO_HITBOX_H       90    // alcance vertical hacia abajo  — era 45

// ── Barra de vida flotante (world-space, actores) ─────────────
//  Mostrada sobre los enemigos. El jugador usa barra de HUD (Draw GUI).
//  Ajustada para ser proporcional al nuevo tamaño visual de los sprites.
#macro HPBAR_WIDTH         90    // px de ancho — era 60 en 128×128
#macro HPBAR_HEIGHT         8    // px de alto  — era 6
#macro HPBAR_OFFSET_Y     -20    // px sobre col_top del actor — era -15

// ── Block / Parry del jugador ──────────────────────────────────
//  PARRY_WINDOW_FRAMES : ventana perfecta al presionar block (frames reales).
//  PARRY_SLOW_DURATION : frames de slow-mo post-parry (frames reales, sección always).
//  COUNTERATTACK_WINDOW: ventana de contraataque disponible (frames gated — respeta time_scale).
//  PARRY_COOLDOWN_MAX  : cooldown entre parries (frames reales, evita spam).
// ── VALORES TEMPORALES DE DEBUG ── (revertir antes de producción)
// Para producción:
//   PARRY_WINDOW_FRAMES  → 8   (~0.13 s, ventana exigente)
//   PARRY_SLOW_DURATION  → 10  (slow-mo breve pero perceptible)
// TEMP: ventana generosa y slow-mo largo para poder testear cómodamente el timing.
#macro PARRY_WINDOW_FRAMES     25    // TEMP DEBUG VALUE (normal: 8) ← cambiar a 8 para producción
#macro PARRY_SLOW_DURATION     60    // TEMP DEBUG VALUE (normal: 10) ← cambiar a 10 para producción
#macro COUNTERATTACK_WINDOW    20    // ventana de contra-ataque futuro
#macro PARRY_COOLDOWN_MAX      20    // cooldown entre intentos de bloqueo

// ── Enemigo: Espadachín ────────────────────────────────────────
#macro ESWORDSMAN_AGGRO_RANGE      350   // px — rango de detección al jugador

// Rango de ataque en dos fases:
//   TRIGGER: distancia a la que el enemigo DECIDE atacar y entra en WINDUP.
//            Mientras el jugador esté a más de STOP_DIST, sigue avanzando.
//   STOP:    distancia a la que se detiene, cuenta el timer y dispara la hitbox.
//            El hitbox se extiende desde el origen hasta TRIGGER_DIST.
// Para ajustar la "reacción" del enemigo: solo cambiar TRIGGER.
// Para ajustar el alcance real del golpe: cambiar TRIGGER (también cambia la hitbox).
#macro ESWORDSMAN_ATTACK_TRIGGER_DIST  220  // px horizontal — enemigo decide atacar + alcance real hitbox
#macro ESWORDSMAN_ATTACK_STOP_DIST      64  // px horizontal — se detiene aquí, cuenta windup, dispara

// Hitbox del ataque: se extiende desde el origen del enemigo hasta TRIGGER_DIST.
// Centrado en TRIGGER_DIST/2 con ancho TRIGGER_DIST = alcance continuo [0, TRIGGER_DIST].
#macro ESWORDSMAN_HITBOX_OFFSET_X  110  // px = TRIGGER_DIST / 2 — centro del hitbox
#macro ESWORDSMAN_HITBOX_OFFSET_Y   -40 // px hacia arriba del origen (cuerpo/torso del enemigo)
#macro ESWORDSMAN_HITBOX_W          220 // px = TRIGGER_DIST — cubre desde 0 hasta trigger_dist
#macro ESWORDSMAN_HITBOX_H          120 // px alto — torso + piernas del jugador

// Tolerancia vertical: si el jugador está más arriba/abajo que esto, no atacar.
// Aumentada a ×1.5 del valor anterior para mantener el feel de combate con el jugador más alto.
// Un jugador de 150 px tiene más "zona de combate" vertical que uno de 72 px.
#macro ESWORDSMAN_ATTACK_VERT_TOL   72   // px vertical — era 48 con sprite 128×128 (×1.5)
#macro ESWORDSMAN_WINDUP            30   // frames de anticipación del ataque
#macro ESWORDSMAN_ACTIVE            12   // frames con hitbox de espada activa
#macro ESWORDSMAN_COOLDOWN          90   // frames entre ataques
#macro ESWORDSMAN_DAMAGE             1   // daño por golpe

// ── Super Energy (mana / super meter) ────────────────────────────
//  Recurso acumulado por golpes exitosos. Base para futuros super ataques.
//
//  SUPER_ENERGY_MAX          : tope del medidor.
//  SUPER_ENERGY_RECHARGE_*   : energía ganada por cada tipo de golpe.
//    Ajustar aquí para cambiar la velocidad de carga del super.
//  SUPER_ATTACK_COST_*       : costo en energía de cada futuro super ataque.
//    No se gastan todavía — los super ataques no están implementados.
#macro SUPER_ENERGY_MAX              100
#macro SUPER_ENERGY_RECHARGE_SWORD     5   // espada normal, en suelo
#macro SUPER_ENERGY_RECHARGE_AIR_SWORD 6   // espada normal, en aire
#macro SUPER_ENERGY_RECHARGE_POGO      8   // downward slash / pogo (hit confirmado)
#macro SUPER_ENERGY_RECHARGE_ARROW     5   // flecha con hit confirmado
#macro SUPER_ENERGY_RECHARGE_PARRY    10   // parry perfecto exitoso
#macro SUPER_ENERGY_RECHARGE_COUNTER  15   // counter attack con hit confirmado

// ── Costos de futuros super ataques ──────────────────────────────
#macro SUPER_ATTACK_COST_UP       25   // ↑ + ataque
#macro SUPER_ATTACK_COST_DOWN     25   // ↓ + ataque (distinto al pogo)
#macro SUPER_ATTACK_COST_FORWARD  30   // → (facing) + ataque
#macro SUPER_ATTACK_COST_BACK     30   // ← (contra facing) + ataque

// ── Air Sword Bounce ─────────────────────────────────────────────
//  Pequeño impulso vertical al golpear un enemigo con espada normal en el aire.
//  NO aplica para downward slash / pogo (que tiene su propio rebote fuerte).
//
//  AIR_SWORD_BOUNCE_SPEED    : px/frame hacia arriba (negativo = arriba).
//                              Rango sugerido: -3 (suave) a -6 (notorio).
//  AIR_SWORD_BOUNCE_COOLDOWN : frames antes de poder volver a rebotar.
//                              Evita multi-bounce si la hitbox permanece en contacto.
#macro AIR_SWORD_BOUNCE_SPEED      -5   // px/frame — impulso suave visible
#macro AIR_SWORD_BOUNCE_COOLDOWN    8   // frames — ventana anti-multi-bounce

// ── Counter Attack (contraataque post-parry) ─────────────────────
//  Activado cuando el jugador presiona ataque durante la ventana de parry.
//  El player se lanza automáticamente hacia counter_target.
//  COUNTER_DASH_SPEED        : px/frame del lanzamiento automático
//  COUNTER_DASH_DURATION     : frames que dura el dash de counter
//  COUNTER_DAMAGE_MULTIPLIER : ×daño de la espada normal
//  COUNTER_HITBOX_W/H        : área de la hitbox del counter (más grande que espada normal)
#macro COUNTER_DASH_SPEED         32    // px/frame — rápido y decidido
#macro COUNTER_DASH_DURATION      12    // frames de viaje (~0.2 s a 60 fps)
#macro COUNTER_DAMAGE_MULTIPLIER   3.0  // × sword_damage_1 — golpe decisivo
#macro COUNTER_HITBOX_W          120    // px — área ancha para compensar la velocidad
#macro COUNTER_HITBOX_H           80    // px — altura generosa

// ── Enemigo: Arquero ───────────────────────────────────────────
#macro EARCHER_AGGRO_RANGE     500   // px — rango de detección
#macro EARCHER_AIM_TIME         45   // frames de carga antes de disparar
#macro EARCHER_SHOOT_COOLDOWN   90   // frames entre disparos
#macro EARCHER_AIM_MIN         -25   // ángulo mínimo (arriba, grados)
#macro EARCHER_AIM_MAX          25   // ángulo máximo (abajo, grados)
#macro EARCHER_DAMAGE            1   // daño de la flecha enemiga
