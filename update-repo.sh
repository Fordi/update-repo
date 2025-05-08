#!/bin/bash
REPO="$1"; shift
TARGET="${1:-/usr/local/bin}"; shift

SELF="/usr/local/bin/update-repo"

if [[ $UID != 0 ]]; then
  echo "Must be run as root" >&2
  exit -1
fi

if [[ -z "$REPO" || "$REPO" == "all" ]]; then
  TYPE="Installed"
  if [[ -f "$SELF" ]]; then
    TYPE="Updated"
  fi
  wget https://fordi.github.io/update-repo/update-repo.sh -qO "$SELF-tmp"
  chmod +x "$SELF-tmp"
  if [[ "$REPO" == "all" ]]; then
    while read git; do
      dir="$(dirname "$git")"
      if [[ -d "$dir/bin" ]]; then
        cd "$dir"
        "$SELF-tmp" "$(git remote get-url origin)"
      fi
    done < <(find /opt -wholename '*/.git')
  fi
  if [[ -f "$SELF" ]]; then
    rm "$SELF"
  fi
  mv "$SELF-tmp" "$SELF"
  echo "${TYPE}"' `update-repo` command' >&2
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

while read link; do
  rm "$link"
done < <(find "$TARGET" -type l -lname "$SOURCES/*")

cd "$SOURCES/bin"
while read file; do
  name="$(basename "$file")";
  echo "Symlinking $SOURCES/bin/$file to $TARGET/$name"
  ln -s "$SOURCES/bin/$file" "$TARGET/$name"
done < <(find . -type f -executable -not -path './.git/*')

