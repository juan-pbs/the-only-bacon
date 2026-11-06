# Tocino: tiras horizontales para Godot 4

Cada PNG de `tiras/` contiene **una sola animación en una fila**. Los cuadros van de izquierda a derecha sobre fondo transparente. Los nombres siguen `accion_direccion.png`, con `down` (frente), `up` (espalda), `left` y `right`. `victory`, `defeat` y `can_spin` no dependen de la dirección.

Los cuadros de Tocino miden **320 × 320 px**. Cada tira tiene 2 o 4 cuadros, por lo que mide 640 × 320 o 1280 × 320 px. La lata que gira usa cuadros de **160 × 160 px**. `manifest.json` registra la cantidad de cuadros, los FPS sugeridos y si la secuencia se repite.

| Acción | Cuadros por dirección | FPS | Repetir |
| --- | ---: | ---: | --- |
| Reposo `idle` | 2 | 3 | Sí |
| Caminar `walk` | 4 | 8 | Sí |
| Correr `run` | 4 | 12 | Sí |
| Saltar `jump` | 4 | 10 | No |
| Esquivar `dodge` | 4 | 14 | No |
| Recoger lata `pickup` | 4 | 10 | No |
| Lanzar lata `throw` | 4 | 12 | No |
| Daño `hurt` | 4 | 10 | No |
| Esconderse `hide` | 4 | 9 | No |
| Reposo con lata `hold_idle` | 2 | 3 | Sí |
| Caminar con lata `hold_walk` | 4 | 8 | Sí |
| Correr con lata `hold_run` | 4 | 12 | Sí |
| Victoria `victory` / derrota `defeat` | 4 cada una | 8 | No |
| Lata en vuelo `can_spin` | 4 | 12 | Sí |

`hold_run` comparte los dibujos de `hold_walk` a mayor velocidad. Todas las demás acciones tienen movimiento entre cuadros; el reposo también tiene una leve respiración. Para diagonales se elige la orientación del eje dominante y, al detenerse, se conserva la última orientación.

## Secuencia de la lata

1. Reproducir `pickup_<direccion>` cuando Tocino recoge la lata. Al terminar los 4 cuadros, marcarla como cargada y pasar a `hold_idle`, `hold_walk` o `hold_run` según su velocidad.
2. Reproducir `throw_<direccion>` al lanzar. En el **tercer cuadro** (índice 2), crear el proyectil con `can_spin` y quitar la lata del inventario.
3. Al terminar el cuarto cuadro, volver a `idle`, `walk` o `run`.

## Importación

En `Sprite2D`, asignar la textura de la tira, `hframes = 2` o `4`, `vframes = 1`, y animar la propiedad `frame` de `0` a `hframes - 1`. También se puede crear una animación en `SpriteFrames`/`AnimatedSprite2D` desde cada tira. Mantener el origen centrado y ajustar la escala de visualización en Godot; los PNG tienen resolución alta para permitir reducirlos sin perder detalle.

Los atlas de origen generados están en `atlases/`. `exportar_tiras.py` separa sus cuadros y normaliza el lienzo; se puede ejecutar otra vez con Python y Pillow. Este paquete es la primera pasada visual del personaje para prototipado y puede requerir retoque cuadro por cuadro antes del arte final.
