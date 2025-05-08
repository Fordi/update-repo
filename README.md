# update-repo

Installation:

```bash
wget https://fordi.github.io/update-repo/update-repo.sh -qO - | sudo bash
```

Update:

```bash
update-repo
```

Usage:

- Not installed:

```bash
wget https://fordi.github.io/update-repo/update-repo.sh -qO - | sudo bash /dev/stdin {repository URL}
```

- Installed

```bash
update-repo {repository URL}
```

- Update all installed
```bash
update-repo all
```

Target repository must have a `bin` folder containing executables to be installed to `/usr/local/bin`.

Full usage:

`update-repo <subcommand> [...options]`

## Subcommands

 - `ls` | `list` - list installed repositories
 - `u` | `uninstall` `<repo>` - uninstall repository
 - `i` | `install` `<repo>` - install a repository
     - `-b` | `-branch` `<branch>` - specify a preferred branch (default: main/master)
 - `c` | `configure` - modify global configuration
 - `d` | `dump-config` - dump the current global configuration
 - `U` | `update` `<repo>` - update repository
      - `-b` | `-branch` `<branch>` - change preferred branch
 - `UA` | `update all` - update all installed repositories

## Common flags:
 - `-s` | `-sources` - specify sources folder (default /opt or ~/.repos)
 - `-t` | `-target` - specify target folder (default /usr/local/bin or first item in PATH under ~)

## `<repo>`
 - project name - a GitHub repo assumed to be owned by $USER, e.g., `update-repo install foo` for user bar would be treated as `git@github.com:bar/foo.git`
 - owner/project - assumed to be a GitHub repo, e.g., `foo/bar` would become https://github.com/foo/bar.git
 - a url - a full URL to a git repo; SSH and HTTPS supported
