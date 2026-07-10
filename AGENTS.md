# AGENTS.md

Guia operativa para agentes que desarrollen en este proyecto GameMaker (`kick_g`).
Para contexto de diseno, vision del juego y sistemas esperados, leer `README.md`.

## Reglas Del Usuario

- No ejecutar tests. Si hace falta probar algo, pedir al usuario que lo haga y esperar el resultado.
- No hacer comandos de git: no branch, no status, no add, no commit, no push.
- No hacer migraciones ni tareas equivalentes sin pedirlo.
- Mantener archivos chicos y legibles. Preferir componentes, scripts dedicados y responsabilidades separadas.
- No reescribir sistemas completos si el cambio puede hacerse de forma localizada.

## Forma De Trabajo

- Leer el codigo existente antes de asumir arquitectura.
- Mantener cambios acotados al sistema solicitado.
- Preferir patrones existentes del proyecto antes de crear una abstraccion nueva.
- Extraer helpers cuando un evento u objeto empieza a mezclar demasiadas responsabilidades.
- Usar comentarios cortos solo para decisiones de gameplay, timing o integracion no obvias.
- Si se agregan recursos GameMaker nuevos (`scripts`, `objects`, `sprites`, `rooms`, `tilesets`), registrar sus `.yy` en `kick_g.yyp` cuando corresponda.
- Revisar estaticamente los archivos tocados antes de entregar.

## Arquitectura GameMaker

- `obj_actor_parent`: fisica, gravedad, colisiones y movimiento base.
- `obj_player`: gameplay del jugador, combate, habilidades, estados y animacion visual.
- `obj_input`: unica capa que toca hardware de teclado/gamepad.
- `obj_camera_controller`: seguimiento, zoom, shake y transiciones cinematicas.
- `obj_time_manager`: `global.time_scale`, slow motion y gating de steps.

Mantener separacion:

- Hardware input -> `obj_input` / scripts de input.
- Estado normalizado -> `global.inp`.
- Gameplay -> lee `global.inp`; no debe llamar directamente `keyboard_check` o `gamepad_*`.

## Input

- Todo input de gameplay debe pasar por `global.inp`.
- Teclado y controller deben convivir: si cualquiera activa una accion, la accion cuenta.
- Mantener acciones one-shot separadas de held:
  - `*_pressed`: solo el frame de activacion.
  - `*_held`: mientras se mantiene.
  - `*_released`: solo el frame de soltar.
- Para analog sticks, usar deadzone y detectar cruce de eje para one-shot direccional.

## Rooms Y Assets

- Un room representa una etapa o espacio con sus propias mecanicas.
- El menu principal tambien es un room.
- Los recursos de room deben usar nombres tecnicos sin espacios (`RoomBigFloor`); el texto visible puede usar nombres de diseno (`Big floor`).
- No usar cambio de room para pausa in-game si se necesita conservar el estado exacto de la etapa; usar overlay/manager dentro del room activo.
- Cambiar de room para menus principales, mapas, hubs o transiciones reales esta bien.

Props:

- Props decorativas grandes (`sofas`, mesas, cuadros, chimeneas, gabinetes, etc.) van en Asset Layers/Sprite Layers, no en Tile Layers.
- Mantener Tile Layers solo para tiles repetibles: pisos, alfombras, paredes y tilesets modulares.
- En `RoomBigFloor`, la capa `Props` queda sobre piso/alfombra y bajo foreground/instancias.
- No crear TileSets para sprites decorativos individuales grandes, aunque vengan desde `Downloads`.
- Importar props grandes como sprites `spr_prop_*` con parent virtual `folders/Sprites/Tiles/Props.yy`.
- Colocar props en el room arrastrando el sprite a la capa `Props`; no pintarlas con tiles.
- Si una prop necesita cambiar de tamano en una etapa, escalar la instancia/asset dentro del room, no cambiar el tamano del sprite base.
- Si existe una prop como TileSet gigante de una sola pieza, reemplazar ese flujo por el sprite original en la capa `Props`.

## Escala, Arte Y Colisiones

- Resolucion logica del gameplay: `640x360`.
- Viewport objetivo: `1920x1080`.
- Tiles: `64x64`, sin separacion, margen ni offset.
- Sprites del jugador: canvas `256x256`.
- Altura visual objetivo del jugador: aproximadamente `160px`.
- Mantener origen, pies y alineacion consistentes entre animaciones.
- Texture interpolation/interpolate colors debe mantenerse apagado para evitar blur.

Colisiones:

- La colision no representa el arte completo.
- La mascara representa peso, piernas y contacto con suelo.
- Para sprites `256x256`, la mascara base recomendada es:
  - `left: 108`
  - `right: 148`
  - `top: 170`
  - `bottom: 255`
- Es aceptable que visualmente los pies entren levemente en el piso; la colision real debe seguir precisa.
- No ajustar hitboxes solo para que calcen con el dibujo completo si eso empeora el gameplay.

## Movimiento

- Respetar buffers y timers existentes.
- Separar logica always-frame de logica gated por `global.do_step`.
- No romper slow motion: acciones one-shot importantes deben capturarse aunque el gameplay este en slow-mo.
- El roll debe reducir solo `col_top`, manteniendo `col_bottom` en los pies.
- Si el roll termina bajo techo, la colision baja debe mantenerse hasta que haya espacio para restaurar la altura normal.

## Combate

- No spawnear ataques desde los pies/origin si representan manos, torso o arma.
- Usar sockets/offsets relativos para espada, arco, flechas y VFX.
- Mantener bloqueo mutuo claro entre espada, arco, dash y block cuando aplique.
- Hitboxes deben tener owner/team/damage source claro.
- Preferir scripts/helpers dedicados para rectangulos, sockets, spawn points y calculos repetidos.

## Trampas

- Las trampas deben partir desde `obj_trap_parent`, no desde objetos sueltos con logica duplicada.
- Separar siempre tres conceptos:
  - Trigger: cuando se activa (`distancia`, rectangulo, contacto o evento externo).
  - Reveal: que se ve al activarse (cubierta intacta, rota, caida, salida desde suelo/techo/pared).
  - Payload: que hace (spawnear enemigo, aplicar dano, empujar, VFX/sonido, o combinaciones).
- `obj_trap_parent` contiene estados, delay, cooldown/recovery, one-shot/reusable, trigger comun y payload comun.
- Los hijos definen el tipo espacial y defaults visuales:
  - `obj_trap_wall_spawn`: enemigo o golpe que sale desde pared.
  - Futuro `obj_trap_ceiling_drop`: algo cae desde arriba.
  - Futuro `obj_trap_floor_burst`: algo sale desde abajo.
  - Futuro `obj_trap_hitbox_only`: no spawnea enemigo, solo golpea/da feedback.
- Variables por instancia esperadas:
  - `trigger_mode`, `trigger_range`, `trigger_xoff`, `trigger_yoff`, `trigger_w`, `trigger_h`.
  - `cover_sprite`, `broken_sprite`, `broken_xoff`, `broken_yoff`, `trap_visual_xscale`, `trap_visual_yscale`, `break_sound`.
  - `payload_spawn_enemy`, `enemy_object`, `enemy_spawn_xoff`, `enemy_spawn_yoff`, `enemy_spawn_layer`.
  - `payload_damage`, `damage`, `hitbox_xoff`, `hitbox_yoff`, `hitbox_w`, `hitbox_h`.
- Si un hijo necesita defaults propios, setearlos antes de `event_inherited()` para que `obj_trap_parent` respete overrides por instancia.
- Las trampas se colocan en capas `Instances`, no en `Props` ni en Tile Layers.
- Sprites visuales de trampas usan nombre `spr_trap_*`; no crear TileSets para cubiertas o paneles rompibles.

## Hazards

- Separar visual y gameplay: agua/lava/pinchos repetibles se pintan como Tile Layers visuales; la zona que mata o dana va como objeto en `Instances`.
- `obj_hazard_parent` contiene la logica reusable de zonas peligrosas.
- Usar hijos/presets como `obj_hazard_water_kill` para defaults de agua letal.
- Los hazards no deben modificar Tile Layers de colision; son zonas rectangulares independientes configurables por instancia.
- Variables por instancia esperadas:
  - `hazard_w`, `hazard_h`, `hazard_xoff`, `hazard_yoff`.
  - `hazard_kill_player`, `hazard_damage`, `hazard_enabled`.
  - `hazard_debug_draw`, `hazard_debug_color`.
- Para ajustar una zona en un room, usar Creation Code de la instancia; no hardcodear medidas de un room dentro del objeto.

## Solidos Dinamicos Y Puentes

- La colision base de actores debe consultar `level_solid_at`, no `tile_solid_at` directamente, para combinar Tile Layers solidos con objetos dinamicos.
- `obj_dynamic_solid_parent` es la base para plataformas/puentes que activan colision rectangular en runtime.
- Usar `obj_pivot_bridge` para puentes levadizos activados por flecha.
- En `obj_pivot_bridge`, `x/y` es el pivote anclado al escenario.
- El puente debe colisionar durante todos sus estados; cerrado usa colision tipo capsula/segmento sobre toda la tabla, abierto queda como plataforma horizontal.
- Cuando una flecha del jugador golpea el target, el puente rota hacia `bridge_open_angle`; la colision sigue la tabla durante la rotacion.
- Los proyectiles deben revisar targets interactivos antes de destruirse contra tiles, para que una flecha pueda activar un target pegado a pared.
- Variables por instancia esperadas:
  - `bridge_sprite`, `bridge_side`, `bridge_length`, `bridge_thickness`.
  - `bridge_visual_yscale`, `bridge_visual_yoff`.
  - `bridge_closed_angle`, `bridge_open_angle`, `bridge_rotate_speed`.
  - `target_radius`, `bridge_collision_padding`, `bridge_debug_draw`.
- `bridge_side = 1` abre hacia la derecha; `bridge_side = -1` invierte el puente para abrir hacia la izquierda.
- `bridge_length` es el largo jugable y visual; el sprite se escala proporcionalmente a ese largo para mantener dibujo y colision sincronizados.
- No editar el tamano del PNG base para ajustar una instancia de puente; usar `bridge_length`, `bridge_visual_yscale`, `bridge_thickness` y `bridge_collision_padding`.
- Los actores prueban izquierda/centro/derecha en colision horizontal para detectar solidos dinamicos finos o inclinados.

## Camara

- La camara debe mostrar suficiente escenario para leer combate y plataformas.
- Mantener soporte de zoom dinamico para bosses, cinematicas, ataques especiales y transiciones.
- Evitar camara demasiado cercana como default.
- No acoplar gameplay a valores magicos de viewport; usar configuracion central cuando exista.

## Estados Y Animacion

- Gameplay state y visual animation state pueden estar separados.
- No reiniciar animacion cada frame si el sprite no cambio.
- Al agregar animaciones nuevas, mantener mismo origin y punto de pies.
- Priorizar legibilidad de transiciones sobre switches gigantes sin helpers.

## Antes De Entregar Cambios

- Revisar estaticamente archivos tocados.
- Confirmar que no se corrio test, git ni migracion.
- Indicar al usuario exactamente que debe probar en GameMaker cuando aplique.
