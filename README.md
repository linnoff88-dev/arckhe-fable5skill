# fable5skill

<div align="center">
  <img src="capa/logo.svg" alt="Arckhé AI" height="48" />
  <p><strong>Arckhé AI</strong></p>
</div>


## ðŸ“– Guia de uso

Guia completo (landing + passo a passo): **https://linnoff88-dev.github.io/

Skills para [Claude Code](https://claude.com/claude-code) que geram sites **scroll-film** â€” pÃ¡ginas onde a rolagem inteira funciona como um plano-sequÃªncia cARCKHÉtogrÃ¡fico contÃ­nuo, que se dissolve no conteÃºdo normal do site ao final.

## scroll-film-studio

A skill principal deste repositÃ³rio. Ã‰ um **processo, nÃ£o um template**: entrevista, pitcha 2-3 conceitos criativos nomeados, faz a direÃ§Ã£o de arte (paleta, tipografia, motion) e constrÃ³i a pÃ¡gina do zero â€” HTML/CSS/JS self-contained.

Instalar:
```bash
cp -r scroll-film-studio ~/.claude/skills/scroll-film-studio
```

### As trÃªs lanes (caminhos de construÃ§Ã£o)

| Lane | O que Ã© | Custo | Setup |
|---|---|---|---|
| **A â€” Pure-code** (padrÃ£o) | GSAP + Lenis: cenas fixadas, parallax, reveals | grÃ¡tis | zero â€” sÃ³ CDN |
| **B â€” Footage (Higgsfield/Kie.ai/fal/Replicate)** | VÃ­deo real gerado por IA, encadeado shot-a-shot (last frame â†’ next start image). Testada em produÃ§Ã£o com **Kie.ai Seedance** (`bytedance/v1-lite-image-to-video`, ~22 crÃ©ditos/clipe 720p) | crÃ©ditos do engine | conta prÃ³pria no serviÃ§o |
| **C â€” Footage via Agnes AI** | Mesmo contrato da Lane B, adaptado pro Agnes (`agnes-video-v2.0`, modo `keyframes`, interpola par de imagens em vez de gerar a partir de 1 start image) | **US$0** | `AGNES_API_KEY` |

A Lane A funciona pra qualquer pessoa que baixe a skill, sem contas nem custo. As Lanes B/C sÃ£o opt-in â€” sÃ³ entram quando o usuÃ¡rio jÃ¡ tem (ou quer) um engine de vÃ­deo por IA.

### Estrutura

```
scroll-film-studio/
â”œâ”€â”€ SKILL.md                    # o processo (entrevista â†’ pitch â†’ build â†’ verify â†’ deploy)
â”œâ”€â”€ references/
â”‚   â”œâ”€â”€ engine.md                # receitas de build: canvas scrub engine (Lane B/C) + motion vocabulary (Lane A)
â”‚   â”œâ”€â”€ playbook.md               # a lei da Lane B (Higgsfield/Kie.ai/fal/Replicate)
â”‚   â””â”€â”€ lane-c-agnes.md            # a lei da Lane C (Agnes AI) â€” par de keyframes por capÃ­tulo, custo zero
â””â”€â”€ scripts/
    â”œâ”€â”€ chain-step.sh              # gera 1 clipe encadeado (Lane B) + gate de SSIM na emenda
    â”œâ”€â”€ chain-step-agnes.sh         # mesmo contrato, engine Agnes (Lane C)
    â”œâ”€â”€ assemble.sh                 # concatena os clipes, extrai frames pro scrubber, amostra a cor da emenda
    â””â”€â”€ verify.js                    # puppeteer-core: teste de jank (rAF) + screenshots via `?jump=`
```

### A regra de ouro

Toda decisÃ£o de **gosto** (conceito, direÃ§Ã£o de arte, paleta, tipografia, motion, copy, o cÃ³digo da pÃ¡gina) Ã© feita pelo Claude que roda a skill â€” nunca delegada a outro modelo. Trabalho mecÃ¢nico (ffmpeg, SSIM, extraÃ§Ã£o de frames, deploy) vai para scripts puros, sem modelo nenhum. Um segundo CLI frontier (Codex, Gemini) pode opcionalmente ser usado sÃ³ pra *criticar* os conceitos antes da escolha â€” nunca pra escrever design ou cÃ³digo.

### VerificaÃ§Ã£o

Todo build implementa um contrato de dev: `?jump=<scrollY>` pra pousar prÃ©-rolado e `window.__ready` pra sinalizar que a pÃ¡gina assentou. `scripts/verify.js` usa isso pra tirar screenshot em qualquer posiÃ§Ã£o de scroll e medir jank real (p95/max de deltas de `requestAnimationFrame`), nunca FPS mÃ©dio.

### Exemplo construÃ­do com esta skill â€” as 3 lanes lado a lado

**Sinal** ([repo](https://github.com/linnoff88-dev/ARCKHÉ-sitefilm)) â€” o scroll-film do ARCKHÉ AI, mesma jornada (RuÃ­do â†’ ConvergÃªncia â†’ NÃºcleo â†’ Rede â†’ Portal) construÃ­da pelas trÃªs lanes, com menu de versÃµes no topo:

| VersÃ£o | Lane / Engine | Link |
|---|---|---|
| Filme I | Lane C â€” Agnes AI (US$0, keyframes interpolados) | [ver](https://linnoff88-dev.github.io/ |
| Filme II â€” Director's Cut | Lane C (mesma footage; filme dentro das letras, dots de capÃ­tulo, timeline de scrub) | [ver](https://linnoff88-dev.github.io/ |
| Filme III | **Lane B â€” Kie.ai Seedance Lite** (cadeia last-frameâ†’start real, ~112 crÃ©ditos) | [ver](https://linnoff88-dev.github.io/ |
| Code I | Lane A â€” GSAP+Lenis vertical (jank max 17ms) | [ver](https://linnoff88-dev.github.io/ |
| Code II | Lane A â€” corrida horizontal pinada, Ã¢mbar | [ver](https://linnoff88-dev.github.io/ |

Os runners usados na Lane B do exemplo (`kie-chain.sh` pro Kie.ai e `fal-chain.sh` pro fal.ai â€” upload â†’ createTask â†’ poll â†’ download â†’ extraÃ§Ã£o do Ãºltimo frame â†’ gate SSIM) estÃ£o no [repo do exemplo](https://github.com/linnoff88-dev/ARCKHÉ-sitefilm) e seguem o contrato de `scripts/chain-step.sh`.

**Notas de campo do Kie.ai** (medidas na prÃ¡tica): modelo `bytedance/v1-lite-image-to-video` via `POST /api/v1/jobs/createTask` + poll em `GET /api/v1/jobs/recordInfo?taskId=`; **data URI nÃ£o Ã© aceito** â€” subir a imagem antes em `https://kieai.redpandaai.co/api/file-base64-upload` e passar a `downloadUrl`; saldo em `GET /api/v1/chat/credit`; ~22,5 crÃ©ditos por clipe 720p/5s.

## Guardrails

- Zero dados pessoais ou API keys no repositÃ³rio â€” cada usuÃ¡rio traz sua prÃ³pria conta de engine de vÃ­deo (Lane B/C) e de deploy (Vercel/GitHub Pages).
- Respeita `prefers-reduced-motion` em todo build.
- Nunca sobe intermediÃ¡rios de build (clipes brutos, keyframes de referÃªncia) pro deploy final â€” sÃ³ o `index.html` + os frames realmente usados pelo scrubber.

---

<div align="center">
  <img src="capa/logo.svg" alt="Arckhé AI" height="32" />
  <p><strong>Arckhé AI</strong></p>
</div>