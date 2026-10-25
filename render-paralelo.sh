#!/usr/bin/env bash
# Renderiza en paralelo: N trabajadores se reparten los cuadros (pares/impares/tercios).
# Uso: ./render-paralelo.sh <html> <salida.mp4> [fps] [segundos] [trabajadores]
set -u

HTML="${1:?falta el html}"
SALIDA="${2:?falta la salida}"
FPS="${3:-25}"
DUR="${4:-17.5}"
W="${5:-3}"

BASE_DIR="$(cd "$(dirname "$HTML")" && pwd -W 2>/dev/null || dirname "$HTML")"
ARCHIVO="$(basename "$HTML")"
CUADROS="$BASE_DIR/cuadros"
N=$(awk -v f="$FPS" -v d="$DUR" 'BEGIN{printf "%d", f*d}')
CHROME="C:/Program Files/Google/Chrome/Application/chrome.exe"
INICIO=$(date +%s)

mkdir -p "$CUADROS" "$(dirname "$SALIDA")"
rm -f "$CUADROS"/f*.png
echo "=== $N cuadros · $W trabajadores · $FPS fps · $DUR s ==="

captura() {
    local i="$1" prof="$2"
    local t n
    t=$(awk -v i="$i" -v f="$FPS" 'BEGIN{printf "%.4f", i/f}')
    n=$(printf "f%04d.png" "$i")
    "$CHROME" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1 \
        --window-size=1080,1920 --user-data-dir="$prof" --virtual-time-budget=1500 \
        --screenshot="$CUADROS/$n" "file:///$BASE_DIR/$ARCHIVO?t=$t" >/dev/null 2>&1
}

for ((w = 0; w < W; w++)); do
    (
        PROF="$BASE_DIR/.perfil-render-$w"
        for ((i = w; i < N; i += W)); do
            captura "$i" "$PROF"
        done
    ) &
done
wait
echo "  primera pasada: $(ls "$CUADROS"/f*.png 2>/dev/null | wc -l) de $N"

# segunda pasada: los que hayan fallado
FALTAN=0
for ((i = 0; i < N; i++)); do
    n=$(printf "f%04d.png" "$i")
    if [ ! -f "$CUADROS/$n" ]; then
        FALTAN=$((FALTAN + 1))
        captura "$i" "$BASE_DIR/.perfil-render-fix"
    fi
done
[ "$FALTAN" -gt 0 ] && echo "  reintentados: $FALTAN"

LISTOS=$(ls "$CUADROS"/f*.png 2>/dev/null | wc -l)
echo "=== cuadros: $LISTOS de $N ($(($(date +%s) - INICIO)) s) ==="
if [ "$LISTOS" -lt "$N" ]; then echo "FALTAN CUADROS: abortando"; exit 1; fi

echo "=== uniendo ==="
ffmpeg -y -framerate "$FPS" -i "$CUADROS/f%04d.png" \
    -c:v libx264 -preset medium -crf 19 -pix_fmt yuv420p -movflags +faststart \
    "$SALIDA" 2>&1 | tail -2

echo "=== resultado (total $(($(date +%s) - INICIO)) s) ==="
ls -la "$SALIDA"
