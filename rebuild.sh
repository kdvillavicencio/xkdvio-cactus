#!/bin/bash

# Start the Astro server in the background
start_server() {
  echo "[rebuild] Starting Astro server..."
  # node ./dist/server/entry.mjs &
  serve /app/dist -l 4321 &
  SERVER_PID=$!
  echo "[rebuild] Server started (PID $SERVER_PID)"
}

# Kill the running server
stop_server() {
  if [ -n "$SERVER_PID" ] && kill -0 "$SERVER_PID" 2>/dev/null; then
    echo "[rebuild] Stopping server (PID $SERVER_PID)..."
    kill "$SERVER_PID"
    wait "$SERVER_PID" 2>/dev/null
  fi
}

# Rebuild Astro and restart the server
rebuild_and_restart() {
  echo "[rebuild] Content change detected — rebuilding..."
  stop_server
  npm run build
  if [ $? -eq 0 ]; then
    echo "[rebuild] Build succeeded."
    start_server
  else
    echo "[rebuild] Build failed. Server not restarted. Fix the issue and save again."
  fi
}

# Initial server start
start_server

# Watch the content directory for changes
# -r: recursive, -e: events to watch, --format: output format
echo "[rebuild] Watching /app/src/content for changes..."
inotifywait -r -m -e close_write,moved_to,create,delete \
  --format '%w%f %e' \
  /app/src/content |
while read -r changed_file event; do
  echo "[rebuild] Detected $event on $changed_file"
  # Debounce: wait briefly in case multiple files are being written at once
  sleep 1
  # Drain any additional events that queued up during the sleep
  while inotifywait -r -t 1 -e close_write,moved_to,create,delete \
      /app/src/content &>/dev/null; do
    sleep 1
  done
  rebuild_and_restart
done