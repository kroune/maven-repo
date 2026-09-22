#!/bin/bash
# Re-version stock Kotlin 2.4.10 artifacts from Maven Central as 2.4.10-fir-cache-1
# (only the two embeddables contain actual code changes and are built from source;
# everything else is bit-identical stock content under the custom version).
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE="https://repo1.maven.org/maven2/org/jetbrains/kotlin"
OLD=2.4.10
NEW=2.4.10-fir-cache-1

ARTIFACTS=(
  kotlin-stdlib
  kotlin-reflect
  kotlin-script-runtime
  kotlin-daemon-embeddable
  kotlin-build-tools-api
  kotlin-build-tools-impl
  kotlin-metadata-jvm
  kotlin-scripting-common
  kotlin-scripting-jvm
  kotlin-scripting-jvm-host
  kotlin-scripting-compiler-impl-embeddable
  kotlin-sam-with-receiver
  kotlin-sam-with-receiver-compiler-plugin
  kotlin-assignment
  kotlin-assignment-compiler-plugin-embeddable
  kotlin-gradle-plugin
  kotlin-gradle-plugin-api
)

for a in "${ARTIFACTS[@]}"; do
  dest="$REPO_DIR/org/jetbrains/kotlin/$a/$NEW"
  mkdir -p "$dest"
  for ext in pom module jar; do
    url="$BASE/$a/$OLD/$a-$OLD.$ext"
    out="$dest/$a-$NEW.$ext"
    code=$(curl -sL -o "/tmp/$a.$ext" -w "%{http_code}" "$url")
    if [ "$code" = "200" ]; then
      if [ "$ext" = "jar" ]; then
        cp "/tmp/$a.$ext" "$out"
      else
        sed "s/$OLD/$NEW/g" "/tmp/$a.$ext" > "$out"
      fi
      echo "OK   $a:$ext"
    elif [ "$ext" = "module" ] && [ "$code" = "404" ]; then
      echo "SKIP $a:$ext (no module metadata)"
    else
      echo "FAIL $a:$ext ($code)" >&2
      exit 1
    fi
  done
done
echo "done"
