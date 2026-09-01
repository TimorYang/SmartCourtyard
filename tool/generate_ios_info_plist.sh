#!/bin/sh

set -eu

: "${SRCROOT:?SRCROOT must be provided by Xcode}"
: "${DERIVED_FILE_DIR:?DERIVED_FILE_DIR must be provided by Xcode}"

source_plist="$SRCROOT/Runner/Info.plist"
output_plist="$DERIVED_FILE_DIR/Runner-Info.plist"
marker="__FLINX_GOOGLE_IOS_REVERSED_CLIENT_ID__"

if [ ! -f "$source_plist" ]; then
  echo "Missing iOS Info.plist template: $source_plist" >&2
  exit 1
fi

if ! grep -Fq "$marker" "$source_plist"; then
  echo "Missing Google Sign-In callback marker in $source_plist" >&2
  exit 1
fi

decode_define() {
  if printf '%s' "$1" | base64 -D 2>/dev/null; then
    return 0
  fi
  printf '%s' "$1" | base64 --decode
}

ios_client_id=""
dart_defines=${DART_DEFINES-}
old_ifs=$IFS
IFS=,
# DART_DEFINES is a comma-separated list of base64-encoded KEY=VALUE pairs.
# The values used here are client identifiers and do not contain commas.
set -- $dart_defines
IFS=$old_ifs

for encoded_define do
  [ -n "$encoded_define" ] || continue
  decoded_define=$(decode_define "$encoded_define")
  case "$decoded_define" in
    FLINX_GOOGLE_IOS_CLIENT_ID=*)
      ios_client_id=${decoded_define#*=}
      ;;
  esac
done

case "$ios_client_id" in
  *.apps.googleusercontent.com) ;;
  *)
    echo "Missing or invalid FLINX_GOOGLE_IOS_CLIENT_ID in DART_DEFINES." >&2
    exit 1
    ;;
esac

reversed_client_id=$(printf '%s\n' "$ios_client_id" | awk -F. '{
  for (i = NF; i >= 1; i--) {
    printf "%s%s", $i, (i == 1 ? ORS : ".")
  }
}')

mkdir -p "$DERIVED_FILE_DIR"
temporary_plist="$output_plist.tmp"
sed "s|$marker|$reversed_client_id|g" "$source_plist" > "$temporary_plist"
mv "$temporary_plist" "$output_plist"
