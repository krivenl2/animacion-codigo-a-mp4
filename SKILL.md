---
name: animacion-codigo-a-mp4
description: "Use when hay que animar texto a MP4 sin IA de video."
version: 1.0.0
author: PECE
license: proprietary
metadata:
  hermes:
    tags: [animacion, motion-graphics, mp4, chrome-headless, ffmpeg, claude-motion]
---

# Animación escrita como código → MP4 (sin modelos de video)

## When to Use

- Kriven pide un video animado de textos/gráficos/formas (explicador, short, promo de datos) y **no** se necesita metraje realista ni personas generadas.
- Referencia: **Claude Motion** (Anthropic, 8-oct-2026) — `/motion` devuelve un MP4 porque **Claude escribe código** que anima el contenido; **no usa modelo de video**. Sólo en planes Team/Enterprise ✗ → esto lo replica gratis.
- **No** usar para reels de foto + texto quemado (`ffmpeg-reel-generation`) ni para video ilustrado con personajes (`video-animado-remotion-ia`).

## Pipeline probado (PECE, oct-2026) — 7 s en ~3 min

1. **Escribir la animación en HTML** con `window.renderAt(t)` que, dado un tiempo en segundos, calcule y aplique opacidades, desplazamientos, anchos de barras y contadores.
2. **Congelar cada cuadro desde la URL**: la página lee `?t=1.234` y llama `renderAt(t)` al cargar.
3. **Capturar con Chrome headless**, un proceso por cuadro:
   `chrome.exe --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1 --window-size=1080,1920 --user-data-dir=<perfil aparte> --virtual-time-budget=900 --screenshot=<carpeta>/f0000.png "file:///.../anim.html?t=1.0000"`
4. **Unir con ffmpeg**: `ffmpeg -y -framerate 25 -i f%04d.png -c:v libx264 -preset slow -crf 18 -pix_fmt yuv420p -movflags +faststart animacion.mp4`
5. **Revisar con visión** 2-3 cuadros sueltos (una escena por cuadro, nada encimado) antes de renderizar los 175.

## Reglas que evitan retrabajo

- **El movimiento se calcula en JS, NUNCA con animaciones CSS.** En headless las animaciones CSS no se congelan de forma fiable con `a.currentTime`: salieron las 4 escenas encimadas. Con `renderAt(t)` el cuadro es determinista.
- **El perfil de Chrome de Hermes está bloqueado si el dueño tiene Chrome abierto** → usar `--user-data-dir` en carpeta aparte. Nunca cerrar su navegador.
- **Escribir a `C:\Users\Kriven\...`**, no a `C:\Users\ThinkCentre\...`: el perfil está renombrado y el segundo da `Permission denied` al crear carpetas nuevas.
- **`write_file` se niega a sobrescribir un HTML existente** (aunque se escribió en la misma sesión) → usar nombre nuevo (`anim2.html`) o `patch`.
- **Programas nativos (ffprobe/ffmpeg) necesitan rutas `C:/...`**, no `/c/...` de MSYS.
- **Costo real:** ~1.5 s por cuadro con arranque de Chrome. 25 fps × 7 s = 175 cuadros ≈ 3-4 min.

## Diseño que funciona en vertical 1080x1920

- Fondo casi negro (`#07080B`) + dos halos radiales suaves; Segoe UI; acento lima `#7CFF6B` o azul `#5AA0FF`.
- 4 escenas de ~2 s: gancho → comparación → dato → cierre. Una idea por escena, poco texto.
- Escenas con ventana propia `fx(t, entra, sale)` que devuelve opacidad y `translateY`: entrada ease-out cúbico, salida ease-in.
- Contadores y barras también interpolados desde `t`.

## Imágenes y capas (el paso siguiente, verificado 24-oct-2026)

Las **imágenes entran al mismo motor**: son capas más. Lo que hace ver caro el resultado no es el modelo, es la **composición**:

1. **Placa de fondo = `<img>` en un contenedor** con `position:absolute; inset:-6%` (el negativo evita que se vean los bordes al hacer zoom) y `object-fit:cover`. La cámara es un `transform: scale(1.03 → 1.13)` con deriva lateral, calculado desde `t`.
2. **Objetos y paneles = capas independientes**, cada una con su propia entrada (opacidad + `translateY` + `scale` + `filter: blur(Npx → 0)`), y un flotar lento con `Math.sin(t)`.
3. **Panel de interfaz: mejor hecho en CSS que generado con IA.** Un panel generado con flux suele traer **marco o fondo claro** que se ve sucio; con `overflow:hidden` + `scale(1.09)` se recorta a medias. Con divs (barras, filas, contadores que crecen desde `t`) queda limpio y además es más “es código”.
4. **Fotos como tarjeta**: `border-radius` + `overflow:hidden` + `object-fit:cover` + `aspect-ratio` → cualquier imagen queda prolija sin importar su marco.
5. **Legibilidad obligatoria**: gradiente `scrim` oscuro abajo (0 → .94) y captions **fuera** de la zona del panel. Sin eso el texto cae sobre la imagen y se pierde.
6. **Acabado cinematográfico** (3 líneas): viñeta radial + `gran` de `feTurbulence` en data-URI a `opacity:.06` con `mix-blend-mode:overlay` + `filter:brightness(1.5)` en las fotos (las imágenes generadas suelen venir muy oscuras).
7. Las imágenes se generan gratis con `scripts/cf_imagen.py` de la skill `video-animado-remotion-ia` (flux-1-schnell, steps 4, ~173 neuronas).

Plantilla lista: `anim-imagenes3.html` del repo (fondo + panel CSS + tarjeta + captions, 8 s).

## Entrega

- El **MP4** es el entregable; el HTML es la fuente y va junto, en `Desktop/<nombre>/` con `LEEME.md` que explique los pasos y cómo cambiar textos y tiempos.
- Verificar con `ffprobe` antes de entregar: h264, `yuv420p`, fps y duración.
