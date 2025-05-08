#!/bin/bash
REPO="$1"; shift
TARGET="${1:-/usr/local/bin}"; shift

if [[ -z "$REPO" ]]; then
  wget https://fordi.github.io/update-repo/update-repo.sh -qO /usr/bin/update-repo
  chmod +x /usr/bin/update-repo
  echo 'Installed `update-repo` command' >&2
  exit
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

function install() {
  local file="$1"; shift;
  local name="$(basename "$1")";
  if [[ -e "$TARGET/$name" ]]; then
    rm "$TARGET/$name"
  fi
  echo "Symlinking $SOURCES/bin/$file to $TARGET/$name"
  ln -s "$SOURCES/bin/$file" "$TARGET/$name"
}

cd "$SOURCES/bin"
while read file; do
  install "$file"
done < <(find . -type f -executable -not -path './.git/*')

