#!/usr/bin/env bash
# Serve the exported HAVEN DHAKA 2026 HTML5 build.
# Opening export/web/index.html via file:// will NOT work; it must be served over HTTP.
set -euo pipefail

cd "$(dirname "$0")"
PORT="${1:-8060}"

if ! command -v python3 >/dev/null 2>&1; then
	echo "python3 is required to run this local server." >&2
	exit 1
fi

echo "Serving HAVEN DHAKA 2026 at http://127.0.0.1:${PORT}/"
echo "Press Ctrl+C to stop."
exec python3 -m http.server "$PORT" --bind 127.0.0.1 --directory export/web
