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

## Cómo tratar un video de referencia (regla del dueño, 24-oct-2026)

- De una referencia se toma **el proceso**, no los efectos: cómo se produjo la pieza (estructura, continuidad, cómo
  se construyó cada capa, cómo se midió). Copiar el efecto concreto no aporta nada.
- Si la referencia es de **otro género** (metraje real con VFX generativos, stop motion, cinematográfico), **decirlo**
  y no intentar replicarla: el dueño lo corrige igual ("no es lo mismo que los anteriores").
- De una comparación se reutiliza el **formato** (A/B, HUD fijo, métrica que corre), no los efectos.

## When to Use

- Kriven pide un video animado de textos/gráficos/formas (explicador, short, promo de datos) y **no** se necesita metraje realista ni personas generadas.
- Referencia: **Claude Motion** (Anthropic, 8-oct-2026) — `/motion` devuelve un MP4 porque **Claude escribe código** que anima el contenido; **no usa modelo de video**. Sólo en planes Team/Enterprise ✗ → esto lo replica gratis.
- **No** usar para reels de foto + texto quemado (`ffmpeg-reel-generation`) ni para video ilustrado con personajes (`video-animado-remotion-ia`).

## Pipeline probado (PECE, oct-2026) — 7 s en ~3 min; 17 s en ~6 min con render en paralelo

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
- **Posicionar dentro de un panel: `left`/`top` en %, nunca `translate(%)`.** En un hijo con `position:absolute`, `translate(X%)` se mide contra **su propio** tamaño, no contra el contenedor: el cursor o el señalamiento se queda pegado a la esquina. Y para que además acompañe al zoom/paneo, el elemento va **dentro** del contenedor del panel, no en el frame.
- **Nunca `-shortest` al pegar audio**: recorta el video a la duración del audio (17.48 → 16.9 s) y se come el cierre. El largo lo manda el video; el audio termina antes y deja silencio.
- **Reescribir un PNG que ya se cargó no se ve**: Chrome cachea por URL y el cuadro sale con la versión vieja aunque el perfil sea nuevo. Cada retoque de imagen guarda con **nombre nuevo**.
- **Un barrido de color global se lleva los iconos de la barra**: para localizar un estado negativo (rojo) hay que buscar sólo dentro del **ROI de las tarjetas**, difuminar y luego **verificar numéricamente** (promedio RGB + conteo de coincidencias = 0).
- **Costo real por cuadro (medido):** cuadros de texto/gráficos ≈1.1-1.5 s; un cuadro con **foto + captura de app + grano ≈2.7 s**. Un video de 17.5 s (437 cuadros) tardó **19 min** con un solo proceso y **~6-7 min con tres** → usar `scripts/render-paralelo.sh` (reparte los índices entre workers y hace segunda pasada para los cuadros que falten).
- **Cronometra 3 cuadros antes de lanzar un render largo** y da el ETA real al dueño: prometer "10 minutos" y tardar 19 se lee como abandono.

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
6. **Acabado cinematográfico** (3 líneas): viñeta radial + `grano` de `feTurbulence` en data-URI a `opacity:.06` con `mix-blend-mode:overlay` + `filter:brightness(1.5)` en las fotos (las imágenes generadas suelen venir muy oscuras).
7. Las imágenes se generan gratis con `scripts/cf_imagen.py` de la skill `video-animado-remotion-ia` (flux-1-schnell, steps 4, ~173 neuronas).

Plantilla lista: `anim-imagenes3.html` del repo (fondo + panel CSS + tarjeta + captions, 8 s).

## Material real: capturas de la app y voz

Una pieza de producto necesita **la app de verdad** en pantalla y voz. Reglas:

- **Captura la ventana con `PrintWindow(hwnd, hdc, 2)`** (PW_RENDERFULLCONTENT), nunca con `CopyFromScreen`: `CopyFromScreen` copia lo que esté encima y mete al cuadro las ventanas del dueño. `PrintWindow` renderiza el contenido aunque esté tapado y no roba el foco.
- **Busca la ventana por proceso, con espera**: `Get-Process <nombre> | ? { $_.MainWindowHandle -ne 0 }` en un bucle de hasta ~40 s (una app WPF tarda en exponer el handle). Cierra **solo lo que tú abriste** (bandera `$yaCorria`).
- **Tapa los estados negativos en la imagen, no con CSS**: detecta el color dentro de un **ROI restringido**, difumina y oscurece (blend ≥0.94) y **verifica numéricamente** (promedio RGB y conteo de píxeles del color). Un barrido de color global se lleva los iconos rojos de la barra de herramientas.
- **Imagen editada = nombre de archivo nuevo.** Chrome cachea por URL: reescribir el mismo PNG deja el cuadro con la versión vieja aunque el perfil sea nuevo.
- **Los señalamientos van DENTRO del contenedor del panel**, no en el frame: así acompañan al zoom y al paneo; en coordenadas del frame se desalinean al acercar.
- **La voz manda la duración**: genera los fragmentos, mídelos con `ffprobe` y arma el video con la suma + silencios (no al revés). Mezcla con `adelay=<ms>:all=1` + `amix=normalize=0` + `loudnorm=I=-16`.
- **Si la nube de voz no conecta, usa la local**: `System.Speech` con la voz `es-MX` instalada (aquí *Microsoft Sabina Desktop*) escribe WAV offline y alcanza para narrar.
- **Sólo lo que la app muestra**: los números en pantalla salen de la captura real; lo que esté en estado negativo se tapa, no se inventa un positivo.

Recetas exactas (PowerShell de captura, PIL de retoque, ffmpeg de mezcla): `references/material-real-capturas-y-voz.md`.

## Recursos del lenguaje visual (ampliado 24-oct-2026, dos referencias vistas cuadro a cuadro)

### Estructura y continuidad
- **HUD fijo**: los captions no cambian de lugar en todo el video y la métrica vive clavada en una esquina.
  Cambia el fondo, no el marco. Es lo que hace que 60 escenas se sientan una sola pieza.
- **Métrica que corre** (el recurso más fuerte de la referencia): un número en una esquina que **sube con cada
  frase** y **cambia de unidad solo** (`0 m → 8 m → 2,4 km → 17 km → 998 km`). Se implementa con una lista de
  pares `(tiempo, valor, unidad)` y `Math.round(valor * ease(p))`.
- **Objeto-ancla**: el logo o una forma (un orbe, un destello) reaparece en casi todas las escenas con distinto
  tamaño. Da continuidad sin repetir el fondo.
- **Contador de pasos**: un `1, 2, 3…` pequeño al costado que avanza con el argumento.
- **Reinicio final**: al cerrar, la métrica vuelve a cero → cierra el círculo narrativo.

### Profundidad sin WebGL
- **Planos apilados en perspectiva**: contenedor con `perspective:1200px`, capas con `transform-style:preserve-3d`
  + `rotateX(55deg) rotateZ(45deg)` + `translateZ` distinto por capa; entradas escalonadas 0.12 s. Es el look
  de "escritorio desarmado".
- **Mockups de interfaz en perspectiva** (Excel, correo, informe): cajas HTML con `rotate`/`skewY` leve y sombra;
  no hace falta captura real.
- **Pilas de objetos para el tiempo**: tres tarjetas de calendario iguales, cada una con más `translateZ` y mes
  distinto → "pasaron las semanas" sin decirlo.
- **Match-cut**: una forma se convierte en la siguiente (carpeta → tarjeta) cambiando `border-radius`, tamaño y
  posición en el mismo tramo de tiempo.

### Interacción simulada
- **Cursor falso**: un SVG de puntero que se mueve y "hace clic" sobre el mockup. Convierte una imagen estática
  en una demostración.
- **Cuadrícula que se completa**: N tarjetas pequeñas que se van marcando en secuencia (una cada 0.15 s) y un
  check grande al final.
- **Bucle dibujado**: una flecha circular que se traza con `stroke-dasharray` + `stroke-dashoffset`.

### Datos sobre foto
- **Foto real de fondo** con fundido lento entre fotos (una frase = una foto) y grade cálido.
- **Dos colores**: fondo cálido y **todo lo de datos en un acento frío** (cian). Marcadores de falla, rutas y
  gráficas usan sólo ese acento.
- **Diagramas en SVG**: contorno de un mapa con una zona resaltada, ruta de red dibujada por tramos, barras
  simples con etiqueta.
- **Nota de papel**: tarjeta clara con una línea de texto y subrayado rojo encima de la foto, para la frase que
  explica.
- **Bokeh**: puntos de luz que aparecen y se apagan; 5-10 a la vez, nunca más.

### Tipografía
- Caption que avanza **palabra por palabra**, no por línea: cada palabra con su propio `opacity`, la clave en
  bold y color pleno.
- El número grande siempre con `font-variant-numeric: tabular-nums` para que no baile al cambiar.

### Comparativas A/B (formato de contenido, no efecto)

- **Layout de comparación**: la misma animación dos veces (dos contenedores al 50%, el mismo `renderAt(t)`),
  con **encabezados fijos** y un **chip de dato** bajo cada lado (costo, tiempo, versión). Sirve para
  "antes / después", "con / sin", "a pie / con la consola".
- **Regla de credibilidad**: en una comparación, el lado perdedor va en **gris** con encabezados idénticos.
  Se lee como juicio, no como adorno.

**Fuera de alcance** (otra familia, no intentar aquí): metraje real con efectos generativos — humo
volumétrico, dobles 3D, composición sobre video filmado. Eso requiere modelos de **video** de pago
(Runway/Kling/Veo), y se cobra por corrida. Este pipeline llega hasta la capa gráfica.

### Presentador en esquina, caption karaoke y tarjeta de producto (referencia 25-oct-2026)

- **Presentador fijo (PiP de cámara)**: la cara en una esquina, siempre en el mismo lugar, sobre el B-roll que
  cambia atrás. Es el recurso que más confianza da en video de negocio y no necesita estudio: un clip a cámara,
  recortado en círculo o cuadrado con borde y sombra. En código: `video`/`img` con `position:absolute` fijo.
- **Caption karaoke arriba**: 2-4 palabras a la vez, siempre en el mismo lugar, letras grandes y blancas. Es la
  evolución del caption por bloques: se calcula el tramo de cada palabra y se encienden una por una con `t`.
- **Tarjeta de producto/modelo con logo brillante**: fondo oscuro + icono centrado con halo + nombre abajo.
  **Una sola plantilla repetida para todos los items** (`{logo, nombre, acento}` como datos): así cuatro
  productos se ven como una serie y no como cuatro videos distintos.
- **Marca de agua del tema**: el nombre del item en una esquina, pequeño, mientras cambia el fondo.
- **Fondo neón abstracto**: gradientes radiales saturados + líneas o partículas con deriva lenta; nunca estático
  y nunca rápido.

### Nube de puntos, escenario y tipografía de terminal (referencia 25-oct-2026)

La pieza más técnica de las vistas: casi todo el cuadro está hecho de **puntos**.

- **Campo de puntos que cambia de forma**: una reja de cientos de puntos pequeños cuyo `left/top` se
  **interpola** entre una forma y otra (onda → esfera → silueta → plano). Es el recurso más llamativo y el más
  barato: un arreglo de posiciones por forma + `lerp` con `ease` sobre `t`. En canvas o con `div`s posicionados.
- **Escenario en perspectiva**: piso oscuro inclinado con borde luminoso y horizonte; todo lo demás se apoya
  encima. Un solo `transform: perspective(900px) rotateX(62deg)` sobre el contenedor del piso da el efecto y da
  **consistencia** entre escenas.
- **Morphing por posiciones**: no hay transición entre escenas — la misma nube cambia de destino, así que el ojo
  nunca ve un corte.
- **Kicker máquina de escribir**: frase corta arriba que se escribe **palabra por palabra** con un guion final
  (`GRÁFICA—`), como cursor de terminal.
- **Billboards**: etiquetas y porcentajes dentro de la escena, inclinados con la misma perspectiva; no son texto
  pegado encima.
- **Luz volumétrica simple**: un haz = `div` con gradiente lineal + `filter:blur()`, rotado sobre el objeto y con
  `mix-blend-mode:screen`. Un halo = círculo con gradiente radial y blur.
- **Cámara casi fija**: sólo `scale` lento y paralaje del piso. El movimiento lo ponen los puntos, no la cámara.
- **Fuera de alcance**: personajes u objetos 3D renderizados (el avatar, el monitor) no salen de este pipeline;
  entran como **imagen generada** en una capa, o se sustituyen por su **silueta de puntos**, que es lo que el
  propio video hace cuando quiere algo abstracto.

## Entrega

- El **MP4** es el entregable; el HTML es la fuente y va junto, en `Desktop/<nombre>/` con `LEEME.md` que explique los pasos y cómo cambiar textos y tiempos.
- Verificar con `ffprobe` antes de entregar: h264, `yuv420p`, fps y duración.
- **Los repos del dueño van PRIVADOS**: no tiene ningún proyecto público. Si hay que crearlo, `--private` desde el inicio — cambiar la visibilidad después falla con `HTTP 403` cuando el token no tiene permiso de administración.
- **Lo ya especificado se ejecuta en el mismo turno.** Cuando la mejora está decidida (dijo "adelante", o la técnica ya quedó identificada), se implementa y se entrega; volver a preguntar "¿se las meto?" se lee como que no avanzaste y luego reclama el tiempo perdido.
- **Copia el MP4 también a `Desktop/<nombre>/`**, además del repo: es de ahí de donde lo abre.
- Recetas ejecutables: `scripts/render-paralelo.sh` (render multiproceso) y `scripts/mezclar-voz.sh` (fragmentos de voz + mux con `adelay`/`amix`/`loudnorm`).
