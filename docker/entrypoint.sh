#!/bin/bash
# Ensure course env binaries stay on PATH, then hand off to micromamba's entrypoint
# (activates ENV_NAME for non-interactive commands). Interactive bash also activates
# ENV_NAME via ~/.bashrc → _activate_current_env.sh.
set -euo pipefail

export MAMBA_ROOT_PREFIX="${MAMBA_ROOT_PREFIX:-/opt/conda}"
export ENV_NAME="${ENV_NAME:-scalable_course}"
export PATH="/opt/tools/bin:${MAMBA_ROOT_PREFIX}/envs/${ENV_NAME}/bin:${PATH}"

if [ "$#" -eq 0 ]; then
  set -- bash
fi

if [ -x /usr/local/bin/_entrypoint.sh ]; then
  exec /usr/local/bin/_entrypoint.sh "$@"
fi

# Fallback if micromamba entrypoint is missing
if command -v micromamba >/dev/null 2>&1; then
  eval "$(micromamba shell hook -s bash)"
  micromamba activate "${ENV_NAME}"
fi
exec "$@"
