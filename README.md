# update-repo

Installation:

```bash
wget https://fordi.github.io/update-repo/update-repo.sh -qO - | bash
```

Update:

```bash
update-repo
```

Usage:

- Not installed:

```bash
wget https://fordi.github.io/update-repo/update-repo.sh -qO - | bash /dev/stdin {arguments}
```

- Installed

```bash
update-repo {arguments}
```

Target repository must have a `bin` folder containing executables to be installed to `/usr/local/bin`.

Full usage:

`update-repo <subcommand> [...options]`

## Subcommands

 - `ls` / `list` - list installed project folders
     - `-v` / `--verbose` - List installed projects with repository and linked binaries
 - `r` / `remove` `<repo>` - uninstall repository
 - `remove self` - uninstall `update-repo` command
 - `i` / `install` `<repo>` - install a repository
     - `-b` / `--branch` `<branch>` - specify a preferred branch (default: main/master)
 - `c` / `configure` - modify global configuration
 - `d` / `dump-config` - dump the current global configuration
 - `u` / `update` `<repo>` - update repository
      - `-b` / `--branch` `<branch>` - change preferred branch
 - `ua` / `update all` - update all installed repositories
 - `update self` - update `update-repo` command

## Common flags:
 - `-s` / `-sources` - specify sources folder (default /opt or ~/.repos)
 - `-t` / `-target` - specify target folder (default /usr/local/bin or first item in PATH under ~)

## `<repo>`
 - project name - a GitHub repo assumed to be owned by $USER, e.g., `update-repo install foo` for user bar would be treated as `git@github.com:bar/foo.git`
 - owner/project - assumed to be a GitHub repo, e.g., `foo/bar` would become https://github.com/foo/bar.git
 - a url - a full URL to a git repo; SSH and HTTPS supported
