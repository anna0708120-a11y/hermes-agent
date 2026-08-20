#!/bin/sh
set -eu

HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
export HERMES_HOME
mkdir -p "$HERMES_HOME"

hermes config set model.provider ollama-cloud
hermes config set model.default gemma4:31b

exec hermes gateway run --no-supervise
