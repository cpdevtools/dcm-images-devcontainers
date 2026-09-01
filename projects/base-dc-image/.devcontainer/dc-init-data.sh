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

mkdir -p "$DATA/claude-config" "$DATA/pnpm/store" "$DATA/pnpm/bin" "$DATA/yarn"

# NuGet, only on images that declare it -- the .NET-bearing ones set NUGET_*
# in their own containerEnv, so the base image stays toolchain-free.
if [ -n "${NUGET_PACKAGES:-}" ]; then
    mkdir -p "$DATA/nuget"/{packages,http-cache,plugins-cache,NuGet}

    # NUGET_* covers the caches, but NuGet.Config at ~/.nuget/NuGet has no env
    # var, so link just that subdirectory. Never touch all of ~/.nuget: an
    # instance may mount a volume over ~/.nuget/packages, and rm would fail on
    # the busy mountpoint and abort the lifecycle hook.
    if [ ! -L "$HOME/.nuget/NuGet" ]; then
        mkdir -p "$HOME/.nuget"
        if [ -d "$HOME/.nuget/NuGet" ]; then
            cp -an "$HOME/.nuget/NuGet/." "$DATA/nuget/NuGet/" 2>/dev/null || true
            rm -rf "$HOME/.nuget/NuGet" 2>/dev/null || true
        fi
        # Best effort only. If ~/.nuget is not ours to write -- e.g. Docker made
        # it root-owned to host a volume mount over ~/.nuget/packages -- leave it
        # alone rather than failing the hook. NUGET_* still redirects the caches.
        if [ ! -e "$HOME/.nuget/NuGet" ]; then
            ln -s "$DATA/nuget/NuGet" "$HOME/.nuget/NuGet" 2>/dev/null \
                || echo "dc-init-data: could not link ~/.nuget/NuGet, leaving as-is" >&2
        fi
    fi
fi

# Nothing else to do for pnpm: PNPM_HOME and PATH come from the image env, and
# the bin dir is created above. Do NOT call `pnpm setup` here -- it kills its
# own parent shell, which aborts the lifecycle hook that invoked this script.
