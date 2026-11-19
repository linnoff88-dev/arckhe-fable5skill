#!/bin/zsh
# chain-step-agnes.sh <assets-dir> <clip-name> <start-image> <end-image> <prompt> [prev-last-png]
#
# Generates ONE Lane-C clip via Agnes AI (agnes-video-v2.0, mode=keyframes, US$0), chaining
# <start-image> -> <end-image>, waits, downloads, extracts first+last frame, and SSIM-gates
# the junction against <prev-last-png>. Mirrors scripts/chain-step.sh's contract exactly so
# assemble.sh and the rest of Lane B's pipeline work unmodified.
#
# Mechanical lane — no model. Requires: curl, python3, ffmpeg. Needs AGNES_API_KEY in env
# (source it from ~/projetos/agnes-nei/.env before calling, same as videos-agnes does).
#
#   start-image and end-image are local PNG/JPG paths — sent as base64 data URIs (Agnes
#   accepts these despite docs claiming public URLs are required — confirmed working).
#   num_frames follows the 8n+1 rule; duration = num_frames / frame_rate (default 24fps, 81
#   frames ≈ 3.4s per clip — tune for your chapter pacing).
set -e -o pipefail
DIR=$1; NAME=$2; START=$3; END=$4; PROMPT=$5; PREV=$6
FRAMES=${AGNES_NUM_FRAMES:-81}; FPS=${AGNES_FRAME_RATE:-24}
W=${AGNES_WIDTH:-1312}; H=${AGNES_HEIGHT:-736}
API=${AGNES_API_BASE:-https://apihub.agnes-ai.com/v1}

if [[ -z "$DIR" || -z "$NAME" || -z "$START" || -z "$END" || -z "$PROMPT" ]]; then
  echo "usage: chain-step-agnes.sh <assets-dir> <clip-name> <start-image> <end-image> <prompt> [prev-last-png]"; exit 1
fi
[[ -r "$START" ]] || { echo "start image not readable: $START"; exit 1; }
[[ -r "$END" ]] || { echo "end image not readable: $END"; exit 1; }
[[ -n "$AGNES_API_KEY" ]] || { echo "AGNES_API_KEY not set (source ~/projetos/agnes-nei/.env first)"; exit 1; }
for bin in curl python3 ffmpeg; do command -v $bin >/dev/null || { echo "missing dependency: $bin"; exit 1; }; done
mkdir -p "$DIR"

b64() { python3 -c "import sys,base64; print(open(sys.argv[1],'rb').read().__class__ and base64.b64encode(open(sys.argv[1],'rb').read()).decode())" "$1"; }
mime() { case "$1" in *.png) echo image/png;; *.jpg|*.jpeg) echo image/jpeg;; *) echo image/png;; esac; }

echo "[$NAME] encoding keyframes as data URIs..."
b64 "$START" > /tmp/chain-step-agnes-start.b64
b64 "$END" > /tmp/chain-step-agnes-end.b64
STARTMIME=$(mime "$START"); ENDMIME=$(mime "$END")

PAYLOAD=$(python3 - "$PROMPT" "$FRAMES" "$FPS" "$W" "$H" "$STARTMIME" "$ENDMIME" <<'PY'
import json,sys
prompt,frames,fps,w,h,startmime,endmime = sys.argv[1:8]
a = "data:%s;base64,%s" % (startmime, open("/tmp/chain-step-agnes-start.b64").read().strip())
b = "data:%s;base64,%s" % (endmime, open("/tmp/chain-step-agnes-end.b64").read().strip())
print(json.dumps({
  "model":"agnes-video-v2.0","prompt":prompt,
  "num_frames":int(frames),"frame_rate":int(fps),"width":int(w),"height":int(h),
  "extra_body":{"image":[a,b],"mode":"keyframes"}
}))
PY
)
rm -f /tmp/chain-step-agnes-start.b64 /tmp/chain-step-agnes-end.b64

echo "[$NAME] creating job (US\$0, ${FRAMES}f@${FPS}fps, ${W}x${H})..."
echo "$PAYLOAD" > /tmp/chain-step-agnes-payload.json
ID=""
for i in 1 2 3 4 5 6; do
  CREATE=$(curl -sS -X POST "$API/videos" \
    -H "Authorization: Bearer $AGNES_API_KEY" -H "Content-Type: application/json" \
    -d @/tmp/chain-step-agnes-payload.json 2>&1)
  ID=$(echo "$CREATE" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('id') or d.get('video_id') or '')" 2>/dev/null)
  [[ -n "$ID" ]] && break
  echo "[$NAME] create retry $i/6 — $(echo "$CREATE" | head -c 200)"
  sleep 15
done
rm -f /tmp/chain-step-agnes-payload.json
if [[ -z "$ID" ]]; then
  echo "[$NAME] FAILED — could not parse a video id after retries. Raw output tail:"
  echo "$CREATE" | tail -5; exit 1
fi
echo "[$NAME] job $ID — polling (Agnes ~34% transient 503s; retrying)..."

URL=""
for i in $(seq 1 90); do
  POLL=$(curl -fsS "$API/agnesapi?video_id=$ID" -H "Authorization: Bearer $AGNES_API_KEY" 2>&1) || { sleep 5; continue; }
  STATUS=$(echo "$POLL" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('status',''))" 2>/dev/null)
  if [[ "$STATUS" == "completed" ]]; then
    URL=$(echo "$POLL" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('video_url') or d.get('url') or '')" 2>/dev/null)
    break
  elif [[ "$STATUS" == "failed" ]]; then
    echo "[$NAME] FAILED — job reported failed (unbilled; just retry the whole step):"
    echo "$POLL" | tail -5; exit 1
  fi
  sleep 10
done
if [[ -z "$URL" ]]; then
  echo "[$NAME] FAILED — timed out waiting for completion (15m)."; exit 1
fi

curl -fsSL -o "$DIR/$NAME.mp4" "$URL"
ffmpeg -y -v error -i "$DIR/$NAME.mp4" -vf "select=eq(n\,0)" -frames:v 1 -update 1 -q:v 1 "$DIR/$NAME-first.png"
ffmpeg -y -v error -sseof -0.05 -i "$DIR/$NAME.mp4" -update 1 -q:v 1 "$DIR/$NAME-last.png"
echo "[$NAME] downloaded: $(ffprobe -v error -select_streams v -show_entries stream=width,height,nb_frames -of csv=p=0 "$DIR/$NAME.mp4")"

if [[ -n "$PREV" ]]; then
  SSIM=$( (ffmpeg -i "$PREV" -i "$DIR/$NAME-first.png" -lavfi ssim -f null - 2>&1 || true) | grep -o 'All:[0-9.]*' | cut -d: -f2)
  ffmpeg -y -v error -i "$PREV" -i "$DIR/$NAME-first.png" -filter_complex "[0][1]hstack" "$DIR/$NAME-junction-compare.jpg" || true
  if [[ -z "$SSIM" ]]; then echo "[$NAME] JUNCTION SSIM could not be computed — inspect $NAME-junction-compare.jpg"; exit 2; fi
  echo "[$NAME] JUNCTION SSIM vs $(basename $PREV): $SSIM   (side-by-side: $NAME-junction-compare.jpg)"
  PASS=$(python3 -c "print(1 if float('$SSIM') >= 0.80 else 0)")
  if [[ "$PASS" == "0" ]]; then
    echo "[$NAME] JUNCTION REVIEW REQUIRED (<0.80). SSIM under-reads on stochastic texture (clouds/"
    echo "[$NAME] particles/caustics can be seamless at 0.6) — inspect the side-by-side. A structural"
    echo "[$NAME] change (new horizon/objects/grade) is a real fail: regenerate the end-keyframe with"
    echo "[$NAME] Agnes img2img referencing the previous end frame, identical framing and colour grade."
    exit 2   # exit 2 = downloaded fine, junction needs a human/model eye before proceeding
  fi
fi
echo "[$NAME] DONE"
