#!/usr/bin/env bash
# Build FmtCli (.NET 8) and stage into out/plugin/
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FMTCLI_PROJECT="$PROJECT_ROOT/fmtcli/PoorMansTSqlFormatterFmtCli/PoorMansTSqlFormatterFmtCli.csproj"
CONFIGURATION="${1:-Release}"
RUNTIME="${RUNTIME:-linux-x64}"
SELF_CONTAINED="${SELF_CONTAINED:-false}"

if ! command -v dotnet >/dev/null 2>&1; then
  echo "error: .NET SDK not found. Install .NET 8: https://dotnet.microsoft.com/download/dotnet/8.0" >&2
  exit 1
fi

echo "Building FmtCli ($CONFIGURATION, .NET 8, $RUNTIME) ..."

dotnet publish "$FMTCLI_PROJECT" \
  -c "$CONFIGURATION" \
  -r "$RUNTIME" \
  --self-contained "$SELF_CONTAINED"

OUT_DIR="$PROJECT_ROOT/fmtcli/PoorMansTSqlFormatterFmtCli/bin/$CONFIGURATION/net8.0/$RUNTIME/publish"
if [[ ! -d "$OUT_DIR" ]]; then
  OUT_DIR="$PROJECT_ROOT/fmtcli/PoorMansTSqlFormatterFmtCli/bin/$CONFIGURATION/net8.0/publish"
fi

EXE="$OUT_DIR/PoorMansTSqlFormatterFmtCli"
if [[ ! -f "$EXE" ]]; then
  echo "error: executable not found under $OUT_DIR" >&2
  exit 1
fi

STAGE_DIR="$PROJECT_ROOT/out/plugin"
mkdir -p "$STAGE_DIR"

for name in \
  PoorMansTSqlFormatterFmtCli \
  PoorMansTSqlFormatterFmtCli.dll \
  PoorMansTSqlFormatterFmtCli.deps.json \
  PoorMansTSqlFormatterFmtCli.runtimeconfig.json \
  PoorMansTSqlFormatterLib.dll
do
  if [[ -f "$OUT_DIR/$name" ]]; then
    cp -f "$OUT_DIR/$name" "$STAGE_DIR/$name"
  fi
done

chmod +x "$STAGE_DIR/PoorMansTSqlFormatterFmtCli"

echo "OK: $EXE"
echo "Staged to $STAGE_DIR"
