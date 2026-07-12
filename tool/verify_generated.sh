#!/usr/bin/env bash
set -euo pipefail

dart run build_runner build
git diff --exit-code -- '*.g.dart' '*.freezed.dart'
