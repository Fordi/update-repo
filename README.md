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

