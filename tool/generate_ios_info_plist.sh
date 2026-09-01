#!/bin/sh

set -eu

: "${SRCROOT:?SRCROOT must be provided by Xcode}"
: "${DERIVED_FILE_DIR:?DERIVED_FILE_DIR must be provided by Xcode}"

source_plist="$SRCROOT/Runner/Info.plist"
output_plist="$DERIVED_FILE_DIR/Runner-Info.plist"
google_marker="__FLINX_GOOGLE_IOS_REVERSED_CLIENT_ID__"
facebook_app_id_marker="__FLINX_FACEBOOK_APP_ID__"
facebook_client_token_marker="__FLINX_FACEBOOK_CLIENT_TOKEN__"
facebook_display_name_marker="__FLINX_FACEBOOK_DISPLAY_NAME__"
facebook_scheme_marker="__FLINX_FACEBOOK_LOGIN_PROTOCOL_SCHEME__"

placeholder_facebook_app_id="123456789012345"
placeholder_facebook_client_token="not-configured"
placeholder_facebook_display_name="F-linx"

if [ ! -f "$source_plist" ]; then
  echo "Missing iOS Info.plist template: $source_plist" >&2
  exit 1
fi

for marker in \
  "$google_marker" \
  "$facebook_app_id_marker" \
  "$facebook_client_token_marker" \
  "$facebook_display_name_marker" \
  "$facebook_scheme_marker"
do
  if grep -Fq "$marker" "$source_plist"; then
    continue
  fi
  echo "Missing sign-in callback marker $marker in $source_plist" >&2
  exit 1
done

decode_define() {
  if printf '%s' "$1" | base64 -D 2>/dev/null; then
    return 0
  fi
  printf '%s' "$1" | base64 --decode
}

ios_client_id=""
facebook_app_id=""
facebook_client_token=""
facebook_display_name=""
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
    FLINX_FACEBOOK_APP_ID=*)
      facebook_app_id=${decoded_define#*=}
      ;;
    FLINX_FACEBOOK_CLIENT_TOKEN=*)
      facebook_client_token=${decoded_define#*=}
      ;;
    FLINX_FACEBOOK_DISPLAY_NAME=*)
      facebook_display_name=${decoded_define#*=}
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

facebook_app_id=$(printf '%s' "$facebook_app_id" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
facebook_client_token=$(printf '%s' "$facebook_client_token" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
facebook_display_name=$(printf '%s' "$facebook_display_name" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')

if [ -z "$facebook_app_id$facebook_client_token$facebook_display_name" ]; then
  facebook_app_id=$placeholder_facebook_app_id
  facebook_client_token=$placeholder_facebook_client_token
  facebook_display_name=$placeholder_facebook_display_name
else
  case "$facebook_app_id" in
    ''|*[!0-9]*)
      echo "Missing or invalid FLINX_FACEBOOK_APP_ID in DART_DEFINES." >&2
      exit 1
      ;;
  esac
  if [ "$facebook_app_id" = "$placeholder_facebook_app_id" ]; then
    echo "FLINX_FACEBOOK_APP_ID is still using the placeholder value." >&2
    exit 1
  fi
  if [ -z "$facebook_client_token" ] ||
    [ "$facebook_client_token" = "$placeholder_facebook_client_token" ]; then
    echo "Missing or invalid FLINX_FACEBOOK_CLIENT_TOKEN in DART_DEFINES." >&2
    exit 1
  fi
  if [ -z "$facebook_display_name" ]; then
    echo "Missing FLINX_FACEBOOK_DISPLAY_NAME in DART_DEFINES." >&2
    exit 1
  fi
fi

reversed_client_id=$(printf '%s\n' "$ios_client_id" | awk -F. '{
  for (i = NF; i >= 1; i--) {
    printf "%s%s", $i, (i == 1 ? ORS : ".")
  }
}')

escape_xml_text() {
  printf '%s' "$1" | sed \
    -e 's/&/\&amp;/g' \
    -e 's/</\&lt;/g' \
    -e 's/>/\&gt;/g' \
    -e 's/"/\&quot;/g' \
    -e "s/'/\&apos;/g"
}

escape_sed_replacement() {
  printf '%s' "$1" | sed 's/[\\&|]/\\&/g'
}

facebook_app_id_value=$(escape_sed_replacement "$(escape_xml_text "$facebook_app_id")")
facebook_client_token_value=$(escape_sed_replacement "$(escape_xml_text "$facebook_client_token")")
facebook_display_name_value=$(escape_sed_replacement "$(escape_xml_text "$facebook_display_name")")
facebook_scheme_value=$(escape_sed_replacement "$(escape_xml_text "fb$facebook_app_id")")
google_reversed_client_id_value=$(escape_sed_replacement "$reversed_client_id")

mkdir -p "$DERIVED_FILE_DIR"
temporary_plist="$output_plist.tmp"
sed \
  -e "s|$google_marker|$google_reversed_client_id_value|g" \
  -e "s|$facebook_app_id_marker|$facebook_app_id_value|g" \
  -e "s|$facebook_client_token_marker|$facebook_client_token_value|g" \
  -e "s|$facebook_display_name_marker|$facebook_display_name_value|g" \
  -e "s|$facebook_scheme_marker|$facebook_scheme_value|g" \
  "$source_plist" > "$temporary_plist"
mv "$temporary_plist" "$output_plist"
