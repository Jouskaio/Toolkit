# Toolkit - Quick connexion to ssh servers

A small menu to keep your SSH connections in one place and open them with one choice.

## Execution

Run it with bash (not `sh`), from any folder:

``` bash
bash ssh/main.sh
```

It needs `jq` and `whiptail` (package `newt` with Homebrew). If one is missing, the script offers to install it.
To leave a server, do Ctrl+D or write `logout`.

## The menu

* **A connection**: select it to connect.
* **+ Add a connection**: name, user, hostname, port (optional) and private key (optional).
  Give the **absolute path** of the key and it is copied to `~/.ssh` with the right permissions (`600`).
  Leave the key empty for a password login.
* **~ Edit a connection**: pick one, the form is pre-filled with its current values.
* **- Delete a connection**: pick one and confirm.

* **\* Generate a key**: creates an ed25519 key in `~/.ssh` (name of your choice, passphrase asked by `ssh-keygen`; an existing key is never overwritten),
  gives it to a connection and offers to install its public half on the server with `ssh-copy-id` (the server asks its password once).

* **= Group, jump host and forwarding**: a label to see your servers by group (`[prod] web`), a jump host (the name of another connection, or `user@host[:port]`)
  and local port forwards such as `8080:localhost:80` (several, separated by commas).
* **< Import from ~/.ssh/config** adds the hosts of an OpenSSH config that are not in the menu yet (your config is only read).
  **> Export to a config file** writes one `Host` block per connection to a file of your choice.

The last connections you used come first in the menu.

Names use letters, digits, `.`, `_` and `-` (no space) and must be unique. A port is a number between 1 and 65535.

## Your connections: keys.json

They live in `ssh/keys.json`, next to `main.sh`. This file lists your real servers, so it is **ignored by git**:
the repository only ships [`keys.example.json`](keys.example.json). Copy it to start from an example,
or just open the menu: the file is created empty on the first run.

Every change keeps the previous version in `keys.json.bak`.

Each connection looks like this (you can still edit the file by hand):

``` json
{
  "name": "Name without space",
  "key": "Name of the key file in ~/.ssh, or null for a password login",
  "hostname": "server.example.com",
  "client": "User on the server",
  "port": "2222, or null for the default port",
  "group": "optional label, e.g. prod",
  "jump": "optional: a connection name or user@host[:port]",
  "forward": "optional: 8080:localhost:80, several separated by commas"
}
```

## Health of all your servers

``` bash
bash ssh/status.sh
```

One table for every connection of `keys.json`, all checked at the same time: is the SSH port open, then (for a connection with a key)
the load, the disk and memory usage, the pm2 processes (online / all) and the number of running Docker containers.
A connection with a password only shows `up-nokey` (asking for the password would block the report), and `denied` means that the key was refused.

## Tests

``` bash
bash ssh/tests/keys.test.sh   # add, edit, delete and validations of keys.json
bash ssh/tests/menu.test.sh   # the whole menu, driven by a fake whiptail
bash ssh/tests/status.test.sh # the health report, with a fake ssh and a fake nc
bash ssh/tests/keygen.test.sh # key generation and installation, in a temporary HOME
bash ssh/tests/comfort.test.sh # groups, recent order, jump host, forwards, config import and export
```

They only use temporary files: your `keys.json` and your `~/.ssh` are never touched.

## Troubleshooting

* `client_loop: send disconnect: Broken pipe` happens when you stay connected for too long or when the network lags: reconnect.
* "The key ... does not exist": the key file is missing from `~/.ssh`. Edit the connection and give the path of the key again.
