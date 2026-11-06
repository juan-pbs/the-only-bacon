# Bocetos de acciones

Las láminas se leen de izquierda a derecha y de arriba abajo. Son estudios de pose para planear animaciones 2D en Godot; todavía no son cuadros finales de animación.

## Tocino (5 columnas x 2 filas)

1. Espera alerta
2. Caminar
3. Correr
4. Saltar
5. Esquivar
6. Esconderse detrás de una caja
7. Recoger una lata
8. Lanzar la lata
9. Recibir daño o resbalar en aceite
10. Escapar por la salida

### Estados especiales del tocino (3 columnas x 1 fila)

1. Recuperar vida con mantequilla
2. Ganar tiempo con el reloj de bolsillo
3. Derrota cuando la vida llega a cero

## Tlacua (3 columnas x 3 filas)

1. Espera con sartén
2. Patrullar
3. Perseguir
4. Preparar el golpe de sartén
5. Golpe amplio de sartén
6. Lanzar botella de aceite
7. Buscar al jugador tras perderlo de vista
8. Recibir impacto de lata
9. Quedar aturdido

## Cuache (3 columnas x 3 filas)

1. Espera
2. Caminar siguiendo a Tlacua
3. Perseguir
4. Bloquear un pasillo
5. Girar para cerrar otra ruta
6. Buscar detrás de una caja
7. Tropezar
8. Recibir impacto de lata
9. Quedar aturdido

La dirección visual base es la vista cenital o ligeramente inclinada del GDD. Para producir sprites finales habrá que animar los estados necesarios en las cuatro direcciones y mantener tamaño, pivote y colisiones consistentes.
