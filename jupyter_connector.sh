#!/bin/bash

# Default values
CONFIG_FILE=""
REMOTE_HOST="mike"
ENV_NAME="base"
PORT=15001
REMOTE_DIR=""

# Parse command-line options
while getopts "f:e:p:d:h:" opt; do
  case $opt in
    f) CONFIG_FILE="$OPTARG" ;;
    e) ENV_NAME="$OPTARG" ;;
    p) PORT="$OPTARG" ;;
    d) REMOTE_DIR="$OPTARG" ;;
    h) REMOTE_HOST="$OPTARG" ;;
    *) echo "Usage: $0 [-f config_file] [-e env] [-p port] [-d dir] [-h remote_host]"; exit 1 ;;
  esac
done

# Read config file if specified
if [ -n "$CONFIG_FILE" ]; then
  while IFS='=' read -r key value; do
    case $key in
      "REMOTE_HOST") REMOTE_HOST="$value" ;;
      "ENV_NAME") ENV_NAME="$value" ;;
      "PORT") PORT="$value" ;;
      "REMOTE_DIR") REMOTE_DIR="$value" ;;
    esac
  done < "$CONFIG_FILE"
fi

# SSH tunnel in background
ssh -N -L ${PORT}:localhost:${PORT} ${REMOTE_HOST} &
TUNNEL_PID=$!

# Build remote command
REMOTE_CMD="source ~/miniforge3/bin/activate ${ENV_NAME} && "
if [ -n "$REMOTE_DIR" ]; then
  REMOTE_CMD+="cd ${REMOTE_DIR} && "
fi
REMOTE_CMD+="jupyter lab --no-browser --port=${PORT}"

# Start JupyterLab
ssh ${REMOTE_HOST} "$REMOTE_CMD"

# Cleanup
kill $TUNNEL_PID

