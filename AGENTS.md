# AGENTS.md

Lineamientos para trabajar en este proyecto GameMaker (`kick_g`).

## Reglas Del Usuario

- No ejecutar tests. Si hace falta probar algo, pedir al usuario que lo haga y esperar el resultado.
- No hacer comandos de git: no branch, no status, no add, no commit, no push.
- No hacer migraciones ni tareas equivalentes sin pedirlo.
- Mantener archivos chicos y legibles. Preferir componentes, scripts dedicados y responsabilidades separadas.
- No reescribir sistemas completos si el cambio puede hacerse de forma localizada.

## Vision Del Juego

Juego 2D de accion y plataformas con mezcla de:

- Action platformer.
- Beat'em up cinematico.
- Combate tecnico.
- Movimiento avanzado.
- Boss fights cinematograficos.

Referencias principales: `Mega Man X4`, `Have a Nice Death`, `Cuphead`, `Shovel Knight`, `Street Fighter II`, `Hollow Knight`.

La direccion tecnica debe favorecer PC, Nintendo Switch y gamepad desde temprano.

## Escala Y Arte

- Resolucion logica del gameplay: `640x360`.
- Room objetivo actual (`RoomBigFloor`): `12288x5120`.
- Viewport objetivo: `1920x1080`.
- Tiles: `64x64`, sin separacion, margen ni offset.
- Sprites del jugador: canvas `256x256`.
- Altura visual objetivo del jugador: aproximadamente `160px`.
- El personaje no debe llenar todo el canvas: usar alrededor de 65%-70% del alto.
- Mantener origen, pies y alineacion consistentes entre animaciones.
- Texture interpolation/interpolate colors debe mantenerse apagado para evitar blur.

## Colisiones

- La colision no representa el arte completo.
- La mascara representa peso, piernas y contacto con suelo.
- Para sprites `256x256`, la mascara base recomendada es:
  - `left: 108`
  - `right: 148`
  - `top: 170`
  - `bottom: 255`
- Es aceptable que visualmente los pies entren levemente en el piso; la colision real debe seguir precisa.
- No ajustar hitboxes solo para que calcen con el dibujo completo si eso empeora el gameplay.

## Arquitectura GameMaker

- `obj_actor_parent`: fisica, gravedad, colisiones y movimiento base.
- `obj_player`: gameplay del jugador, combate, habilidades, estados y animacion visual.
- `obj_input`: unica capa que toca hardware de teclado/gamepad.
- `obj_camera_controller`: seguimiento, zoom, shake y transiciones cinematicas.
- `obj_time_manager`: `global.time_scale`, slow motion y gating de steps.

## Rooms

- Un room representa una etapa o espacio con sus propias mecanicas.
- El menu principal tambien es un room.
- El mapa del juego debe ser otro room.
- Los recursos de room deben usar nombres tecnicos sin espacios (`RoomBigFloor`); el texto visible puede usar nombres de diseno (`Big floor`).
- No usar cambio de room para una pausa in-game si se necesita conservar el estado exacto de la etapa; usar overlay/manager dentro del room activo.
- Cambiar de room para menus principales, mapas, hubs o transiciones reales esta bien.
- Las props decorativas grandes (`sofas`, mesas, cuadros, chimeneas, gabinetes, etc.) deben ir en Asset Layers/Sprite Layers, no en Tile Layers.
- Mantener Tile Layers solo para tiles repetibles: pisos, alfombras, paredes y tilesets modulares.
- En `RoomBigFloor`, la capa `Props` es la capa para props grandes; debe quedar sobre piso/alfombra y bajo foreground/instancias.
- No crear TileSets para sprites decorativos individuales grandes, aunque vengan desde `Downloads`.
- Importar props grandes como sprites con nombre `spr_prop_*` y parent virtual `folders/Sprites/Tiles/Props.yy`.
- Colocar props en el room arrastrando el sprite a la capa `Props`; no pintarlas con tiles.
- Si una prop necesita cambiar de tamano en una etapa, escalar la instancia/asset dentro del room, no cambiar el tamano del sprite base.
- Si existe una prop como TileSet gigante de una sola pieza, reemplazar ese flujo por el sprite original en la capa `Props`.

Mantener la separacion:

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
- Preparar el codigo para remap futuro, pero no crear menu de configuracion hasta que el layout base este estable.

## Movimiento

Sistemas ya existentes o esperados:

- Movimiento horizontal.
- Salto.
- Gravedad.
- Tile collision.
- Coyote time.
- Jump buffer.
- Facing.
- State machine.
- Wall contact.
- Wall slide.
- Wall jump.
- Dash.
- Dash jump.
- Air dash.

Cuando se edite movimiento:

- Respetar buffers y timers existentes.
- Separar logica always-frame de logica gated por `global.do_step`.
- No romper slow motion: acciones one-shot importantes deben capturarse aunque el gameplay este en slow-mo.

## Combate

Sistemas principales:

- Espada con combo de 3 golpes.
- Arco con carga, aiming, disparo aereo y bullet time.
- Block/parry.
- Counter attack.
- Hitboxes independientes.
- Knockback, hit stop y VFX.

Reglas:

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
- Las variables por instancia deben poder cambiarse desde Creation Code del room:
  - `trigger_mode`, `trigger_range`, `trigger_xoff`, `trigger_yoff`, `trigger_w`, `trigger_h`.
  - `cover_sprite`, `broken_sprite`, `broken_xoff`, `broken_yoff`, `trap_visual_xscale`, `trap_visual_yscale`, `break_sound`.
  - `payload_spawn_enemy`, `enemy_object`, `enemy_spawn_xoff`, `enemy_spawn_yoff`, `enemy_spawn_layer`.
  - `payload_damage`, `damage`, `hitbox_xoff`, `hitbox_yoff`, `hitbox_w`, `hitbox_h`.
- Si un hijo necesita defaults propios, setearlos antes de `event_inherited()` para que `obj_trap_parent` respete overrides por instancia.
- Las trampas se colocan en capas `Instances`, no en `Props` ni en Tile Layers.
- Sprites visuales de trampas usan nombre `spr_trap_*`; no crear TileSets para cubiertas o paneles rompibles.
- Si una cubierta de trampa queda grande/chica, ajustar `trap_visual_xscale`/`trap_visual_yscale` o la escala de la instancia; no convertirla en TileSet.

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
- Cuando el visual este listo, apagar `hazard_debug_draw` y dejar el Tile Layer visual como feedback para el jugador.

## Camara

- La camara debe mostrar suficiente escenario para leer combate y plataformas.
- Mantener soporte de zoom dinamico para bosses, cinematicas, ataques especiales y transiciones.
- Evitar camara demasiado cercana como default.
- No acoplar gameplay a valores magicos de viewport; usar configuracion central cuando exista.

## Estados Y Animacion

Estados actuales base:

- `IDLE`
- `RUN`
- `JUMP`
- `FALL`
- `WALL`
- `DASH`
- Ataques, block, dash attack, counter y down slash segun `PSTATE`.

Reglas:

- Gameplay state y visual animation state pueden estar separados.
- No reiniciar animacion cada frame si el sprite no cambio.
- Al agregar animaciones nuevas, mantener mismo origin y punto de pies.
- Priorizar legibilidad de transiciones sobre switches gigantes sin helpers.

## Estilo De Codigo

- Preferir scripts chicos con una responsabilidad clara.
- Evitar archivos largos; si un evento crece demasiado, extraer helpers.
- Usar nombres descriptivos en ingles o espanol consistente con el archivo existente.
- Comentarios cortos solo cuando expliquen decisiones de gameplay o timing.
- No introducir refactors grandes junto con fixes pequenos.
- Mantener cambios acotados al sistema solicitado.

## Antes De Entregar Cambios

- Revisar estaticamente archivos tocados.
- Confirmar que no se corrio test, git ni migracion.
- Indicar al usuario exactamente que debe probar en GameMaker cuando aplique.
- Si se agregan recursos GameMaker nuevos (`scripts`, `objects`, `sprites`), registrar sus `.yy` en `kick_g.yyp` cuando corresponda.
