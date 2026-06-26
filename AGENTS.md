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
