# Para los agentes de la flota

Este repositorio existe para que **cualquier nodo** (la PC, el VPS de CETis, el teléfono,
la laptop de Jalados) pueda producir videos animados sin depender de un servicio de pago
ni de la PC del dueño.

## Lo mínimo para usarlo

```bash
git clone https://github.com/krivenl2/animacion-codigo-a-mp4.git
cd animacion-codigo-a-mp4
./render.sh                     # produce demo/animacion.mp4 en ~3.5 min
```

Si no hay Chrome, **Edge sirve igual** (el script lo detecta solo). Si `ffmpeg` no está,
instalarlo primero: es la única dependencia externa.

## Los tres tropiezos (esto ahorra una tarde)

1. **Nunca animar con CSS.** Se intentó primero con `@keyframes` + `document.getAnimations()`
   y `currentTime`: en modo headless **no se congelan** y el cuadro sale con todas las
   escenas encimadas. La solución es `renderAt(t)`: el estado se **calcula** desde `t` y se
   aplica como estilo en línea (`opacity`, `transform`, `width`).
2. **`--user-data-dir` en una carpeta aparte.** Si el dueño tiene su Chrome abierto, el
   perfil está bloqueado y el navegador de Hermes se niega a arrancar. Nunca cerrar su
   navegador; usar un perfil propio.
3. **Rutas nativas para programas nativos.** Chrome y ffprobe no entienden `/c/...` de
   MSYS: hay que pasarles `C:/...` o `F:/...`. Con rutas MSYS falla con "No such file".

Extra: si Hermes escribe el HTML con su herramienta de archivos, **usar un nombre nuevo**
cuando ya existe uno (se niega a sobrescribir sin lectura completa previa).

## Cómo se verifica antes de entregar

- Revisar **2 o 3 cuadros sueltos** con visión (`?t=1.0`, `?t=5.4`): una sola escena por
  cuadro, nada cortado, texto alineado. Si se ve bien, renderizar los 175.
- Al final, `ffprobe` debe decir: `codec_name=h264`, `pix_fmt=yuv420p`, `width=1080`,
  `height=1920`, `r_frame_rate=25/1`, `duration=7.000000`.

## Dónde está la versión publicada

- Demo en video: `https://www.jaladoscash.com/hermes/animaciones/demo.mp4`
- Demo en HTML (se ve en cualquier navegador, sin cuenta):
  `https://www.jaladoscash.com/hermes/animaciones/`
- Avisos entre nodos: el buzón del hosting, `agentes/<nodo>/BUZON.md` (un solo archivo por
  nodo, como quedó establecido).

## Reglas de la casa al entregar

- El **MP4 es el entregable**; el HTML es la fuente y va junto.
- Entregar en subcarpeta con `LEEME.md` que explique cómo cambiar textos y tiempos.
- No dejar archivos de paso fuera del proyecto; borrar `cuadros/` al terminar (está en
  `.gitignore`).
