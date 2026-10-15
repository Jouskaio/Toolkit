# Toolkit - SFTP users locked in their folder

Run it **on the server**, as root. It manages users of the `sftpusers` group whose SFTP session is limited to `/home/<user>/ftp`.

``` bash
sudo bash ftp/ftp.sh create client ~/client_key.pub   # the user, its locked folder and its authorized key
sudo bash ftp/ftp.sh list                             # the users and the size of their files
sudo bash ftp/ftp.sh password client                  # a new random password, shown once
sudo bash ftp/ftp.sh quota client 5G                  # a disk limit (needs quotas on the file system)
sudo bash ftp/ftp.sh delete client                    # delete the user, its files stay (--purge deletes them too)
```

`bash ftp/create_ftp_user.sh <user>` still works: it is `ftp.sh create`.

## What `create` does

* creates the group `sftpusers` if needed, then the user with no shell (`/usr/sbin/nologin`);
* builds `/home/<user>/ftp` owned by root (sshd's chroot refuses anything else) and an **upload folder `ftp/files`** that belongs to the user;
* when a public key file is given, adds it to `/home/<user>/.ssh/authorized_keys` (`700` / `600`, owned by the user);
* an existing user is kept as it is, so it is safe to run it again to add a key.

On the sshd side, the group needs a block like this in `/etc/ssh/sshd_config` (once):

```
Match Group sftpusers
    ChrootDirectory %h/ftp
    ForceCommand internal-sftp
    AllowTcpForwarding no
    X11Forwarding no
```

## Try it without touching anything

`FTP_DRY_RUN=1` prints the commands instead of running them (and does not ask for root):

``` bash
FTP_DRY_RUN=1 bash ftp/ftp.sh create client
bash ftp/tests/ftp.test.sh
```
