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
//    Sprite 128×128, origin=(64,118) → altura visual ~72 px
//    72 / 540 = 13.3 % de pantalla → zona Mega Man X4 / Have a Nice Death ✓
//    Con zoom K (×1.25 → 675px alto): 72/675 = 10.7 % (más espacio de escenario) ✓
//    (Sprite anterior: 192×128, ~118px visual — rescalado ×0.75 con tools/rescale_player_sprites.py)
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
//  Con GAME_H=540 y personaje de 118 px visible:
//    sin offset → personaje a 50 % de pantalla (centrado)
//    −50 px     → personaje a 320/540 = 59 % desde arriba (tercio inferior) ✓
//
//  CAM_LOOKAHEAD: desplazamiento horizontal máx. en la dirección de avance.
//  Proporcional: 960 × 0.125 = 120 px.
#macro CAM_OFFSET_Y    -50    // px — jugador en tercio inferior del frame
#macro CAM_LOOKAHEAD   120    // px — look-ahead horizontal máximo

// ── Tiles ──────────────────────────────────────────────────────
#macro TILE_SIZE          64   // tamaño visual de tile — NO cambiar al migrar colisión

// Nombre de la capa de colisión de tiles. Fuente única de verdad:
// cambiar aquí afecta todos los actores, proyectiles y herramientas.
// Durante la migración 64→32: dejar "tiles_collision" hasta que la
// nueva capa 32×32 esté validada, luego renombrarla en el IDE a
// "tiles_collision" (sin tocar este macro) — cero cambios de código.
#macro COLLISION_LAYER    "tiles_collision_32"

// ── Anclas verticales del personaje (offset desde origen = pies) ─
//  Sprite actual: 128×128 px, origin=(64, 118).
//  Altura visual sobre los pies: ~72 px (rescalado ×0.75 desde 118 px).
//  Hitbox física: left=48, right=80, top=46, bottom=118
//    col_left=−16, col_right=+16, col_top=−72, col_bottom=0
//    Área de colisión: 32×72 px (torso y piernas; cabeza fuera)
//
//  Si el sprite cambia, actualizar SOLO estas macros.
//  Todos los sistemas (arco, espada, pogo, indicador aim) leen de aquí.
//
//  Coordenadas: negativo = ARRIBA desde los pies, positivo = abajo.
#macro PLAYER_FEET_Y        0    // origen — contacto con el suelo
#macro PLAYER_KNEE_Y      -19    // rodillas  (~21 % de 72 px) — era -25
#macro PLAYER_HIP_Y       -38    // cadera    (~42 %)           — era -50
#macro PLAYER_CHEST_Y     -49    // pecho/mano — ancla de arma, disparo, aim (~55 %) — era -65
#macro PLAYER_SHOULDER_Y  -68    // hombros   (~76 %)           — era -90
#macro PLAYER_HEAD_TOP_Y  -88    // cima de cabeza (referencia visual) — era -118

// ── Tipos de ataque (damage sources) ─────────────────────────────
//  Asignado en cada damage source para permitir reacciones específicas.
//  ATTACK_TYPE_MELEE      → golpe cuerpo a cuerpo (activa parry stun en el atacante)
//  ATTACK_TYPE_PROJECTILE → bala/flecha (proyectil; destruida o desviada por parry)
#macro ATTACK_TYPE_MELEE       0
#macro ATTACK_TYPE_PROJECTILE  1

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
//  col_top normal: -72 px (hitbox completa desde pies hasta hombros).
//  col_top slide : -36 px (mitad inferior del cuerpo — permite pasar por túneles bajos).
//  Ajustar PLAYER_SLIDE_COL_TOP según el diseño de nivel:
//    más negativo  → hitbox más alta (menos margen para túneles)
//    menos negativo → hitbox más baja (más permisivo, solo cubre piernas)
#macro PLAYER_SLIDE_COL_TOP  -36   // px — col_top reducido durante dash slide en suelo

// ── Offset visual del sprite (ground embedding) ────────────────
//  El sprite se dibuja PLAYER_DRAW_OY px MÁS ABAJO que la posición física.
//  Nota: con origin_y=118 en canvas de 128px, el sprite ya extiende
//  10px por debajo del origen → hay embedding natural.
//  Este offset añade un desplazamiento extra para el efecto de pisada.
//  Ajustar junto al arte del tile. 0 = sin desplazamiento adicional.
#macro PLAYER_DRAW_OY       4    // px extra hacia abajo (verificar tras rescale)

// ── Alcance horizontal del personaje ──────────────────────────
//  PLAYER_HAND_REACH: distancia desde el centro al extremo de la mano.
#macro PLAYER_HAND_REACH   34    // px hacia adelante — era 45 (×0.75)

// ── Sprite de ataque 1 ────────────────────────────────────────
//  spr_player_attack_1: 192×128 px, origin=(64,118), 10 frames, 30fps.
//  Canvas más ancho (192 px) para dar espacio a la espada a la derecha del cuerpo.
//  Al facing=-1 (izquierda), GM voltea alrededor de xorigin=64 → espada va a la izquierda.
//
//  Velocidad de imagen: playbackSpeed=30 con juego a 60fps = 0.5 frames/step.
//  10 frames / 0.5 = 20 steps totales = ataque_1_frames (20). Coinciden exactamente.
//
//  Si ajustás el sprite y el timing no coincide, modificar attack_1_frames
//  en obj_player/Create_0.gml para que = sprite_frames × (game_fps / sprite_fps).

// ── Hitbox de espada (combo normal) ───────────────────────────
//  SWORD_HITBOX_Y == PLAYER_CHEST_Y → la hitbox parte del nivel de la mano.
//  Con facing=+1: hitbox_x=x+34; el área de colisión va de x+14 a x+55.
//  col_right=+16 → el borde izquierdo de la espada roza el borde del cuerpo ✓
#macro SWORD_HITBOX_X      34    // px hacia adelante — era 45 (×0.75)
#macro SWORD_HITBOX_Y     -49    // px sobre el origen (= PLAYER_CHEST_Y) — era -65
#macro SWORD_HITBOX_W      41    // ancho total del área de golpe — era 55
#macro SWORD_HITBOX_H      41    // alto total del área de golpe  — era 55

// ── Hitbox de pogo / downward slash ───────────────────────────
//  Centrada debajo de los pies; NO se multiplica por facing.
#macro POGO_HITBOX_X        0    // centrado horizontalmente
#macro POGO_HITBOX_Y       22    // px BAJO el origen — era 30 (×0.75)
#macro POGO_HITBOX_W       30    // ancho del área de golpe pogo — era 40
#macro POGO_HITBOX_H       45    // alcance vertical hacia abajo  — era 60

// ── Barra de vida flotante (world-space, actores) ─────────────
//  Mostrada sobre los enemigos. El jugador usa barra de HUD (Draw GUI).
#macro HPBAR_WIDTH         60    // px de ancho
#macro HPBAR_HEIGHT         6    // px de alto
#macro HPBAR_OFFSET_Y     -15    // px sobre col_top del actor

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
// Distancia de parada y activación de ataque.
// Debe ser <= hitbox_offset_x + hitbox_w/2 (alcance real del golpe).
// Fórmula: esword_hitbox_offset_x(44) + esword_hitbox_w/2(26) = 70 px alcance.
// Usar 60 deja 10 px de margen → golpe garantizado.
#macro ESWORDSMAN_ATTACK_STOP_DIST  60   // px horizontal — detenerse y atacar aquí
// Tolerancia vertical: si el jugador está más arriba/abajo que esto, no atacar.
// Hitbox ocupa y-39 a y+3 (offset_y=-18, h/2=21). Con 48 px cubre saltos normales.
#macro ESWORDSMAN_ATTACK_VERT_TOL   48   // px vertical — máx diferencia de Y para atacar
#macro ESWORDSMAN_WINDUP            30   // frames de anticipación del ataque
#macro ESWORDSMAN_ACTIVE            12   // frames con hitbox de espada activa
#macro ESWORDSMAN_COOLDOWN          90   // frames entre ataques
#macro ESWORDSMAN_DAMAGE             1   // daño por golpe

// ── Enemigo: Arquero ───────────────────────────────────────────
#macro EARCHER_AGGRO_RANGE     500   // px — rango de detección
#macro EARCHER_AIM_TIME         45   // frames de carga antes de disparar
#macro EARCHER_SHOOT_COOLDOWN   90   // frames entre disparos
#macro EARCHER_AIM_MIN         -25   // ángulo mínimo (arriba, grados)
#macro EARCHER_AIM_MAX          25   // ángulo máximo (abajo, grados)
#macro EARCHER_DAMAGE            1   // daño de la flecha enemiga
