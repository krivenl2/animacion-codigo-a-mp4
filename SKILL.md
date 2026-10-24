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

## Pipeline probado (PECE, oct-2026) — 7 s en ~3.5 min

1. **Escribir la animación en HTML** con `window.renderAt(t)` que, dado un tiempo en segundos, calcule y aplique opacidades, desplazamientos, anchos de barras y contadores.
2. **Congelar cada cuadro desde la URL**: la página lee `?t=1.234` y llama `renderAt(t)` al cargar.
3. **Capturar con Chrome headless**, un proceso por cuadro:
   `chrome.exe --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1 --window-size=1080,1920 --user-data-dir=<perfil aparte> --virtual-time-budget=900 --screenshot=<carpeta>/f0000.png "file:///.../anim.html?t=1.0000"`
4. **Unir con ffmpeg**: `ffmpeg -y -framerate 25 -i f%04d.png -c:v libx264 -preset slow -crf 18 -pix_fmt yuv420p -movflags +faststart animacion.mp4`
5. **Revisar con visión** 2-3 cuadros sueltos (una escena por cuadro, nada encimado) antes de renderizar los 175.

Repositorio con la plantilla y el script listos: `github.com/krivenl2/animacion-codigo-a-mp4`
(`./render.sh` hace los pasos 3 y 4 completos).

## Reglas que evitan retrabajo

- **El movimiento se calcula en JS, NUNCA con animaciones CSS.** En headless las animaciones CSS no se congelan de forma fiable con `a.currentTime`: salieron las 4 escenas encimadas. Con `renderAt(t)` el cuadro es determinista.
- **El perfil de Chrome de Hermes está bloqueado si el dueño tiene Chrome abierto** → usar `--user-data-dir` en carpeta aparte. Nunca cerrar su navegador.
- **Escribir a `C:\Users\Kriven\...`**, no a `C:\Users\ThinkCentre\...`: el perfil está renombrado y el segundo da `Permission denied` al crear carpetas nuevas.
- **`write_file` se niega a sobrescribir un HTML existente** (aunque se escribió en la misma sesión) → usar nombre nuevo (`anim2.html`) o `patch`.
- **Programas nativos (ffprobe/ffmpeg/chrome) necesitan rutas `C:/...`**, no `/c/...` de MSYS.
- **Costo real:** ~1.1 s por cuadro con arranque de Chrome. 25 fps × 7 s = 175 cuadros ≈ 3.5 min. Para 1 minuto, trabajar por bloques.

## Diseño que funciona en vertical 1080x1920

- Fondo casi negro (`#07080B`) + dos halos radiales suaves; Segoe UI; acento lima `#7CFF6B` o azul `#5AA0FF`.
- 4 escenas de ~2 s: gancho → método → dato → cierre. Una idea por escena, poco texto.
- Escenas con ventana propia `fx(t, entra, sale)` que devuelve opacidad y `translateY`: entrada ease-out cúbico, salida ease-in.
- Contadores y barras también interpolados desde `t`.

## Entrega

- El **MP4** es el entregable; el HTML es la fuente y va junto, en `Desktop/<nombre>/` o en la carpeta del proyecto, con `LEEME.md` que explique los pasos y cómo cambiar textos y tiempos.
- Verificar con `ffprobe` antes de entregar: h264, `yuv420p`, fps y duración.
- Publicar la demo también en el hosting (`jaladoscash.com/hermes/animaciones/`) para que cualquier nodo o teléfono la abra sin cuenta.
