#!/usr/bin/env bash
set -euo pipefail

mkdir -p public
cp sbom-files/*.spdx.json public/

{
  cat <<'HTML'
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>wolfpack SBOMs</title>
<style>
  body { font-family: system-ui, sans-serif; max-width: 900px; margin: 2rem auto; padding: 0 1rem; }
  table { border-collapse: collapse; width: 100%; }
  th, td { text-align: left; padding: 0.5rem 0.75rem; border-bottom: 1px solid #ddd; }
  th { background: #f5f5f5; }
</style>
</head>
<body>
<h1>wolfpack SBOMs</h1>
<p>Software Bill of Materials (SPDX JSON) for every published image, regenerated daily by <a href="https://github.com/Theo-Gkisis/wolfpack">the build pipeline</a>.</p>
<table>
<thead><tr><th>Runtime</th><th>Version</th><th>SBOM</th></tr></thead>
<tbody>
HTML

  for f in $(ls public/*.spdx.json | sort -V); do
    base=$(basename "$f")
    rest="${base#sbom-}"
    rest="${rest%.spdx.json}"
    runtime="${rest%%-*}"
    version="${rest#*-}"
    echo "<tr><td>${runtime}</td><td>${version}</td><td><a href=\"${base}\">${base}</a></td></tr>"
  done

  cat <<'HTML'
</tbody>
</table>
</body>
</html>
HTML
} > public/index.html
