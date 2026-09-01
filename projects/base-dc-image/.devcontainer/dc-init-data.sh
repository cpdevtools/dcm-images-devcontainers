#!/usr/bin/env bash
# Creates the persistent data root for this devcontainer.
#
# /devcontainer is a bind mount, so anything created at image build time is
# masked once the mount lands. This runs at container start instead, and is
# idempotent so it can be re-asserted on every restart.
set -euo pipefail

SETTINGS="${CONTAINER_SETTINGS_FOLDER:-/devcontainer/.devcontainer}"
DATA="$SETTINGS/.data"

mkdir -p "$DATA"

# One ignore file keeps everything persisted here out of the workspace repo,
# regardless of what that repo's own .gitignore says.
[ -f "$DATA/.gitignore" ] || printf '*\n' >"$DATA/.gitignore"

# Adopt a claude config from before .data existed (same-fs rename, instant).
if [ -d "$SETTINGS/.claude-config" ] && [ ! -e "$DATA/claude-config" ]; then
    mv "$SETTINGS/.claude-config" "$DATA/claude-config"
fi

mkdir -p "$DATA/claude-config" "$DATA/pnpm/store" "$DATA/yarn"

# NuGet, only on images that declare it -- the .NET-bearing ones set NUGET_*
# in their own containerEnv, so the base image stays toolchain-free.
if [ -n "${NUGET_PACKAGES:-}" ]; then
    mkdir -p "$DATA/nuget"/{packages,http-cache,plugins-cache,NuGet}

    # NuGet.Config lives at ~/.nuget/NuGet and no env var relocates it, so link
    # the whole nuget home. Migrates existing content exactly once.
    if [ ! -L "$HOME/.nuget" ]; then
        if [ -d "$HOME/.nuget" ]; then
            cp -an "$HOME/.nuget/." "$DATA/nuget/" 2>/dev/null || true
            rm -rf "$HOME/.nuget"
        fi
        ln -s "$DATA/nuget" "$HOME/.nuget"
    fi
fi

# pnpm global bin dir, ready to use without per-instance wiring.
export SHELL="${SHELL:-/bin/bash}"
export PNPM_HOME="$DATA/pnpm"
pnpm setup >/dev/null 2>&1 || true
