# Toolkit - Backups with rsync and rotation

Snapshots of your folders: every run makes a dated folder, and the files that did not change are **hard links** to the previous
snapshot, so ten snapshots cost little more than one. The oldest ones are deleted beyond `KEEP`.

``` bash
cp backup/backup.example.conf backup/backup.conf   # then edit it: backup.conf is ignored by git
bash backup/backup.sh                               # one snapshot, then the rotation
bash backup/backup.sh list                          # the snapshots and their size
bash backup/backup.sh /path/to/other.conf           # another config file
```

## The config

| Setting | Meaning |
| --- | --- |
| `SOURCES` | Folders to save, absolute paths separated by spaces (no space inside a path) |
| `DEST` | A local folder, or `user@host:/folder` to save over SSH |
| `KEEP` | How many snapshots to keep (1 or more) |
| `EXCLUDE` | Patterns that are not saved (`node_modules .cache *.log`) |
| `RSYNC_SSH` | The ssh command for a remote `DEST`, e.g. `ssh -i /home/me/.ssh/backup_key -p 2222` |
| `RSYNC_OPTIONS` | Extra rsync flags, simple words (`--bwlimit=5000`) |

Inside a snapshot, each source keeps its full path (`<snapshot>/var/www/...`). If a source is missing or rsync fails,
the incomplete snapshot is removed and the older ones are untouched.

To run it every night, add a line to `crontab -e`: `30 3 * * * bash /opt/toolkit/backup/backup.sh >> /var/log/toolkit-backup.log 2>&1`.

A remote `DEST` is saved with rsync over SSH but **not rotated** by this script: delete the old snapshots on the server (or give it a local folder).

## Tests

``` bash
bash backup/tests/backup.test.sh   # snapshots, hard links, rotation, failures: all in temporary folders
```
