# Lane C — CARCKHÉtic footage via Agnes AI (US$0)

Lane C is Lane B's exact contract (storyboard → chain → junction-gate → assemble →
canvas scrub build), swapped onto **Agnes AI** as the engine. It exists alongside Lane
A and Lane B in `SKILL.md` unmodified — this file is the law for Lane C only, read it
before running Lane C. Trigger: user has/wants Agnes instead of Higgsfield/Kie.ai/fal/
Replicate, or says "usa o Agnes" / "faz com Agnes" for the footage lane.

## Why Agnes needs a different chain shape than Lane B

Higgsfield/Kie.ai/fal take **one start image + a prompt** and generate video forward —
the end frame is whatever the model decides. Agnes's `agnes-video-v2.0` instead
**interpolates between two keyframes** (`mode: "keyframes"`) — you must supply both the
start AND the end image per clip. This means Lane C storyboarding needs **two images per
chapter** (like `videos-agnes` already does), not one:

- Chapter N's **end keyframe** doubles as chapter N+1's **start keyframe** — this is
  where the seamless chain comes from (same as Lane B's "last frame becomes next start
  image", just decided up front instead of extracted after the fact).
- Generate keyframes with `agnes-image-2.1-flash`: the chain's first start image via
  text2img, every subsequent end keyframe via **img2img derived from the previous end
  keyframe** (not generated independently) — same "derive, don't generate in parallel"
  rule as `videos-agnes`, so identity/world stays consistent across chapters.

## The chain contract (mirrors Lane B exactly)

1. **Storyboard** the chosen concept as N chapters (5 is still the sweet spot), one
   continuous camera direction, same as Lane B.
2. **Generate keyframe pairs**: chapter 1's start (text2img) and end (img2img from
   start); chapter 2's start = chapter 1's end (reuse the file, no re-generation); chapter
   2's end (img2img from chapter 1's end); and so on down the chain.
3. **Generate each clip** with `scripts/chain-step-agnes.sh <assets-dir> <clip-name>
   <start-img> <end-img> <prompt> [prev-last-png]` — same call shape as Lane B's
   `chain-step.sh`, drafts fine at lower `AGNES_NUM_FRAMES`/resolution for a cheap first
   pass since there's no cost either way, then re-run at your target frame count.
4. **Junction-gate every seam** — the script SSIM-gates automatically (same ≥0.80
   threshold, same side-by-side JPEG). A real fail here means the interpolation drifted;
   repair by regenerating the **end keyframe** (not the clip) with tighter continuity
   language, then re-chain.
5. **Assemble** with the *existing* `scripts/assemble.sh` — unchanged, it only cares
   about clip `.mp4` files in order, doesn't know which engine made them.
6. **Build the page** exactly per Lane B's step 5 in `SKILL.md` and `references/
   engine.md` §Scrub-engine — the canvas scrubber doesn't know or care which engine
   produced the frames.

## Cost discipline (Lane C is different from Lane B here)

Agnes is **US$0** — no credits, no "confirm before spending", no receipt. Skip that
whole step from `SKILL.md`'s COST DISCIPLINE section for Lane C. What still matters:

- **Prompts in ENGLISH** — Portuguese trips Agnes's content filter with spurious
  HTTP 400s on legitimate content.
- **~34% transient 503s** on both image and video calls — `chain-step-agnes.sh` retries
  video polling already; if image generation 503s, just retry the single call.
- **Video rate limit**: ~1 req/min declared for video — space clip generations out if
  you see 429s.
- **`num_frames` must satisfy 8n+1** (e.g. 81, 89, 97…) and `≤ 441` (≈18.4s @24fps);
  `duration = num_frames / frame_rate`.
- **Base64 data URIs work for keyframes** despite docs implying public URLs are
  required — `chain-step-agnes.sh` already encodes local files this way.
- **`size`/response metadata can lie** — verify actual clip dimensions with `ffprobe`,
  same discipline as Lane B.

## Prerequisites

- `AGNES_API_KEY` sourced into the environment before calling `chain-step-agnes.sh`
  (same key file as `videos-agnes`/`imagens-agnes`: `~/projetos/agnes-nei/.env`).
- `ffmpeg`/`ffprobe`, `curl`, `python3` on PATH.
- No account/credits needed beyond the Agnes API key itself.

## Limitations to disclose to the user (don't hide these)

- **Identity drift across chapters** — no seed control in Agnes; derive-from-previous
  keyframes minimizes but doesn't eliminate this, same caveat as `videos-agnes`.
- **Human faces are more fragile** than animals/creatures/abstract subjects.
- **Strong action** (impacts, fast camera whips) tends to render amenized/soft.
- Always inspect the keyframe contact sheet and every junction compare JPEG before
  calling a chapter done — never take a green SSIM number alone as proof if the
  side-by-side looks structurally different.
