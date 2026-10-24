# Animación escrita como código → MP4

Explicadores cortos (texto, gráficos, datos) hechos con **HTML + CSS + JavaScript** y
renderizados a video, **sin ningún modelo de generación de video**. Cero costo por
render, cero servicios externos: todo ocurre en la máquina.

## El contexto

En octubre de 2026 Anthropic lanzó **Claude Motion**: escribes `/motion` en el chat y te
devuelve un MP4. La clave de cómo funciona está en su propia documentación:

> *"Claude Motion no usa un modelo de generación de video. Claude escribe código que anima
> el texto, gráficos, formas e imágenes."*

Por eso se puede cambiar una palabra, un número o un tiempo sin rehacer la animación — y
por eso no cuesta extra. También por eso **no hace falta el plan de Team/Enterprise**:
el mismo resultado se logra con un navegador y ffmpeg.

Este repositorio es esa versión libre.

## Cómo funciona (3 pasos)

1. **`anim.html`** es la animación. No usa animaciones CSS para el movimiento: expone una
   función `renderAt(t)` que, dado un tiempo en segundos, calcula y aplica opacidades,
   desplazamientos, barras y contadores. Cada cuadro es determinista.
2. **Chrome headless captura un PNG por cuadro.** La página acepta `?t=1.234` en la URL y
   dibuja exactamente ese instante. 25 fps × 7 s = 175 cuadros.
3. **ffmpeg los une** en un MP4 H.264 con `yuv420p` y `faststart`, listo para cualquier
   plataforma.

## Imágenes: el mismo motor, más capas

Las fotos entran como capas y se animan igual (calculadas desde `t`). Lo que hace ver
profesional el resultado es la **composición**, no la IA:

- **Placa de fondo**: `<img>` en un contenedor con `inset:-6%` + `object-fit:cover`; la cámara
  es un `scale(1.03 → 1.13)` con deriva lateral.
- **Paneles de interfaz: mejor en CSS que generados.** Una imagen de UI hecha con IA suele traer
  marco o fondo claro que se ve sucio; con divs queda limpio y es más "es código".
- **Fotos como tarjeta**: `border-radius` + `overflow:hidden` + `object-fit:cover` +
  `aspect-ratio` → prolijas sin importar el marco que traigan.
- **Legibilidad**: `scrim` con gradiente oscuro abajo y captions **fuera** de la zona del panel.
- **Acabado de cine**: viñeta radial + grano (`feTurbulence` en data-URI, `opacity:.06`,
  `mix-blend-mode:overlay`) + `filter:brightness(1.5)` en las fotos, que suelen venir oscuras.

Plantilla: **`anim-imagenes3.html`** (fondo + panel CSS + tarjeta de foto + captions, 8 s) y su
video en `demo/demo-imagenes.mp4`.

## Uso

```bash
# la demo por omisión: anim.html -> demo/animacion.mp4 (25 fps, 7 s)
./render.sh

# otros parámetros: <html> <salida> <fps> <segundos>
./render.sh anim.html demo/animacion.mp4 30 8
```

Requisitos: **Chrome o Edge** instalado y **ffmpeg** en el PATH. Nada más.
Funciona igual en Windows (git-bash) y en Linux.

## Para cambiar el video

Todo lo editable está en `anim.html`:

- Los **textos** de cada escena están en el HTML (bloques `<div class="scene">`).
- Los **tiempos** están en la función `renderAt` — cada escena se declara con su ventana:
  `aplicar(t, 's1', 0.00, 2.05)` significa "visible entre el segundo 0 y el 2.05".
- Los **contadores y barras** también se interpolan desde `t` (nunca desde el reloj del
  navegador).

## Reglas de oro

Estas tres son las que hicieron perder tiempo. Están explicadas en `LEEME-AGENTES.md`:

1. **El movimiento va en JavaScript, nunca en animaciones CSS.** En modo headless las
   animaciones CSS no se congelan de forma fiable y se ven todas las escenas encimadas.
2. **Perfil de Chrome aislado** (`--user-data-dir`), para no tocar el navegador del usuario.
3. **Rutas nativas (`C:/…`, `F:/…`) para Chrome y ffmpeg**, nunca rutas de MSYS (`/c/…`).

## Rendimiento medido

| Dato | Valor |
|---|---|
| Costo por cuadro (1080×1920, arranque de Chrome incluido) | ~1.1 s |
| Demo de 7 s a 25 fps (175 cuadros) + ffmpeg | ~3.5 min |
| Peso del MP4 resultante | ~400 KB |

Para un video de 1 minuto hay que trabajar por bloques y unir al final.

## Créditos

Método armado y probado en casa (PECE / Hermes). Idea original del producto: Claude Motion,
Anthropic. Este repositorio no usa ni redistribuye nada de Anthropic.
