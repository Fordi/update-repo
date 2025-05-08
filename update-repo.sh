#!/bin/bash
SELF="$(basename "$0")"

LOCAL_SOURCES=
LOCAL_TARGET=
LOCAL_CONF=

function conf-file() {
  if [[ -n "$LOCAL_CONF" ]]; then
    echo "$LOCAL_CONF"
  elif [[ $UID == 0 ]]; then
    echo "/etc/update-repo/global.conf"
  else
    echo "$HOME/.config/update-repo/global.conf"
  fi
}

function conf-path() {
  dirname "$(conf-file)"
}

function conf-name() {
  basename "$(conf-file)"
}

function home-first-bin() {
  while read -r -d ':' item; do
    if [[ "$item" == "$HOME/"* ]]; then
      echo "$item";
      return 0;
    fi
  done < <(echo "$PATH")
  mkdir -p "$HOME/.local/bin"
  echo "$HOME/.local/bin"
  echo "Warning: No local user bin directory; created $HOME/.local/bin, but you must also add that to your path"
}

function get-target() {
  if [[ -n "$LOCAL_TARGET" ]]; then
    echo "$LOCAL_TARGET";
    return 0;
  fi
  local TARGET;
  local CONF_FILE="$(conf-file)"
  if [[ -e "$CONF_FILE" ]]; then
    . "$CONF_FILE"
  fi
  if [[ -n "$TARGET" ]]; then
    echo "$TARGET";
    return 0;
  fi
  if [[ $UID == 0 ]]; then
    echo "/usr/local/bin"
    return 0;
  fi
  home-first-bin
}

function get-sources() {
  if [[ -n "$LOCAL_SOURCES" ]]; then
    echo "$LOCAL_SOURCES";
    return 0;
  fi
  local SOURCES;
  local CONF_FILE="$(conf-file)"
  if [[ -e "$CONF_FILE" ]]; then
    . "$CONF_FILE"
  fi
  if [[ -n "$SOURCES" ]]; then
    echo "$SOURCES"
    return 0;
  fi
  if [[ $UID == 0 ]]; then
    echo "/opt"
    return 0;
  fi
  echo "$HOME/.repos"
  return 0;
}

function normalize-repo() {
  if [[ "$1" == *"@"*":"*"/"* || "$1" == "https://"* || "$1" == *"/"*"/"* ]]; then
    echo "$1";
    return;
  fi
  if [[ "$1" == *"/"* ]]; then
    echo "https://github.com/$1.git";
    return;
  fi
  # check installed repos
  REPO="$(get-sources)/$1"
  if [[ -d "$REPO/.git" ]]; then
    if [[ "$(stat -c '%U' "$REPO")" == "$USER" ]]; then
      cd "$REPO"
      git remote get-url origin 2>/dev/null && return;
    fi
  fi

  # assume...
  echo "git@github.com:$USER/$1.git"
}

function project-name() {
  basename -s .git "$1"
}

function dump-config() {
  echo "Configuration file: $(conf-file)"
  echo "Source folder: $(get-sources)"
  echo "Executables: $(get-target)"
}

function set-value() {
  local CONF_FILE="$(conf-file)"
  local name="$1"; shift
  local value="$1"; shift
  if [[ ! -d "$CONF_PATH" ]]; then
    mkdir -p "$(dirname "$CONF_PATH")";
  fi
  if [[ ! -f "$CONF_FILE" ]]; then
    touch "$CONF_FILE";
  fi
  TMP="$(mktemp)"
  cat "$CONF_FILE" | grep -Ev "^$name=" > "$TMP"
  echo "$name=\"$value\"" >> "$TMP"
  rm "$CONF_FILE"
  mv "$TMP" "$CONF_FILE"
}

function list-sources() {
  SOURCE="$(dirname "$(find "$(get-sources)" -wholename "*/.git")")"
  if [[ -d "$SOURCE/bin" ]]; then
    echo "$SOURCE"
  fi
}

function repo-for-source() {
  cd "$1"
  git remote get-url origin
}

function list-links() {
  local target="$(get-target)"
  find "$target" -lname "$1/*"
}

function install-links() {
  local source="$1"; shift
  local target="$(get-target)"
  while read bin; do
    name="$(basename "$bin")"
    ln -s "$source/bin/$name" "$target/$name"
  done < <(find "$source/bin" -executable -type f)
}

function uninstall-links() {
  local source="$1"; shift
  local target="$(get-target)"
  while read link; do
    rm "$link"
  done < <(list-links "$source")
}

function assert-args() {
  if [[ "${#ARGS[@]}" != "$1" ]]; then
    echo "Expected $1 positional arguments; got ${#ARGS[@]}."
    exit -1
  fi
}

function install-repo() {
  REPO="$(normalize-repo "$1")"
  SOURCE="$(get-sources)/$(project-name "$REPO")"
  if [[ -d "$SOURCE" ]]; then
    uninstall-repo "$REPO"
  fi
  if [[ -z "$BRANCH" ]]; then
    git clone --depth=1 "$REPO" "$SOURCE" >&2
  else
    git clone --depth=1 -b "$BRANCH" "$REPO" "$SOURCE" >&2
  fi
  if [[ -f "$SOURCE/package.json" ]]; then
    cd "$SOURCE"
    npm i
  fi
  install-links "$SOURCE"
}

function uninstall-repo() {
  REPO="$(normalize-repo "${ARGS[0]}")"
  SOURCE="$(get-sources)/$(project-name "$REPO")"
  uninstall-links "$SOURCE"
  rm -rf "$SOURCE"
}

function update-repo() {
  local source="$1"; shift
  if [[ -n "$BRANCH" ]]; then
    local repo="$(repo-for-source "$source")"
    uninstall-repo "$repo"
    install-repo "$repo"
  else
    cd "$source"
    git pull
    if [[ -f "$source/package.json" ]]; then
      npm i
    fi
    uninstall-links "$source"
    instal-links "$source"
  fi
}

function update-self() {
  SELF="$(get-target)/update-repo"
  TYPE="Installed"
  if [[ -f "$SELF" ]]; then
    TYPE="Updated"
  fi
  wget https://raw.githubusercontent.com/Fordi/update-repo/refs/heads/main/update-repo.sh -qO "$SELF-tmp"
  chmod +x "$SELF-tmp"
    if [[ -f "$SELF" ]]; then
    rm "$SELF"
  fi
  mv "$SELF-tmp" "$SELF"
  echo "${TYPE}"' `update-repo` command' >&2
}

ARGS=()
SUBCOMMAND=usage
ALL=0
BRANCH=
VERBOSE=0
while ((${#})); do case "$1" in
  u | update | ua)
    SUBCOMMAND=update
    if [[ "$1" == "ua" ]]; then
      ALL=1
    fi
  ;;
  d | dump-config)
    SUBCOMMAND=dump-config
  ;;
  c | configure)
    SUBCOMMAND=configure
  ;;
  i | install)
    SUBCOMMAND=install
  ;;
  r | remove)
    SUBCOMMAND=remove
  ;;
  ls | list)
    SUBCOMMAND=list
  ;;
  -b | --branch)
    BRANCH="$2"; shift
  ;;
  -s | --sources)
    LOCAL_SOURCES="$2"; shift
  ;;
  -t | --target)
    LOCAL_TARGET="$2"; shift
  ;;
  -c | --configuration)
    LOCAL_CONF="$2"; shift
  ;;
  -v | --verbose)
    VERBOSE=1;
  ;;
  *)
    ARGS+=($1)
  ;;
esac; shift; done

case "$SUBCOMMAND" in
  dump-config)
    assert-args 0
    dump-config
    exit
  ;;
  configure)
    assert-args 0
    set-value SOURCES "$(get-sources)"
    set-value TARGET "$(get-target)"
    exit
  ;;
  install)
    assert-args 1
    install-repo "${ARGS[0]}"
  ;;
  remove)
    assert-args 1
    uninstall-repo "${ARGS[0]}"
  ;;
  list)
    assert-args 0
    if [[ $VERBOSE == 0 ]]; then
      list-sources
    else
      while read source; do
        echo "Installed: $source"
        echo "  Repository: $(repo-for-source $source)"
        echo "  Binaries:"
        while read link; do
          echo "    $link -> $(readlink "$link")"
        done < <(list-links $source)
      done < <(list-sources)
    fi
  ;;
  update)
    if [[ $ALL == 1 ]]; then
      assert-args 0
    else
      assert-args 1
    fi
    if [[ "${ARGS[0]}" == "all" ]]; then
      ALL=1
    fi
    if [[ "${ARGS[0]}" == "self" ]]; then
      update-self
      exit
    fi
    if [[ $ALL == 1 ]]; then
      while read source; do
        cd "$source"
        git pull
        uninstall-links "$source"
        install-links "$source"
      done < <(list-sources)
    else
      REPO="$(normalize-repo "${ARGS[0]}")"
      SOURCE="$(get-sources)/$(project-name "$REPO")"
      cd "$SOURCE"
      git pull
      uninstall-links "$SOURCE"
      install-links "$SOURCE"
    fi
  ;;
  usage)
    if [[ "$SELF" == "bash" || "$0" == "/dev/stdin" ]]; then
      update-self
      exit
    fi
    echo "$SELF <subcommand> [...options]"
    echo "    ls | list - list installed repositories"
    echo "      -v | --verbose - List installed projects with repository and linked binaries"
    echo "    r | remove [repo] - uninstall repository"
    echo "    i | install [repo] - install a repository"
    echo "      -b | --branch [branch] - specify a preferred branch"
    echo "    c | configure - modify global configuration"
    echo "    d | dump-config - dump the current global configuration"
    echo "    u | update [repo] - update repository"
    echo "      -b | --branch [branch] - specify a preferred branch"
    echo "    ua | update all - update all installed repositories"
    echo "    update self - update \`update-repo\` command"
    echo ""
    echo "Flags:"
    echo "    -s | -sources - specify sources folder (default /opt or ~/.repos)"
    echo "    -t | -target - specify target folder (default /usr/local/bin or first item in PATH under ~)"
    echo ""
    echo "[repo] can be:"
    echo "    [project-name] - a GitHub repo assumed to be owned by \$USER, e.g.,"
    echo "      \`update-repo install foo\` for user $USER would be treated as git@github.com:$USER/foo.git"
    echo "    [owner/project] - a GitHub repo; \`foo/bar\` would become https://github.com/foo/bar.git"
    echo "    [url] - a full URL to a git repo; SSH and HTTPS supported"
  ;;
esac

