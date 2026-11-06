# Sprites 2D de The Only Bacon

Estos PNG son la primera entrega visual para el proyecto Godot 4.7. Los tres personajes y los objetos tienen canal alfa; el atlas de pisos es opaco.

## Personajes

- `tocino-direcciones.png`, `tlacua-direcciones.png`, `cuache-direcciones.png`: atlas de 1774 x 887 px, 4 columnas y 2 filas.
- Columnas, de izquierda a derecha: abajo, izquierda, derecha, arriba.
- Fila superior: quieto. Fila inferior: pose de carrera.
- Los dibujos no están distribuidos en celdas exactamente iguales. Para evitar recortes, usar estas divisiones aproximadas de atlas (coordenadas en píxeles):

| Archivo | Límites X | Límites Y |
| --- | --- | --- |
| `tocino-direcciones.png` | 0, 474, 887, 1306, 1774 | 0, 449, 887 |
| `tlacua-direcciones.png` | 0, 458, 886, 1317, 1774 | 0, 448, 887 |
| `cuache-direcciones.png` | 0, 428, 890, 1351, 1774 | 0, 450, 887 |

- En Godot, usar regiones individuales del atlas en `SpriteFrames` de un `AnimatedSprite2D`. Cada dirección tiene una pose quieta y una pose de carrera; todavía no es un ciclo de caminata completo.

## Escenario

- `objetos-escenario.png`: atlas transparente de 1774 x 887 px. Divisiones aproximadas X = 0, 446, 882, 1305, 1774; Y = 0, 477, 887.
- Fila superior: caja, pila de huevos, charco de aceite, fogata con olla.
- Fila inferior: estufa, mesa, salida, cerca de madera.
- `pisos-niveles.png`: atlas opaco de 1254 x 1254 px, dividido en cuatro cuadrantes de 627 x 627 px: tierra de La Fogata, piedra oscura del Bodegón, loseta cálida de la Cocina, loseta oscura de escondite.
- En Godot, usar `TileMapLayer` y `TileSet` para los suelos y obstáculos. Los mapas de composición están en `assets/bocetos/niveles-2d-godot-v2.png`.

Los dibujos son una primera pasada de arte. Antes de cerrar un tileset definitivo hay que revisar las uniones de los pisos, las colisiones y la escala dentro de una escena de prueba.

## Sprites de acciones

Las cuatro láminas nuevas están en `assets/sprites/acciones/`. Son PNG con transparencia. Se leen de izquierda a derecha y de arriba abajo; cada acción tiene una pose estática. Los cuadros intermedios para animación continua aún no están dibujados.

| Archivo | Cuadrícula visual | Orden de acciones |
| --- | --- | --- |
| `tocino-acciones.png` | 5 x 2 | espera, caminar, correr, salto, esquiva; esconderse, recoger, lanzar, daño/aceite, escapar |
| `tlacua-acciones.png` | 3 x 3 | espera, patrullar, perseguir; preparar sartén, golpe de sartén, lanzar aceite; buscar, recibir impacto, aturdido |
| `cuache-acciones.png` | 3 x 3 | espera, caminar, perseguir; bloquear, girar/cerrar ruta, buscar; tropezar, recibir impacto, aturdido |
| `tocino-especiales.png` | 3 x 1 | mantequilla/vida, reloj/tiempo, derrota |

Las poses ocupan tamaños variables dentro de las láminas. Al asignarlas en Godot, usar regiones individuales del atlas y comprobar cada recorte; no aplicar una división uniforme automática a estas cuatro láminas.
