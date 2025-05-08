#!/bin/bash
REPO="$1"; shift
TARGET="${1:-/usr/local/bin}"; shift

if [[ -z "$REPO" || "$REPO" == "all" ]]; then
  TYPE="Installed"
  if [[ -f /usr/bin/update-repo ]]; then
    TYPE="Updated"
  fi
  wget https://fordi.github.io/update-repo/update-repo.sh -qO /usr/bin/update-repo-tmp
  chmod +x /usr/bin/update-repo-tmp
  echo "${TYPE}"' `update-repo` command' >&2
  if [[ "$REPO" == "all" ]]; then
    while read git; do
      dir="$(dirname "$git")"
      if [[ -d "$dir/bin" ]]; then
        cd "$dir"
        /usr/bin/update-repo-tmp "$(git remote get-url origin)"
      fi
    done < <(find /opt -wholename '*/.git')
  fi
  if [[ -f /usr/bin/update-repo ]]; then
    rm /usr/bin/update-repo
    mv /usr/bin/update-repo-tmp /usr/bin/update-repo
  fi
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
  echo "Symlinking $SOURCES/bin/$file to $TARGET/$name"
  ln -s "$SOURCES/bin/$file" "$TARGET/$name"
}

while read link; do
  rm "$link"
done < <(find "$TARGET" -type l -lname "$SOURCES/*")

cd "$SOURCES/bin"
while read file; do
  install "$file"
done < <(find . -type f -executable -not -path './.git/*')

