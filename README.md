# OWASP Juice Shop CTF – Training Setup

A local, self-contained CTF for practising web security with
[OWASP Juice Shop](https://owasp.org/www-project-juice-shop/) (an intentionally vulnerable web shop with 100+ challenges)
and a [CTFd](https://ctfd.io/) scoreboard where you submit flags and track your progress.

| Service    | URL                   | What it is                                     |
|------------|-----------------------|------------------------------------------------|
| Juice Shop | http://localhost:3000 | The target you hack                            |
| CTFd       | http://localhost:8000 | Scoreboard: challenges, hints, flag submission |

> ⚠️ Juice Shop is **deliberately insecure**. Run it only on your own machine or an isolated network, never exposed to the internet.

## Requirements

- Docker with Docker Compose v2 (`docker compose version`)
- `bash` and `curl` (on Windows, use WSL or Git Bash)

## Quick start

```bash
# 1. (Recommended) set your own secrets
cp .env.example .env        # then edit CTF_KEY and CTFD_SECRET_KEY

# 2. Start Juice Shop + CTFd
docker compose up -d

# 3. Build the CTFd challenge list from the running Juice Shop (all challenges, flags and hints)
./scripts/generate-ctfd-import.sh

# 4. Create the CTFd admin account and import the challenges
./scripts/setup-ctfd.sh     # asks you to choose an admin password
```

Then:

1. Open http://localhost:8000, **register a player account** (keep the admin account for administration).
2. Open http://localhost:3000 and start hacking. A good first challenge: find the hidden **Score Board**.
3. Every time you solve a challenge, Juice Shop shows a green notification with a **flag code**.
   Copy it and submit it on the matching challenge in CTFd.

Both scripts are safe to re-run: the setup script detects an already configured CTFd and skips the import if challenges exist.

## Training vs. competition mode

Juice Shop runs with the custom `training` profile ([`juice-shop/training.yml`](juice-shop/training.yml)):
CTF flags in notifications, **hints shown** in the Juice Shop score board, and the interactive
**Hacking Instructor** tutorials enabled. In CTFd, hints are free to unlock (`insertHints: free` in
[`ctf/ctf.config.yml`](ctf/ctf.config.yml)).

For a harder, competition-style event:

- set `JUICE_SHOP_PROFILE=ctf` in `.env` (the built-in profile: no in-app hints or tutorials), and
- set `insertHints: paid` in `ctf/ctf.config.yml` so unlocking a hint costs points.

Note: hints are only exported to CTFd while Juice Shop runs with hints enabled, so generate the CSV
(step 3) with the `training` profile and switch to `ctf` afterwards (`docker compose up -d`).

## Flags and the CTF key

Flag codes are an HMAC of the challenge name with `CTF_KEY`. The generator script reads `CTF_KEY` from
`.env`, so the flags in CTFd always match the ones Juice Shop shows. **If you change `CTF_KEY`, regenerate
and re-import the challenges** (reset CTFd with `docker compose down -v` first).

## Useful commands

```bash
docker compose logs -f juice-shop   # watch Juice Shop logs
docker compose restart juice-shop   # reset Juice Shop's data (solved state lives in CTFd)
docker compose down                 # stop everything, keep CTFd scores
docker compose down -v              # stop and wipe CTFd (accounts, scores, challenges)
```

## Optional challenges

A few challenges need external services and stay unsolvable without them (Juice Shop logs a warning at startup):

- *Chatbot Prompt Injection*, *Greedy Chatbot Manipulation*, *AI Debugging*: an OpenAI-compatible LLM at `http://localhost:11434/v1` (e.g. Ollama).
- *Mint the Honey Pot*, *Wallet Depletion*: internet access and an `ALCHEMY_API_KEY`.

All other challenges work fully offline.

## Learning resources

- [Pwning OWASP Juice Shop](https://pwning.owasp-juice.shop/) – the official free companion guide, with hints and full solutions
- [OWASP Top 10](https://owasp.org/Top10/) – the vulnerability categories the challenges are grouped by
- [juice-shop-ctf-cli](https://github.com/juice-shop/juice-shop-ctf) – the tool used to generate the CTFd import
