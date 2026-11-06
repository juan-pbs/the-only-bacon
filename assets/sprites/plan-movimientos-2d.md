# Plan de movimientos 2D

> **Actualización del tocino:** las tiras finales están en `assets/sprites/tocino_animado/tiras/` con su `manifest.json`. Cada archivo es una sola fila horizontal de 2 o 4 cuadros. Para el tocino se dibujó una carrera propia y se añadieron secuencias de recoger, sostener y lanzar la lata en las cuatro orientaciones. Las cantidades de este documento son el plan inicial de bocetos, no el inventario actual; el inventario vigente está en el manifiesto.

## Perspectiva y direcciones

La cámara queda fija en vista cenital ligeramente inclinada, como el mockup del GDD. El control permite movimiento en ocho direcciones, pero la animación muestra cuatro orientaciones. Esto mantiene un movimiento simple y legible parecido a la referencia que el usuario describió como *Among Us*.

| Dirección de pantalla | Nombre en archivos | Aspecto |
| --- | --- | --- |
| Abajo | `down` | Frente del personaje, hacia la cámara |
| Arriba | `up` | Espalda del personaje, alejándose de la cámara |
| Izquierda | `left` | Perfil izquierdo |
| Derecha | `right` | Perfil derecho |

En diagonal se usa la orientación del eje dominante. Al detenerse, se conserva la última orientación. No hacen falta sprites diagonales para la primera versión.

## Bocetos del ciclo de caminar

Los bocetos están en `assets/bocetos/movimiento/`: `tocino-caminar-4-direcciones.png`, `tlacua-caminar-4-direcciones.png` y `cuache-caminar-4-direcciones.png`. Cada lámina se lee por filas: frente, espalda, izquierda y derecha. Cada fila tiene cuatro cuadros consecutivos: apoyo izquierdo, paso intermedio, apoyo derecho y segundo paso intermedio. Después vuelve al cuadro 1.

Hay una segunda lámina por personaje en la misma carpeta. `tocino-acciones-por-frames.png` muestra salto (4), esquiva (3), lanzamiento (4) y recolección (3), una acción por fila. `tlacua-acciones-por-frames.png` muestra el ataque de sartén (5) y el lanzamiento de aceite (4). `cuache-acciones-por-frames.png` muestra bloqueo (3), tropiezo (3) y búsqueda (2). Las casillas restantes de las filas cortas están vacías deliberadamente.

## Base compartida por los tres personajes

| Estado | Direcciones | Cuadros visibles por dirección | Dibujos nuevos por personaje | Uso propuesto |
| --- | --- | --- | --- | --- |
| `idle` | 4 | 1 | 4 | Reposo conservando la última dirección. La respiración puede hacerse con una pequeña escala o desplazamiento en Godot. |
| `walk` | 4 | 4 | 16 | Ciclo 1-2-3-4 a unas 8 imágenes por segundo. |
| `run` | 4 | 4 | 0 adicionales | Reutilizar el ciclo de caminar a unas 12 imágenes por segundo y mayor velocidad física. Si se necesita una silueta distinta, dibujar cuatro cuadros nuevos por dirección después. |

**Primera versión: 20 dibujos distintos por personaje para reposo y caminar en cuatro direcciones.** El ciclo de carrera reutiliza los 16 cuadros de caminata. La velocidad de animación es una propuesta inicial que debe ajustarse al probar el juego.

Para mantener el estilo de movimiento simple, el cuerpo sube y baja pocos píxeles al caminar. Los pies vuelven al mismo punto de apoyo al cerrar el ciclo. La sombra permanece en el suelo.

## Acciones propias

| Personaje | Acciones que requieren dirección | Acciones que pueden empezar con una sola vista |
| --- | --- | --- |
| Tocino | `jump`, `dodge`, `throw` en 4 direcciones | `hide`, `pickup`, `heal`, `time_bonus`, `victory`, `defeat` |
| Tlacua | `pan_windup`, `pan_swing`, `oil_throw` en 4 direcciones | `search`, `hurt`, `stunned` |
| Cuache | `block` en 4 direcciones | `search`, `trip`, `hurt`, `stunned` |

El salto del tocino se representa como un brinco corto con separación entre pies y sombra. La colisión del obstáculo se resuelve en la lógica del juego. Cuache puede cerrar una ruta con `block`; el giro para llegar al pasillo usa su animación normal de movimiento y cambia su orientación.

### Cuadros sugeridos para acciones especiales

| Personaje | Acción | Cuadros por orientación | Secuencia de poses |
| --- | --- | --- | --- |
| Tocino | `jump` | 4 | Impulso, subida, punto alto, aterrizaje |
| Tocino | `dodge` | 3 | Preparación, desplazamiento, recuperación |
| Tocino | `pickup` | 3 | Agacharse, tomar objeto, levantarse |
| Tocino | `throw` | 4 | Preparar, llevar brazo atrás, soltar, recuperar |
| Tocino | `hide` | 2 | Entrar en escondite, permanecer oculto |
| Tocino | `hurt`/resbalar | 3 | Impacto, pérdida de equilibrio, recuperación |
| Tocino | `victory`/`defeat` | 3 cada una | Inicio, pose principal, final |
| Tlacua | `pan_windup` + `pan_swing` | 5 | Preparar, alzar, golpe, barrido, recuperar |
| Tlacua | `oil_throw` | 4 | Preparar, llevar brazo atrás, lanzar, recuperar |
| Tlacua | `search`/`hurt`/`stunned` | 2/2/3 | Reacciones breves |
| Cuache | `block` | 3 | Abrir brazos, bloquear, bajar brazos |
| Cuache | `search`/`trip`/`hurt`/`stunned` | 2/3/2/3 | Reacciones breves |

`jump`, `dodge`, `throw`, `pan_swing`, `oil_throw` y `block` deben prepararse en cuatro orientaciones porque afectan la dirección del movimiento o del ataque. `pickup`, `hide`, daño y otras reacciones pueden empezar con una vista reutilizable. Mantequilla y reloj usan `pickup` con efectos visuales distintos, sin cuadros nuevos del cuerpo.

Con esas decisiones, el paquete completo estimado tendría **78 dibujos distintos para el tocino, 63 para Tlacua y 42 para Cuache**. Es una estimación de producción: incluye los 20 dibujos base por personaje, repite en cuatro direcciones solo las acciones dirigidas y no cuenta cuadros nuevos para `run`, mantequilla ni reloj. Los seis bocetos de movimiento muestran la secuencia y la cuenta de cuadros, pero no sustituyen esos dibujos finales.

## Orden de producción

1. Crear `idle` y los cuatro cuadros de `walk` en cuatro direcciones para los tres personajes.
2. Probar `run` reutilizando `walk` a mayor velocidad.
3. Crear las acciones dirigidas: salto, esquiva y lanzamiento del tocino; sartén y aceite de Tlacua; bloqueo de Cuache.
4. Crear las reacciones y estados especiales.

Cada cuadro final debe tener un lienzo transparente de tamaño fijo por personaje, el mismo punto de apoyo en los pies y una escala constante. Nombres sugeridos: `tocino/walk_down_00.png`, `tocino/walk_down_01.png`, etc. Los atlas actuales contienen poses de referencia y tienen espacios variables; todavía no son ciclos de animación con cuadros uniformes.
