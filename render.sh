#!/usr/bin/env bash
# Renderiza una animación HTML a MP4, cuadro por cuadro, sin IA de video.
#
#   ./render.sh                          -> usa anim.html y produce demo/animacion.mp4
#   ./render.sh anim.html salida.mp4     -> otros nombres
#   ./render.sh anim.html salida.mp4 30 8 -> 30 fps y 8 segundos
#
# Requisitos: Chrome (o Edge) instalado y ffmpeg en el PATH.

set -u

HTML="${1:-anim.html}"
SALIDA="${2:-demo/animacion.mp4}"
FPS="${3:-25}"
DUR="${4:-7}"
N=$(awk -v f="$FPS" -v d="$DUR" 'BEGIN{printf "%d", f*d}')

# --- localizar Chrome ---
CHROME=""
for c in \
  "C:/Program Files/Google/Chrome/Application/chrome.exe" \
  "C:/Program Files (x86)/Google/Chrome/Application/chrome.exe" \
  "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe" \
  "C:/Program Files/Microsoft/Edge/Application/msedge.exe" ; do
  [ -f "$c" ] && CHROME="$c" && break
done
if [ -z "$CHROME" ]; then echo "ERROR: no encontre Chrome ni Edge"; exit 1; fi
command -v ffmpeg >/dev/null || { echo "ERROR: ffmpeg no esta en el PATH"; exit 1; }

# --- rutas absolutas (los programas nativos necesitan rutas C:/..., no /c/...) ---
DIR="$(cd "$(dirname "$HTML")" && pwd -W 2>/dev/null || dirname "$HTML")"
ARCHIVO="$(basename "$HTML")"
CUADROS="$DIR/cuadros"
PERFIL="$DIR/.perfil-chrome"
mkdir -p "$CUADROS" "$(dirname "$SALIDA")"
rm -f "$CUADROS"/f*.png

echo "=== $N cuadros ($FPS fps, $DUR s) desde $ARCHIVO ==="

for ((i = 0; i < N; i++)); do
  t=$(awk -v i="$i" -v f="$FPS" 'BEGIN{printf "%.4f", i/f}')
  n=$(printf "f%04d.png" "$i")
  "$CHROME" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1 \
    --window-size=1080,1920 --user-data-dir="$PERFIL" --virtual-time-budget=900 \
    --screenshot="$CUADROS/$n" "file:///$DIR/$ARCHIVO?t=$t" >/dev/null 2>&1
  [ $((i % 25)) -eq 0 ] && echo "  cuadro $i de $N (t=$t s)"
done

LISTOS=$(ls "$CUADROS"/f*.png 2>/dev/null | wc -l)
echo "=== cuadros: $LISTOS de $N ==="
[ "$LISTOS" -lt "$N" ] && { echo "FALTAN CUADROS: abortando"; exit 1; }

echo "=== uniendo con ffmpeg ==="
ffmpeg -y -framerate "$FPS" -i "$CUADROS/f%04d.png" \
  -c:v libx264 -preset slow -crf 18 -pix_fmt yuv420p -movflags +faststart \
  "$SALIDA" 2>&1 | tail -3

echo
echo "=== resultado ==="
ls -la "$SALIDA"
ffprobe -v error -show_entries format=duration,size:stream=codec_name,width,height,pix_fmt,r_frame_rate \
  -of default=noprint_wrappers=1 "$SALIDA"
