# claudesbx

Run [Claude Code](https://claude.ai/code) inside a disposable, reproducible Docker sandbox — while keeping your agents, skills, plugins, and project history on the host.

`claudesbx` is a thin wrapper that launches Claude Code in an Alpine container with a curated developer toolchain preinstalled, a persistent home directory on the host, and your host `~/.claude` configuration bind-mounted in. The current working directory is mounted inside the container, so Claude operates on your real project files without installing anything on the host beyond Docker.

## Why

- **Isolation.** Claude runs with its own filesystem, shell history, package caches, and installed tools — nothing leaks onto the host.
- **Reproducibility.** The Dockerfile pins the toolchain (Node, Go, Python/uv, ripgrep, fzf, docker-cli, …). Anyone who runs the script gets the same environment.
- **Continuity.** Your agents, skills, plugins, `CLAUDE.md`, and `projects/` directory come from the host, so sessions, memory, and customizations survive across containers.
- **Disposability.** The container is `--rm`; only `~/.claudesbx/home` and your host `~/.claude` persist. Blow it away any time.
- **Host-user permissions.** The container runs as your host UID/GID, so files Claude creates in `$PWD` are owned by you — no `sudo chown` dance after the fact.
- **Docker-in-Docker.** If `/var/run/docker.sock` is present, the entrypoint adds your in-container user to the socket's group so tools like `./kas-container` or `docker compose` work without `sudo`.

## Requirements

- Docker (with the daemon running)
- A POSIX shell (`sh`, `bash`, `zsh`, …)
- Linux or macOS (Windows via WSL2)

## Install

```sh
git clone git@github.com:highercomve/claudesbx.git
cd claudesbx
./install              # symlinks to ~/.local/bin/claudesbx
# or
./install /usr/local/bin/claudesbx
```

Ensure the install destination is on your `PATH`.

## Usage

From any project directory:

```sh
claudesbx                 # launch Claude Code in the current directory
claudesbx --help          # args are forwarded to `claude`
```

On first run (or when `Dockerfile` / `entrypoint.sh` change), the image is built automatically. On first launch inside the container, the `serena` and `playwright` MCP servers are registered via `claude mcp add`.

## What gets mounted

| Host path              | Container path         | Purpose                                        |
| ---------------------- | ---------------------- | ---------------------------------------------- |
| `~/.claudesbx/home`    | `/root`                | Persistent container home (caches, shell, …)   |
| `~/.claudesbx/.claude.json` | `/root/.claude.json` | Per-sandbox Claude config                     |
| `~/.claude/agents`     | `/root/.claude/agents` | Shared agents                                  |
| `~/.claude/skills`     | `/root/.claude/skills` | Shared skills                                  |
| `~/.claude/plugins`    | `/root/.claude/plugins`| Shared plugins                                 |
| `~/.claude/CLAUDE.md`  | `/root/.claude/CLAUDE.md` | Global user instructions                    |
| `~/.claude/projects`   | `/root/.claude/projects` | Session history & memory                     |
| `~/.serena` *(if present)* | `/root/.serena`    | Serena MCP state                               |
| `/var/run/docker.sock` *(if present)* | same | Docker-in-Docker for tools that need it |
| `$PWD`                 | `$PWD`                 | Your working directory                         |

The working directory is mounted at the same absolute path inside the container so file paths reported by Claude match the host.

## Configuration

Override defaults via environment variables:

| Variable              | Default            | Description                         |
| --------------------- | ------------------ | ----------------------------------- |
| `CLAUDESBX_IMAGE`     | `claudesbx`        | Docker image tag                    |
| `CLAUDESBX_HOME_DIR`  | `~/.claudesbx/home`| Host dir bind-mounted at `/root`    |

Example:

```sh
CLAUDESBX_IMAGE=claudesbx:work CLAUDESBX_HOME_DIR=~/.claudesbx/work claudesbx
```

Pointing `CLAUDESBX_HOME_DIR` at different paths gives you independent sandboxes (e.g. per-client, per-project).

## Customizing the toolchain

Edit the `Dockerfile` to add or remove packages. The wrapper detects when `Dockerfile` or `entrypoint.sh` is newer than the built image and rebuilds automatically on the next run.

The `claude` CLI and `uv` are installed at image-build time under `/opt/tools` (not `/root/.local`) so they remain available once the host bind mount takes over `/root` at runtime. `PATH` also includes `/root/.local/bin`, so any native installation Claude Code writes to `$HOME/.local/bin` at runtime is picked up without a warning.

## Uninstall

```sh
./uninstall              # remove the symlink from ~/.local/bin/claudesbx
./uninstall /usr/local/bin/claudesbx
./uninstall --purge      # also remove the docker image and ~/.claudesbx
```

Or manually:

```sh
rm ~/.local/bin/claudesbx
docker image rm claudesbx
rm -rf ~/.claudesbx
```

## License

MIT — see [LICENSE](LICENSE).
