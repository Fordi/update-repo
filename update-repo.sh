#!/bin/bash
REPO="$1"; shift
TARGET="${1:-/usr/local/bin}"; shift

if [[ -z "$REPO" ]]; then
  echo "$(basename "$0") [repository URL]" >&2
  exit -1
fi

SOURCES="/opt/$(basename "$REPO")"
if [[ -x "$SOURCES" ]]; then
  cd "$SOURCES";
  echo "Updating $(basename "$SOURCES")"
  git pull
else
  git clone --depth 1 "$REPO" "$SOURCES" > /dev/null 2>&1
fi
cd "$SOURCES"
HERE="$SOURCES"

function install() {
  local file="$1"; shift;
  local name="$(basename "$1")";
  if [[ -e "$TARGET/$name" ]]; then
    rm "$TARGET/$name"
  fi
  echo "Symlinking $HERE/$file to $TARGET/$name"
  ln -s "$HERE/$file" "$TARGET/$name"
}

cd bin
while read file; do
  install "$file"
done < <(find . -type f -executable -not -path './.git/*')

