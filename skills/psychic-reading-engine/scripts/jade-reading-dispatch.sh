#!/bin/bash
# jade-reading-dispatch.sh — Run real reading engine then dispatch to Jade for interpretation
# Usage: jade-reading-dispatch.sh --name "Name" --date "YYYY-MM-DD" --time "HH:MM" --place "City" --question "love"
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse args
NAME="" DATE="" TIME="" PLACE="" QUESTION="general" SPREAD="3-card"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --name) NAME="$2"; shift 2 ;;
        --date) DATE="$2"; shift 2 ;;
        --time) TIME="$2"; shift 2 ;;
        --place) PLACE="$2"; shift 2 ;;
        --question) QUESTION="$2"; shift 2 ;;
        --spread) SPREAD="$2"; shift 2 ;;
        *) shift ;;
    esac
done

# Geocode place
COORDS=$(python3 -c "
places = {
    'kuala lumpur': (3.139, 101.687), 'kl': (3.139, 101.687),
    'singapore': (1.352, 103.820), 'sg': (1.352, 103.820),
    'penang': (5.416, 100.333), 'hong kong': (22.320, 114.169),
    'jakarta': (-6.175, 106.827), 'bangkok': (13.756, 100.502),
    'tokyo': (35.682, 139.692), 'new york': (40.713, -74.006),
    'london': (51.507, -0.128), 'los angeles': (34.052, -118.244),
    'seoul': (37.567, 126.978), 'taipei': (25.033, 121.565),
    'sydney': (-33.869, 151.209), 'melbourne': (-37.814, 144.963),
}
place = '${PLACE}'.lower().strip()
lat, lon = places.get(place, (3.139, 101.687))
print(f'{lat} {lon}')
")
LAT=$(echo "$COORDS" | cut -d' ' -f1)
LON=$(echo "$COORDS" | cut -d' ' -f2)

# Run real reading engine
READING=$(bash "$SCRIPT_DIR/psychic-reading.sh" \
    --name "$NAME" --date "$DATE" --time "$TIME" \
    --lat "$LAT" --lon "$LON" --tz "Asia/Kuala_Lumpur" \
    --spread "$SPREAD" --question "$QUESTION" --output markdown 2>/dev/null)

echo "$READING"
echo ""
echo "---"
echo "Above is the REAL computed reading from QMDJ + Astrology + Tarot engines."
echo "Jade should interpret this data in her warm, mystical voice."
