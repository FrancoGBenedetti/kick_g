# kick_g

Juego 2D de accion y plataformas hecho en GameMaker LTS 2026.

## Vision Del Juego

`kick_g` mezcla:

- Action platformer.
- Beat'em up cinematico.
- Combate tecnico.
- Movimiento avanzado.
- Boss fights cinematograficos.

Referencias principales:

- `Mega Man X4`
- `Have a Nice Death`
- `Cuphead`
- `Shovel Knight`
- `Street Fighter II`
- `Hollow Knight`

La direccion tecnica favorece PC, Nintendo Switch y gamepad desde temprano.

## Escala Y Arte

- Resolucion logica del gameplay: `640x360`.
- Room objetivo actual (`RoomBigFloor`): `12288x5120`.
- Viewport objetivo: `1920x1080`.
- Tiles: `64x64`, sin separacion, margen ni offset.
- Sprites del jugador: canvas `256x256`.
- Altura visual objetivo del jugador: aproximadamente `160px`.
- El personaje no debe llenar todo el canvas: usar alrededor de 65%-70% del alto.
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

## Sistemas De Gameplay

Movimiento esperado o existente:

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
- Roll con colision baja para pasar por espacios estrechos.

Combate esperado o existente:

- Espada con combo de 3 golpes.
- Arco con carga, aiming, disparo aereo y bullet time.
- Block/parry.
- Counter attack.
- Hitboxes independientes.
- Knockback, hit stop y VFX.

## Rooms

Un room representa una etapa o espacio con sus propias mecanicas.

- El menu principal tambien es un room.
- El mapa del juego debe ser otro room.
- `RoomBigFloor` es la etapa grande actual.
- Los recursos de room usan nombres tecnicos sin espacios (`RoomBigFloor`).
- El texto visible puede usar nombres de diseno (`Big floor`).

## Assets Y Props

Las props decorativas grandes no son tiles.

- Sofas, mesas, cuadros, chimeneas, gabinetes y decoracion grande van en Asset Layers/Sprite Layers.
- Tile Layers quedan reservadas para pisos, alfombras, paredes y tilesets modulares.
- En `RoomBigFloor`, la capa `Props` contiene decoracion grande.
- Las props grandes usan sprites `spr_prop_*`.
- Si una prop necesita cambiar de tamano en una etapa, se escala la instancia en el room.

## Trampas

Las trampas se piensan como sistemas reutilizables separados en:

- Trigger: cuando se activa.
- Reveal: que se ve al activarse.
- Payload: que hace.

Ejemplos:

- Trampa de pared que rompe una cubierta y spawnea enemigo.
- Trampa de techo que deja caer algo.
- Trampa de suelo que emerge desde abajo.
- Trampa que solo genera hitbox/dano.

## Hazards

Los hazards separan visual y gameplay.

- Agua/lava/pinchos repetibles pueden pintarse como Tile Layers visuales.
- La zona que mata o dana es un objeto en `Instances`.
- Esto permite ajustar tamano y comportamiento por instancia sin cambiar tiles.

## Solidos Dinamicos Y Puentes

El proyecto soporta solidos dinamicos para plataformas y mecanismos.

Ejemplo actual:

- `obj_pivot_bridge`: puente levadizo activado por flecha.
- La flecha golpea un target.
- El puente pivotea hasta quedar como plataforma.
- Puede invertirse con `bridge_side = -1`.

## Camara

La camara debe mostrar suficiente escenario para leer combate y plataformas.

Objetivos:

- Soporte de zoom dinamico.
- Shake.
- Transiciones cinematicas.
- Encuadres para bosses y ataques especiales.

## Estado Del Proyecto

Este README describe la vision y convenciones de diseno del proyecto.
Las reglas operativas para agentes de codigo estan en `AGENTS.md`.
