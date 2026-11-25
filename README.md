# fable5skill

<div align="center">
  <img src="capa/logo.svg" alt="Arckhé AI" height="48" />
  <p><strong>Arckhé AI</strong></p>
</div>


## ê°Å¸ââ Guia de uso

Guia completo (landing + passo a passo): **https://linnoff88-dev.github.io/

Skills para [Claude Code](https://claude.com/claude-code) que geram sites **scroll-film** ê¢â¬â pêÂ¡ginas onde a rolagem inteira funciona como um plano-sequêÂªncia cARCKHêtogrêÂ¡fico contêÂ­nuo, que se dissolve no conteêÂºdo normal do site ao final.

## scroll-film-studio

A skill principal deste repositêÂ³rio. êâ° um **processo, nêÂ£o um template**: entrevista, pitcha 2-3 conceitos criativos nomeados, faz a direêÂ§êÂ£o de arte (paleta, tipografia, motion) e constrêÂ³i a pêÂ¡gina do zero ê¢â¬â HTML/CSS/JS self-contained.

Instalar:
```bash
cp -r scroll-film-studio ~/.claude/skills/scroll-film-studio
```

### As trêÂªs lanes (caminhos de construêÂ§êÂ£o)

| Lane | O que êÂ© | Custo | Setup |
|---|---|---|---|
| **A ê¢â¬â Pure-code** (padrêÂ£o) | GSAP + Lenis: cenas fixadas, parallax, reveals | grêÂ¡tis | zero ê¢â¬â sêÂ³ CDN |
| **B ê¢â¬â Footage (Higgsfield/Kie.ai/fal/Replicate)** | VêÂ­deo real gerado por IA, encadeado shot-a-shot (last frame ê¢â â next start image). Testada em produêÂ§êÂ£o com **Kie.ai Seedance** (`bytedance/v1-lite-image-to-video`, ~22 crêÂ©ditos/clipe 720p) | crêÂ©ditos do engine | conta prêÂ³pria no serviêÂ§o |
| **C ê¢â¬â Footage via Agnes AI** | Mesmo contrato da Lane B, adaptado pro Agnes (`agnes-video-v2.0`, modo `keyframes`, interpola par de imagens em vez de gerar a partir de 1 start image) | **US$0** | `AGNES_API_KEY` |

A Lane A funciona pra qualquer pessoa que baixe a skill, sem contas nem custo. As Lanes B/C sêÂ£o opt-in ê¢â¬â sêÂ³ entram quando o usuêÂ¡rio jêÂ¡ tem (ou quer) um engine de vêÂ­deo por IA.

### Estrutura

```
scroll-film-studio/
ê¢âÅê¢ââ¬ê¢ââ¬ SKILL.md                    # o processo (entrevista ê¢â â pitch ê¢â â build ê¢â â verify ê¢â â deploy)
ê¢âÅê¢ââ¬ê¢ââ¬ references/
ê¢ââ   ê¢âÅê¢ââ¬ê¢ââ¬ engine.md                # receitas de build: canvas scrub engine (Lane B/C) + motion vocabulary (Lane A)
ê¢ââ   ê¢âÅê¢ââ¬ê¢ââ¬ playbook.md               # a lei da Lane B (Higgsfield/Kie.ai/fal/Replicate)
ê¢ââ   ê¢ââê¢ââ¬ê¢ââ¬ lane-c-agnes.md            # a lei da Lane C (Agnes AI) ê¢â¬â par de keyframes por capêÂ­tulo, custo zero
ê¢ââê¢ââ¬ê¢ââ¬ scripts/
    ê¢âÅê¢ââ¬ê¢ââ¬ chain-step.sh              # gera 1 clipe encadeado (Lane B) + gate de SSIM na emenda
    ê¢âÅê¢ââ¬ê¢ââ¬ chain-step-agnes.sh         # mesmo contrato, engine Agnes (Lane C)
    ê¢âÅê¢ââ¬ê¢ââ¬ assemble.sh                 # concatena os clipes, extrai frames pro scrubber, amostra a cor da emenda
    ê¢ââê¢ââ¬ê¢ââ¬ verify.js                    # puppeteer-core: teste de jank (rAF) + screenshots via `?jump=`
```

### A regra de ouro

Toda decisêÂ£o de **gosto** (conceito, direêÂ§êÂ£o de arte, paleta, tipografia, motion, copy, o cêÂ³digo da pêÂ¡gina) êÂ© feita pelo Claude que roda a skill ê¢â¬â nunca delegada a outro modelo. Trabalho mecêÂ¢nico (ffmpeg, SSIM, extraêÂ§êÂ£o de frames, deploy) vai para scripts puros, sem modelo nenhum. Um segundo CLI frontier (Codex, Gemini) pode opcionalmente ser usado sêÂ³ pra *criticar* os conceitos antes da escolha ê¢â¬â nunca pra escrever design ou cêÂ³digo.

### VerificaêÂ§êÂ£o

Todo build implementa um contrato de dev: `?jump=<scrollY>` pra pousar prêÂ©-rolado e `window.__ready` pra sinalizar que a pêÂ¡gina assentou. `scripts/verify.js` usa isso pra tirar screenshot em qualquer posiêÂ§êÂ£o de scroll e medir jank real (p95/max de deltas de `requestAnimationFrame`), nunca FPS mêÂ©dio.

### Exemplo construêÂ­do com esta skill ê¢â¬â as 3 lanes lado a lado

**Sinal** ([repo](https://github.com/linnoff88-dev/ARCKHê-sitefilm)) ê¢â¬â o scroll-film do ARCKHê AI, mesma jornada (RuêÂ­do ê¢â â ConvergêÂªncia ê¢â â NêÂºcleo ê¢â â Rede ê¢â â Portal) construêÂ­da pelas trêÂªs lanes, com menu de versêÂµes no topo:

| VersêÂ£o | Lane / Engine | Link |
|---|---|---|
| Filme I | Lane C ê¢â¬â Agnes AI (US$0, keyframes interpolados) | [ver](https://linnoff88-dev.github.io/ |
| Filme II ê¢â¬â Director's Cut | Lane C (mesma footage; filme dentro das letras, dots de capêÂ­tulo, timeline de scrub) | [ver](https://linnoff88-dev.github.io/ |
| Filme III | **Lane B ê¢â¬â Kie.ai Seedance Lite** (cadeia last-frameê¢â âstart real, ~112 crêÂ©ditos) | [ver](https://linnoff88-dev.github.io/ |
| Code I | Lane A ê¢â¬â GSAP+Lenis vertical (jank max 17ms) | [ver](https://linnoff88-dev.github.io/ |
| Code II | Lane A ê¢â¬â corrida horizontal pinada, êÂ¢mbar | [ver](https://linnoff88-dev.github.io/ |

Os runners usados na Lane B do exemplo (`kie-chain.sh` pro Kie.ai e `fal-chain.sh` pro fal.ai ê¢â¬â upload ê¢â â createTask ê¢â â poll ê¢â â download ê¢â â extraêÂ§êÂ£o do êÂºltimo frame ê¢â â gate SSIM) estêÂ£o no [repo do exemplo](https://github.com/linnoff88-dev/ARCKHê-sitefilm) e seguem o contrato de `scripts/chain-step.sh`.

**Notas de campo do Kie.ai** (medidas na prêÂ¡tica): modelo `bytedance/v1-lite-image-to-video` via `POST /api/v1/jobs/createTask` + poll em `GET /api/v1/jobs/recordInfo?taskId=`; **data URI nêÂ£o êÂ© aceito** ê¢â¬â subir a imagem antes em `https://kieai.redpandaai.co/api/file-base64-upload` e passar a `downloadUrl`; saldo em `GET /api/v1/chat/credit`; ~22,5 crêÂ©ditos por clipe 720p/5s.

## Guardrails

- Zero dados pessoais ou API keys no repositêÂ³rio ê¢â¬â cada usuêÂ¡rio traz sua prêÂ³pria conta de engine de vêÂ­deo (Lane B/C) e de deploy (Vercel/GitHub Pages).
- Respeita `prefers-reduced-motion` em todo build.
- Nunca sobe intermediêÂ¡rios de build (clipes brutos, keyframes de referêÂªncia) pro deploy final ê¢â¬â sêÂ³ o `index.html` + os frames realmente usados pelo scrubber.

---

<div align="center">
  <img src="capa/logo.svg" alt="Arckhé AI" height="32" />
  <p><strong>Arckhé AI</strong></p>
</div>