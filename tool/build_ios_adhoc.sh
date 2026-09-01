#!/usr/bin/env bash

set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root_dir"

export_options_plist="ios/ExportOptions.plist"
environment_file=""

usage() {
  cat <<'EOF'
Usage: bash tool/build_ios_adhoc.sh --env <dart-define-json>

Builds a manually signed Ad Hoc IPA using ios/ExportOptions.plist.

Examples:
  bash tool/build_ios_adhoc.sh --env config/env/prod.json
EOF
}

while (($#)); do
  case "$1" in
    --env)
      [[ $# -ge 2 ]] || { echo "Missing value for --env." >&2; exit 2; }
      environment_file="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

[[ -f "$export_options_plist" ]] || {
  echo "Missing $export_options_plist." >&2
  exit 1
}

[[ -n "$environment_file" ]] || {
  echo "Missing required --env. Refusing to build without Dart environment definitions." >&2
  usage >&2
  exit 2
}

if [[ ! -f "$environment_file" ]]; then
  echo "Environment file not found: $environment_file" >&2
  exit 1
fi

if command -v fvm >/dev/null 2>&1; then
  flutter_cmd=(fvm flutter)
else
  flutter_cmd=(flutter)
fi

build_args=(build ipa --release --export-options-plist="$export_options_plist")
build_args+=(--dart-define-from-file="$environment_file")

echo "Building signed Ad Hoc IPA..."
"${flutter_cmd[@]}" "${build_args[@]}"

ipa_path="$(find build/ios/ipa -maxdepth 1 -type f -name '*.ipa' -print | head -n 1)"
[[ -n "$ipa_path" ]] || { echo "IPA was not produced in build/ios/ipa." >&2; exit 1; }
archive_app="build/ios/archive/Runner.xcarchive/Products/Applications/Runner.app"

[[ -d "$archive_app" ]] || { echo "Archive app was not produced: $archive_app" >&2; exit 1; }

echo
echo "IPA: $ipa_path"
echo "SHA-256: $(shasum -a 256 "$ipa_path" | awk '{print $1}')"
echo "Signing:"
codesign -dvv "$archive_app" 2>&1 | grep -E 'Identifier=|Authority=|TeamIdentifier='
