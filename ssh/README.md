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
  "port": "2222, or null for the default port"
}
```

## Tests

``` bash
bash ssh/tests/keys.test.sh   # add, edit, delete and validations of keys.json
bash ssh/tests/menu.test.sh   # the whole menu, driven by a fake whiptail
```

They only use temporary files: your `keys.json` and your `~/.ssh` are never touched.

## Troubleshooting

* `client_loop: send disconnect: Broken pipe` happens when you stay connected for too long or when the network lags: reconnect.
* "The key ... does not exist": the key file is missing from `~/.ssh`. Edit the connection and give the path of the key again.
