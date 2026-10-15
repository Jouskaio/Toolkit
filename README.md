# Toolkit
[![CI](https://github.com/Jouskaio/Toolkit/actions/workflows/ci.yml/badge.svg)](https://github.com/Jouskaio/Toolkit/actions/workflows/ci.yml)

All scripts and random tools who can be use to help the user

## One command

``` bash
bash install.sh      # puts `toolkit` on your PATH (~/.local/bin) with its tab completion
toolkit help
```

| Command | What it does |
| --- | --- |
| `toolkit ssh` | [The SSH connection menu](./ssh): connect, add, edit, delete, groups, jump host, port forwards, key generation, `~/.ssh/config` import and export |
| `toolkit status` | [Health of all your servers](./ssh#health-of-all-your-servers): port, load, disk, memory, pm2 and Docker in one table |
| `toolkit ftp ...` | [SFTP users](./ftp) locked in their folder: create, list, password, quota, delete |
| `toolkit backup` | [Snapshots with rsync](./backup): hard-linked, rotated, local or over SSH |
| `toolkit certs` | [Expiry of your TLS certificates](./certs), with an exit code for cron |
| `toolkit docs [name]` | The cheatsheets below |
| `toolkit test` | Every test of the toolkit |

Without installing anything, every tool also runs directly, for example `bash ssh/main.sh`.

## Shell

* [Quick connexion to SSH servers](./ssh) : Execute the file with `bash ssh/main.sh`, then connect to, add, edit or delete a server
* [Health of all your servers](./ssh#health-of-all-your-servers) : `bash ssh/status.sh`
* [SFTP users locked in their folder](./ftp) : `bash ftp/ftp.sh help` (`create_ftp_user.sh` still works)
* [Backups with rsync and rotation](./backup) : `bash backup/backup.sh`
* [Expiry of the TLS certificates](./certs) : `bash certs/certs.sh`

## Documentation

* [Linux Commands basic](_Documentation/cheatsheet_linux.md)
* [Docker](_Documentation/cheatsheet_docker.md)
* [git flow](_Documentation/cheatsheet_git_flow.md)
* [nginx](_Documentation/cheatsheet_nginx.md)
* [tmux](_Documentation/cheatsheet_tmux.md)

## Quality

Every script is checked with [ShellCheck](https://www.shellcheck.net) and every tool has tests that only use temporary files and fake commands
(your `keys.json`, your `~/.ssh` and your servers are never touched):

``` bash
toolkit test            # or: bash tests/run-all.sh
```

The CI runs ShellCheck and the tests on Linux and macOS for every push and pull request.
