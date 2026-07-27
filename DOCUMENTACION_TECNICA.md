# Documentación técnica — kick_g

> Estado: documentación basada en los recursos y código actualmente versionados. Describe la implementación existente; algunos sistemas contienen comentarios de trabajo, valores temporales de debug o puntos de extensión futuros.

## 1. Resumen técnico

`kick_g` es un juego 2D de acción/plataformas desarrollado en **GameMaker LTS 2026**. Su arquitectura está orientada a separar la lectura de hardware, el estado de juego, la física de actores, el combate y la presentación.

La ejecución se concentra en cuatro servicios colocados por room:

```text
obj_input ──> global.inp ──> obj_player / menú de pausa
obj_time_manager ──> global.do_step ──> actores, enemigos, proyectiles y mundo
obj_camera_controller <── player, BattleRooms y zoom triggers
obj_pause_menu ──> pausa e input de rebinding
```

- El frame de juego puede ser desacelerado mediante `global.time_scale`.
- Los sistemas que deben mantener respuesta visual o capturar un input puntual tienen una ruta de actualización de tiempo real.
- El combate usa objetos de daño/hitboxes independientes del actor que los creó.
- Las colisiones de nivel combinan un tilemap de colisión con sólidos dinámicos.

## 2. Estructura del proyecto

| Ruta | Responsabilidad |
| --- | --- |
| `objects/` | Objetos GameMaker: managers, actores, enemigos, mundo, UI y combate. |
| `scripts/` | Configuración central y helpers de input, física, dificultad, cámara y UI. |
| `rooms/` | Etapas, menú y salas de prueba/tutorial. |
| `sprites/` | Arte del jugador, enemigos, props, VFX, UI y tiles visuales. |
| `tilesets/` | Tilesets visuales y el tileset de colisión de 32 px. |
| `kick_g.yyp` | Manifiesto de recursos y orden de rooms. |

Los nombres de recursos siguen una convención por tipo: `obj_*`, `spr_*`, `ts_*` y `scr_*`.

## 3. Configuración central

El archivo [scripts/scr_config/scr_config.gml](scripts/scr_config/scr_config.gml) es la fuente de verdad para constantes de escala, cámara, geometría del jugador, combate, IA y equipos.

Valores relevantes actualmente configurados:

| Área | Configuración |
| --- | --- |
| Puerto de salida | `DISPLAY_W × DISPLAY_H = 1920 × 1080` |
| Macros de área lógica | `GAME_W × GAME_H = 960 × 540` |
| Cámara default | `1792 × 1008` en el mundo; close `1344 × 756`; far `2304 × 1296` |
| Arte visual | Tiles de 64 px; sprites del jugador en canvas de 256 px |
| Colisión activa | Capa `tiles_collision_32` mediante `COLLISION_LAYER` |
| Equipos | `TEAM_NEUTRAL`, `TEAM_PLAYER`, `TEAM_ENEMY` |
| Tipos de daño | `ATTACK_TYPE_MELEE`, `ATTACK_TYPE_PROJECTILE` |

La configuración también define los enums `CameraViewMode`, `BattleRoomState`, `BattleRoomCameraBoundsMode` y `BattleRoomArenaBoundsMode`. No se deben duplicar sus números en objetos consumidores.

### Geometría del jugador

La posición del jugador representa sus pies. Los sockets verticales se expresan como offsets desde ese origen (`PLAYER_CHEST_Y`, `PLAYER_SHOULDER_Y`, etc.). Espada, arco, indicador de apuntado y ataques hacia abajo deben usar estas macros, no offsets locales arbitrarios.

La hitbox física usa `col_left`, `col_right`, `col_top` y `col_bottom`, derivados de la máscara de sprite al crear el actor. Durante el roll, solo baja `col_top` a `PLAYER_SLIDE_COL_TOP`; los pies se mantienen alineados.

## 4. Ciclo de actualización y pausa

### `obj_time_manager`

Inicializa y administra:

- `global.time_scale`: escala de simulación; `1.0` es tiempo normal.
- `global.step_accum`: acumulador de frames simulados.
- `global.do_step`: indica si el frame ejecuta lógica gated.
- `global.slowmo_active`, `global.slowmo_timer` y escala temporal para efectos como parry.

Los scripts [scripts/scr_time_manager/scr_time_manager.gml](scripts/scr_time_manager/scr_time_manager.gml) exponen `time_set_slow`, `time_set_normal`, `trigger_slow_motion` y `trigger_parry_feedback`.

```text
Frame real
  ├─ input y timers de respuesta inmediata
  ├─ time manager calcula global.do_step
  └─ si global.do_step: física, IA, proyectiles, trampas y gameplay avanzan
```

`obj_player` divide explícitamente su Step entre una sección **always** y otra **gated**. Por ejemplo, buffer de ataque, carga/soltado del arco, ventana de parry y la selección de slow motion se capturan en tiempo real; movimiento y progreso principal de acciones respetan `global.do_step`.

`obj_pause_menu` pone el tiempo a cero, invalida el acumulador y guarda la escala anterior. Al cerrar el overlay, restaura el tiempo. No cambia de room.

### Regla para objetos nuevos

El Step de un actor, proyectil, enemigo, hazard o mecanismo debe iniciar con:

```gml
if (!global.do_step) exit;
```

Solo omitir esta puerta para lógica que deba correr a velocidad real —por ejemplo, interpolación de cámara, UI o captura fiable de un one-shot— y documentar el motivo.

## 5. Input y remapeo

`obj_input` es la única capa destinada a leer teclado y gamepad para gameplay. Su contrato público es `global.inp`.

| Script | Función |
| --- | --- |
| `scr_input_ensure_globals` | Inicializa `global.keybinds`, `global.inp` y valores de pausa sin sobrescribir remapeos. |
| `scr_input_read_keyboard` | Devuelve el estado del teclado en el frame. |
| `scr_input_read_gamepad` | Lee stick/D-pad, aplica deadzone y convierte cruces de eje en presses one-shot. |
| `scr_input_apply` | Fusiona teclado y gamepad con OR para botones y clamp para movimiento. |

Acciones disponibles: movimiento horizontal, salto, dash, ataque, arco, apuntado vertical, block/parry y pausa. Cada una distingue cuando corresponde entre `*_pressed`, `*_held` y `*_released`.

Bindings por defecto:

| Acción | Teclado | Gamepad |
| --- | --- | --- |
| Movimiento | Flechas izquierda/derecha | Stick izquierdo o D-pad |
| Salto | Espacio | `gp_face1` |
| Dash | Shift | `gp_face3` |
| Espada | Z | `gp_face2` |
| Arco | X | R1 (`gp_shoulderr`) |
| Block | C | L1 (`gp_shoulderl`) |
| Pausa | Escape | Start |

El menú de pausa permite cambiar bindings. Gameplay debe consumir `global.inp`; no debe introducir lecturas directas de `keyboard_check*` o `gamepad_*`.

## 6. Física y colisión

### `obj_actor_parent`

Es la base física reutilizable. Mantiene velocidades `move_x`/`move_y`, gravedad, máximo de caída, estado de suelo y contacto de pared. Su Step resuelve el desplazamiento contra la función `level_solid_at`.

```text
tile_solid_at(collision_map, x, y)
             │
             └─ level_solid_at(collision_map, x, y)
                    ├─ tilemap de COLLISION_LAYER
                    └─ obj_dynamic_solid_parent activos
```

[scripts/tile_solid_at/tile_solid_at.gml](scripts/tile_solid_at/tile_solid_at.gml) consulta el tilemap. [scripts/level_solid_at/level_solid_at.gml](scripts/level_solid_at/level_solid_at.gml) añade instancias dinámicas que implementan `dynamic_solid_contains_point`.

Esta segunda función es la API obligatoria para lógica de colisión de actores y mecanismos; consultar tiles directamente deja fuera puentes y futuras plataformas móviles.

### Sólidos dinámicos y puentes

`obj_dynamic_solid_parent` provee la interfaz de sólido habilitable. `obj_pivot_bridge` la usa para mantener colisión a lo largo de una tabla que rota desde un pivote. Sus parámetros de instancia incluyen lado, longitud, grosor, ángulos, velocidad, radio del target y debug.

El puente responde a flechas mediante targets interactivos; los proyectiles deben comprobar esos targets antes de destruirse al tocar una pared.

## 7. Jugador y máquina de estados

`obj_player` concentra las decisiones de gameplay del jugador y hereda la física de `obj_actor_parent`. La máquina de estados vive en [scripts/scr_player_fsm/scr_player_fsm.gml](scripts/scr_player_fsm/scr_player_fsm.gml).

| Grupo | Estados `PSTATE` |
| --- | --- |
| Movimiento | `IDLE`, `RUN`, `JUMP`, `FALL`, `WALL`, `DASH` |
| Espada | `ATTACK_1`, `ATTACK_2`, `ATTACK_3`, `DOWN_SLASH`, `DASH_ATTACK` |
| Defensa | `BLOCK`, `COUNTER_ATTACK` |

`player_set_state()` es el único punto de transición. Ejecuta hooks de salida y entrada: destruye hitboxes que correspondan, restaura límites de caída, reinicia buffers, restaura air dash al aterrizar y configura timers de ataque/parry. No se debe escribir `player_state` directamente fuera de esa función.

Capacidades implementadas o preparadas en `obj_player`:

- Movimiento, salto con coyote time y jump buffer.
- Contacto de pared, wall slide y wall jump.
- Dash en suelo/aire, dash jump y afterimages.
- Roll de perfil bajo, con chequeo para no expandir la colisión bajo un techo.
- Combo de espada, ataque en dash y ataque aéreo descendente con rebote.
- Arco con carga, apuntado aéreo y slow motion durante la carga en el aire.
- Block/parry, ventana de contraataque y respuesta de slow motion.
- Modo temporal beat'em up con golpes ligeros, heavy y uppercut.
- HUD de vida, carga de heavy, duración de beat'em up y overlays de debug.

Los buffers de comandos futuros se mantienen en [scripts/scr_combo_buffer/scr_combo_buffer.gml](scripts/scr_combo_buffer/scr_combo_buffer.gml). Registran ataques y direcciones relativas al `facing`, pero no deciden por sí mismos qué combo ejecutar.

## 8. Daño, combate y proyectiles

La arquitectura separa la entidad que se mueve de la fuente que aplica daño.

| Recurso | Rol |
| --- | --- |
| `obj_damage_source_parent` | Contrato común de fuente de daño: owner, equipo, tipo de ataque, daño, hit list, duración y parry. |
| `obj_sword_hitbox` | Hitbox de espada del jugador; usa sockets y ventana activa del estado. |
| `obj_enemy_sword_hitbox` | Hitbox de ataques melee enemigos. |
| `obj_projectile_parent` | Base para proyectiles con equipo, impacto, colisión, vida y depuración. |
| `obj_player_arrow` / `obj_enemy_arrow` | Proyectiles de jugador y arquero. |
| `obj_fly_bat_lightning_ball` | Proyectil específico del murciélago. |

La fuente de daño debe identificar claramente a su `owner`, `team` y `attack_type`. Las listas de objetivos golpeados se limpian al destruirse una hitbox para evitar dobles impactos durante la misma ventana activa.

`scr_enemy_get_attack_rect` centraliza la geometría de alcance de enemigos para lectura y debug. `scr_draw_healthbar` dibuja barras de vida compartidas.

## 9. Enemigos e IA

`obj_enemy_parent` concentra vida, daño recibido, knockback, invulnerabilidad/hitstun, físicas compartidas y visualización de debug. Los hijos actuales son:

- `obj_enemy_swordsman`: persecución, windup, ataque melee y cooldown.
- `obj_enemy_archer`: adquisición de objetivo, apuntado, disparo y cooldown.
- `obj_enemy_spider`: enemigo terrestre específico.
- `obj_enemy_golem`: enemigo de prueba/boss de comportamiento propio.
- `obj_test_fly_bat`: enemigo volador de prueba; puede lanzar `obj_fly_bat_lightning_ball`.

Los valores de daño, knockback, rangos y timings están en `scr_config`. La dificultad se calcula en [scripts/scr_difficulty_config/scr_difficulty_config.gml](scripts/scr_difficulty_config/scr_difficulty_config.gml), que expone `set_difficulty`, `apply_current_difficulty_config` y `apply_difficulty_to_existing_objects`. La configuración activa se publica como `global.current_config`.

## 10. Mundo, trampas y hazards

### Trampas

`obj_trap_parent` define el flujo reusable **trigger → reveal → payload → recovery**. Permite configurar por instancia el tipo y rectángulo de trigger, visual de cubierta rota, spawn de enemigos y/o hitbox de daño.

`obj_trap_wall_spawn` define defaults para una trampa montada en pared. Al crear hijos de trap, los defaults del hijo deben asignarse antes de `event_inherited()` para que una instancia pueda sobrescribirlos.

### Hazards

`obj_hazard_parent` implementa zonas rectangulares independientes de los tiles visuales: dimensiones, offset, activación, daño, muerte y debug. `obj_hazard_water_kill` es el preset para agua letal.

Los hazards se colocan en capas de instancias. Agua, lava o pinchos repetibles se representan visualmente con tiles; su gameplay no debe modificar tiles de colisión.

### BattleRooms

`obj_battleroom_parent` contiene el flujo de arena: espera, entrada, spawn, combate, limpieza, recompensa opcional y finalización. Usa `BattleRoomState` y puede bloquear input solo para el jugador, gestionar puertas/paredes, cambiar objetivo/bounds de cámara y contar enemigos.

Recursos asociados:

- `obj_battleroom_trigger` y `obj_battleroom_bridge_trigger`: activadores de arena.
- `obj_enemy_spawner` y `obj_battleroom_spawn_marker`: puntos y grupos de spawn.
- `obj_battleroom_gate` y `obj_battleroom_wall`: bloqueos físicos/visuales.
- `obj_battleroom_template` y `obj_battleroom_spawn_bridge_golem`: presets concretos.

## 11. Cámara

`obj_camera_controller` crea y asigna la cámara de `view_camera[0]`; interpola posición, tamaño, look-ahead, offset de aim, shake y límites de cámara en **End Step**. Esto permite que siga siendo fluida durante slow motion.

API pública de instancia:

```gml
camera_set_view_mode(CameraViewMode.FAR);
camera_set_target(_instance);
camera_restore_player_target();
camera_set_bounds_override(_left, _top, _right, _bottom);
camera_clear_bounds_override();
do_shake(_intensity, _duration);
```

Los objetos `obj_camera_zoom_trigger`, `obj_camera_zoom_trigger_close`, `obj_camera_zoom_trigger_normal` y `obj_camera_zoom_trigger_far` activan encuadres contextuales. Las BattleRooms pueden imponer temporalmente un target y bounds de arena.

## 12. Rooms y capas

El orden actual de rooms es:

1. `RoomStartMenu`
2. `RoomBigFloor`
3. `Room1`
4. `RoomTutorial`

| Room | Papel actual |
| --- | --- |
| `RoomStartMenu` | Menú principal y navegación a contenido. |
| `RoomBigFloor` | Etapa grande de prueba/producción, con props, trampas y enemigos. |
| `Room1` | Sala de combate y pruebas de enemigos. |
| `RoomTutorial` | Recorrido de sistemas: puentes, targets, hazards, BattleRoom y triggers de zoom. |

Todo room jugable debe tener una instancia de `obj_time_manager`, `obj_camera_controller`, `obj_input` y, cuando corresponda, `obj_player`. La capa nombrada por `COLLISION_LAYER` debe existir y contener un tilemap válido.

Convención de capas:

- Tile layers: suelo, paredes, alfombras, fondos y colisión repetible.
- Asset/sprite layers: props grandes `spr_prop_*`.
- Instance layers: actores, enemigos, triggers, traps, hazards, puentes y objetos de gameplay.

## 13. Depuración disponible

Hay overlays y toggles para cámara, colisiones, hitboxes, IA, proyectiles, ataques, BattleRooms, knockback, parry, dificultad y afterimages. Parte de ellos se controlan desde `obj_time_manager`, `obj_input`, la cámara y el propio jugador.

Son herramientas de desarrollo: no son un contrato de gameplay. Antes de una entrega, revisar especialmente los valores marcados como temporales de debug en `scr_config` y `obj_time_manager`.

## 14. Guía de extensión segura

### Agregar una acción al jugador

1. Añadir binding y campos `pressed`/`held`/`released` necesarios en `scr_input_ensure_globals`.
2. Implementar lectura de teclado y gamepad en scripts separados.
3. Fusionar ambos en `scr_input_apply`.
4. Consumir solo `global.inp` desde gameplay.
5. Capturar en la sección always si un frame skipped no puede perder el input; avanzar el gameplay en la sección gated.

### Agregar un enemigo

1. Crear un hijo de `obj_enemy_parent`.
2. Dejar al parent manejar vida, hitstun, knockback, muerte y debug compartido.
3. Mantener AI y ataques en scripts/eventos específicos del hijo.
4. Para daño, crear fuente hija de `obj_damage_source_parent` o proyectil hijo de `obj_projectile_parent`.
5. Definir rangos y timings reutilizables en `scr_config`.

### Agregar una trampa o hazard

1. Heredar de `obj_trap_parent` u `obj_hazard_parent`.
2. Exponer dimensiones, offsets, estado y payload como variables de instancia.
3. Colocarlo en una capa de instancias; no codificar dimensiones de una room en el objeto.
4. Registrar el recurso `.yy` en `kick_g.yyp`.

### Agregar un mecanismo sólido

1. Heredar de `obj_dynamic_solid_parent`.
2. Implementar la prueba espacial requerida por `dynamic_solid_contains_point`.
3. Conservar la colisión mientras cambie su visual/animación.
4. Verificar que todo actor use `level_solid_at`.

## 15. Puntos de atención técnicos

- La configuración documenta arte de 64 px, mientras la capa de colisión activa y algunos rooms usan una grilla de 32 px. Mantener ambos conceptos diferenciados y consultar `COLLISION_LAYER` en vez de asumir el tamaño visual.
- Hay rutas de debug y comentarios de trabajo dentro de objetos grandes, particularmente `obj_player` y `obj_battleroom_parent`. Cambios nuevos deben extraerse a helpers o recursos dedicados cuando mezclen responsabilidades.
- Algunos comentarios históricos de cámara mencionan dimensiones antiguas; los valores efectivos son los macros actuales de `scr_config`.
- La ausencia de input directo en gameplay es una regla de arquitectura. Las lecturas crudas existentes deben tratarse como deuda técnica, no como patrón para nuevas funciones.

## 16. Checklist manual al modificar el proyecto

- Confirmar que todo room jugable instancia input, tiempo y cámara.
- Confirmar que la capa `tiles_collision_32` existe en el room y coincide con `COLLISION_LAYER`.
- Verificar teclado y gamepad, incluyendo one-shot de sticks al cruzar deadzone.
- Probar acciones clave a tiempo normal, slow motion y pausa.
- Probar colisiones contra tiles y sólidos dinámicos.
- Verificar sockets y máscara de colisión al importar animaciones del jugador.
- Revisar que nuevos objetos y scripts estén registrados en `kick_g.yyp`.

