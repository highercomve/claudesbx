# claudesbx

Run [Claude Code](https://claude.ai/code) inside a disposable, reproducible Docker sandbox — while keeping your agents, skills, plugins, and project history on the host.

`claudesbx` is a thin wrapper that launches Claude Code in an Alpine container with a curated developer toolchain preinstalled, a persistent home volume, and your host `~/.claude` configuration bind-mounted in. The current working directory is mounted inside the container, so Claude operates on your real project files without installing anything on the host beyond Docker.

## Why

- **Isolation.** Claude runs with its own filesystem, shell history, package caches, and installed tools — nothing leaks onto the host.
- **Reproducibility.** The Dockerfile pins the toolchain (Node, Go, Python/uv, ripgrep, fzf, docker-cli, …). Anyone who runs the script gets the same environment.
- **Continuity.** Your agents, skills, plugins, `CLAUDE.md`, and `projects/` directory come from the host, so sessions, memory, and customizations survive across containers.
- **Disposability.** The container is `--rm`; only the named Docker volume and your host `~/.claude` persist. Blow it away any time.

## Requirements

- Docker (with the daemon running)
- Bash 4+
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

On first run (or when the `Dockerfile` changes), the image is built automatically. On first launch inside the container, the `serena` and `playwright` MCP servers are registered via `claude mcp add`.

## What gets mounted

| Host path              | Container path         | Purpose                                        |
| ---------------------- | ---------------------- | ---------------------------------------------- |
| `claudesbx-home` vol.  | `/root`                | Persistent container home (caches, shell, …)   |
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
| `CLAUDESBX_VOLUME`    | `claudesbx-home`   | Named volume used for `/root`       |

Example:

```sh
CLAUDESBX_IMAGE=claudesbx:work CLAUDESBX_VOLUME=claudesbx-work claudesbx
```

Running multiple named volumes gives you independent sandboxes (e.g. per-client, per-project).

## Customizing the toolchain

Edit the `Dockerfile` to add or remove packages. The wrapper detects that the Dockerfile is newer than the built image and rebuilds automatically on the next run.

## Uninstall

```sh
rm ~/.local/bin/claudesbx
docker volume rm claudesbx-home
docker image rm claudesbx
rm -rf ~/.claudesbx
```

## License

MIT — see [LICENSE](LICENSE).
