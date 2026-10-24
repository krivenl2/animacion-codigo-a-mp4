# El proceso (esto es lo que se reutiliza)

Las imágenes, los colores y el tema son **decoración intercambiable**. Lo que hay que entender
es el proceso. Sirve igual para un video oscuro y cinematográfico que para uno colorido, con
fotos de producto, capturas de pantalla o ilustraciones.

## Principio único

**El video es una función del tiempo.** Una sola función `renderAt(t)` recibe los segundos y
deja la pantalla exactamente como debe verse en ese instante. No hay animaciones sueltas ni
relojes del navegador: si llamas `renderAt(3.4)` mil veces, obtienes mil veces el mismo cuadro.
De ahí sale todo: se puede capturar cuadro por cuadro, y el resultado es siempre el mismo.

## Los 6 pasos

### 1. Guion por escenas
Una idea por escena, ~2 segundos cada una. Para 8-16 s: gancho → desarrollo → cierre. Se escribe
primero en texto plano; nada de esto se programa todavía.

### 2. Descomponer en capas
Cada cosa que se mueve es **una capa independiente** (un `div` o una `img`). La pregunta que
ordena todo es: *¿qué se mueve junto y qué se mueve aparte?*

| Capa | Elemento | Qué animación le toca |
|---|---|---|
| Fondo | foto / ilustración / degradado | cámara lenta: `scale` + deriva |
| Objetos | producto, taza, personaje recortado | entrada + flotar + salida |
| Interfaz | panel, dashboard, captura | entrada con blur + datos que crecen |
| Tarjetas | fotos secundarias | suben con un `rotate` leve |
| Texto | captions / títulos | entrada por bloques, palabra clave resaltada |
| Acabado | viñeta, grano, scrim | estático (o grano que vibra) |

### 3. La función y sus dos ayudantes
- `ease(p)` — suaviza (cúbica de salida). Sin esto todo se siente robótico.
- `fx(t, entra, sale)` — devuelve opacidad y desplazamiento de una capa según la ventana de
  tiempo en que vive. Con esto una escena se declara en una línea:
  `capa(t, 'cap2', 2.35, 4.15)`.

### 4. El repertorio de movimientos (el catálogo real)
Esta tabla es el valor del método. Cualquier efecto del video de referencia sale de aquí:

| Efecto | Cómo se hace |
|---|---|
| Cámara que empuja | `scale(1.03 → 1.13)` sobre el fondo + contenedor con `inset:-6%` |
| Deriva lateral | `translate(x%, y%)` con el mismo progreso que el zoom |
| Entrada de capa | opacidad `0→1` + `translateY(50px→0)` + `scale(.94→1)` en 0.7-0.9 s |
| Aparecer enfocando | `filter: blur(7px → 0)` en la misma entrada |
| Flotar | `translateY += sin((t - inicio) * 1.6) * 6` |
| Datos que crecen | barras: `height` interpolada; contadores: `Math.round(valor * progreso)` |
| Entrada escalonada | mismo efecto con desfase de 0.07 s por elemento ("stagger") |
| Tarjeta que sube | `translateY(80→0)` + `rotate(-3.5°→0)` |
| Salida | la ventana de `fx` cierra: opacidad `→0` y `translateY(-28px)` |
| Texto que resalta | dos colores en el mismo caption: palabra clave brillante, resto apagado |

### 5. Acabado: lo que hace ver caro
Cuatro cosas, todas de pocas líneas y **ninguna depende del color**:
- **Scrim**: gradiente oscuro en la zona del texto → legibilidad garantizada sobre cualquier foto.
- **Viñeta**: radial que oscurece las orillas → dirige la mirada al centro.
- **Grano**: `feTurbulence` en data-URI a `opacity:.06` con `mix-blend-mode:overlay` → quita el
  aspecto de "render de computadora".
- **Grade**: `filter: brightness/contrast/saturate` sobre las fotos (las imágenes generadas o de
  archivo suelen venir planas u oscuras).

### 6. Tema: cambiar el look sin tocar la animación
La paleta vive en variables al inicio del CSS. Cambiar el bloque `:root` cambia todo el video
(acento, colores del texto, fuerza del scrim, corrección de la foto). **La animación no se toca**:
por eso el mismo esqueleto sirve para un video oscuro de cine o para uno colorido de producto.

## Verificación (no se salta)

Antes de renderizar los cientos de cuadros, se capturan **2 o 3 instantes sueltos** (`?t=1.4`,
`?t=5.9`) y se miran: una sola escena visible, nada encimado, texto legible, sin bordes raros.
Si ahí está bien, el video estará bien. Ahí es donde apareció el marco claro de la imagen de IA y
el caption encimado — en el render completo eso habría costado 4 minutos por intento.

## Errores que ya costaron tiempo (no repetir)

1. **Animar con CSS** (`@keyframes`) y congelar con `currentTime`: en headless no se congela y
   salen todas las escenas encimadas. Todo el movimiento va calculado en JavaScript.
2. **Texto sobre las capas**: si el caption cae en la zona del panel, se vuelve ilegible. Scrim
   + zonas separadas (panel arriba, texto abajo).
3. **Imágenes de IA para interfaces**: traen marco o fondo claro. Mejor un panel en CSS, o
   recortar con `overflow:hidden` + `scale`.
4. **Fotos oscuras**: `brightness(1.5)` antes de juzgar; las generadas suelen venir subexpuestas.
5. **Perfil de Chrome**: `--user-data-dir` aparte, o el navegador del dueño bloquea el perfil.
6. **Rutas**: Chrome y ffmpeg necesitan `C:/...`, no `/c/...` de MSYS.

## Por qué esto es distinto de "IA de video"

No hay nada que "alucine": cada píxel está determinado por el código. Se corrige un número o una
palabra y **el resto queda idéntico**; se cambia una imagen y la animación se conserva; se cambia
la paleta y no se re-renderiza el diseño. Eso es exactamente lo que hace Claude Motion por dentro.
