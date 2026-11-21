# The Only Bacon

Juego de acción y escape en Godot 4.7. Tocino debe cruzar La Fogata, el Bodegón de Huevos y la Cocina del Desayuno antes de perder la vida o agotar el tiempo.

## Controles

| Acción | Tecla |
| --- | --- |
| Moverse | WASD o flechas |
| Correr | Shift |
| Lanzar objeto recogido | Espacio o J |
| Cambiar entre lata y cacerola | Q |
| Saltar cajas de huevos y evitar aceite | K |
| Esquivar ataques | L |
| Ocultarse en una zona oscura | Mantener H |
| Pausa | Esc |

Las latas y cacerolas se consumen al lanzarse. La mantequilla restaura hasta 25 puntos de vida y el reloj agrega 10 segundos. Tlacua aparece cerca del inicio, persigue a Tocino y lanza botellas que dejan charcos temporales. Cuache patrulla junto a la salida y embiste a quien se acerque. Cada nivel comienza en un refugio que oculta a Tocino hasta que sale de él. El nivel 1 incluye una guía inicial.

La escapatoria es un hueco estrecho y sin rótulo en la cerca: arriba en el nivel 1, a la derecha en el nivel 2 y a la izquierda en el nivel 3. Tocino tiene un tamaño menor para poder atravesarlo.

En el nivel 2, el mapa se revela al explorar. En el nivel 3, Tocino lleva un cerillo encendido: solo se ilumina su entorno actual y lo recorrido vuelve a quedar oscuro.

## Editar los mapas

Abre `nivel_1.tscn`, `nivel_2.tscn` o `nivel_3.tscn` en el editor de Godot. Cada nivel tiene su propio árbol de nodos: `Pisos/PisoVisible` muestra el suelo, `Escenario` contiene los obstáculos, objetos, escondites y refugio, y `Limites` contiene las colisiones de los bordes. Tocino, Tlacua y Cuache están completos dentro de los niveles, con sus sprites y colisiones editables. Las escenas individuales de personajes y proyectiles también muestran sus sprites en el editor. Puedes mover o editar estos nodos directamente; el script solo controla la lógica durante la partida. La oscuridad de los niveles 2 y 3 se aplica al ejecutar el juego, así que el mapa queda visible al editarlo. Los objetos recogibles flotan y pulsan para distinguirlos; vuelven a aparecer cinco segundos después de recogerlos. El tiempo de reaparición se puede cambiar en el inspector de cada objeto.

## Ejecutar

Abre `project.godot` con Godot 4.7 y ejecuta el proyecto. La escena inicial es `menu.tscn`.

## Comprobación rápida

```sh
godot --headless --path . --script res://tests/smoke.gd
godot --headless --path . --script res://tests/route_check.gd
godot --headless --path . --script res://tests/pickups.gd
godot --headless --path . --script res://tests/cuache_attack.gd
godot --headless --path . --script res://tests/enemy_roles.gd
```

Las pruebas comprueban las escenas, las salidas y sus aberturas, las rutas hacia todos los objetos, la recogida real mediante colisiones, los papeles de los enemigos, la seguridad del refugio inicial y las mecánicas de inventario, curación, tiempo, salto, esquiva, ocultamiento, proyectiles, aceite y pausa.
